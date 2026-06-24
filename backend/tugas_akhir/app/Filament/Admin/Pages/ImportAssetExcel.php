<?php

namespace App\Filament\Admin\Pages;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\AssetImportLog;
use App\Models\AssetLocation;
use App\Services\AssetCodeService;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Maatwebsite\Excel\Facades\Excel;
use Throwable;

class ImportAssetExcel extends Page implements HasForms
{
    use InteractsWithForms;

    protected static \BackedEnum|string|null $navigationIcon = 'heroicon-o-arrow-up-tray';

    protected static \UnitEnum|string|null $navigationGroup = 'Manajemen Aset';

    protected static ?string $navigationLabel = 'Import Data Aset';

    protected static ?string $title = 'Import Data Aset';

    protected string $view = 'filament.admin.pages.import-asset-excel';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'fresh' => false,
        ]);
    }

    public function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                Section::make('Upload File Excel Aktiva Tetap')
                    ->description('Upload file Excel aktiva tetap untuk dimasukkan ke tabel operasional aset.')
                    ->schema([
                        FileUpload::make('file')
                            ->label('File Excel')
                            ->disk('local')
                            ->directory('imports/assets')
                            ->acceptedFileTypes([
                                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                'application/vnd.ms-excel',
                            ])
                            ->maxSize(10240)
                            ->required(),

                        Toggle::make('fresh')
                            ->label('Hapus data import Excel sebelumnya')
                            ->helperText('Jika aktif, sistem akan menghapus data aset yang sebelumnya diimport dari Excel Aktiva Tetap.')
                            ->default(false),
                    ]),
            ])
            ->statePath('data');
    }

    public function import(): void
    {
        $state = $this->form->getState();

        if (empty($state['file'])) {
            Notification::make()
                ->title('File belum dipilih')
                ->body('Silakan pilih file Excel terlebih dahulu sebelum melakukan import.')
                ->danger()
                ->send();

            return;
        }

        $filePath = Storage::disk('local')->path($state['file']);
        $fileName = basename($state['file']);

        if (! file_exists($filePath)) {
            Notification::make()
                ->title('File tidak ditemukan')
                ->body('File Excel tidak ditemukan di storage.')
                ->danger()
                ->send();

            return;
        }

        $log = AssetImportLog::create([
            'file_name' => $fileName,
            'status' => 'processing',
            'message' => 'Proses import data aset sedang berjalan.',
            'imported_by' => auth()->id() ?: 1,
            'started_at' => now(),
        ]);

        try {
            $sheets = Excel::toCollection(null, $filePath);

            if ($sheets->isEmpty()) {
                $log->update([
                    'status' => 'failed',
                    'message' => 'File Excel kosong.',
                    'error_message' => 'Tidak ada sheet yang bisa dibaca dari file Excel.',
                    'finished_at' => now(),
                ]);

                Notification::make()
                    ->title('File Excel kosong')
                    ->body('Tidak ada data yang bisa diproses dari file tersebut.')
                    ->danger()
                    ->send();

                return;
            }

            $rows = $sheets->first();

            $result = DB::transaction(function () use ($rows, $state): array {
                if (! empty($state['fresh'])) {
                    Asset::query()
                        ->where('description', 'like', 'Import dari Excel Aktiva Tetap%')
                        ->delete();
                }

                return $this->importRows($rows);
            });

            $status = $result['skipped'] > 0 ? 'success_with_warning' : 'success';

            $message = $result['skipped'] > 0
                ? 'Import berhasil, tetapi ada beberapa baris yang dilewati.'
                : 'Import data aset berhasil sepenuhnya.';

            $log->update([
                'total_rows' => $result['total_rows'],
                'imported_rows' => $result['imported'],
                'skipped_rows' => $result['skipped'],
                'status' => $status,
                'message' => $message,
                'finished_at' => now(),
            ]);

            Notification::make()
                ->title('Import data aset selesai')
                ->body("Berhasil: {$result['imported']} data. Dilewati: {$result['skipped']} baris. Total dibaca: {$result['total_rows']} baris.")
                ->success()
                ->send();

            if ($result['skipped'] > 0) {
                Notification::make()
                    ->title('Ada baris yang dilewati')
                    ->body("Sebanyak {$result['skipped']} baris dilewati karena kosong, tidak valid, atau harga perolehan tidak ditemukan.")
                    ->warning()
                    ->send();
            }

            $this->form->fill([
                'fresh' => false,
            ]);
        } catch (Throwable $e) {
            report($e);

            $log->update([
                'status' => 'failed',
                'message' => 'Import gagal.',
                'error_message' => $e->getMessage(),
                'finished_at' => now(),
            ]);

            Notification::make()
                ->title('Import gagal')
                ->body($e->getMessage())
                ->danger()
                ->send();
        }
    }

    private function importRows(Collection $rows): array
    {
        $currentCategory = null;

        $imported = 0;
        $skipped = 0;

        foreach ($rows as $index => $row) {
            $rowNumber = $index + 1;

            $values = collect($row)
                ->map(fn ($value) => is_string($value) ? trim($value) : $value)
                ->values();

            if ($this->isEmptyRow($values)) {
                continue;
            }

            $columnA = $this->cell($values, 0);
            $columnB = $this->cell($values, 1);
            $columnC = $this->cell($values, 2);

            if ($this->isCategoryRow($columnA, $columnB)) {
                $categoryName = $this->cleanCategoryName($columnB);

                $currentCategory = AssetCategory::firstOrCreate(
                    ['name' => $categoryName],
                    [
                        'code' => app(AssetCodeService::class)->nextAssetCategoryCode(),
                        'description' => 'Import dari Excel Aktiva Tetap.',
                        'is_active' => true,
                    ]
                );

                continue;
            }

            if ($this->isHeaderRow($values) || $this->isTotalRow($values)) {
                continue;
            }

            if (! $currentCategory) {
                $skipped++;
                continue;
            }

            $assetName = $columnC;

            if (! $assetName || strlen($assetName) < 2) {
                $skipped++;
                continue;
            }

            $locationName = $this->cell($values, 6);
            $year = $this->toYear($values->get(7));
            $price = $this->toNumber($values->get(8));

            $licensePlate = $this->makeLicensePlate(
                $values->get(3),
                $values->get(4),
                $values->get(5)
            );

            if ($price <= 0) {
                $skipped++;
                continue;
            }

            $location = null;

            if ($locationName) {
                $location = AssetLocation::firstOrCreate(
                    ['name' => $this->normalizeLocationName($locationName)],
                    [
                        'code' => app(AssetCodeService::class)->nextAssetLocationCode(),
                        'address' => null,
                        'is_active' => true,
                    ]
                );
            }

            $assetCode = app(AssetCodeService::class)->nextAssetCode();

            Asset::create([
                'asset_category_id' => $currentCategory->id,
                'asset_location_id' => $location?->id,
                'asset_code' => $assetCode,
                'name' => $assetName,
                'license_plate' => $licensePlate,
                'brand' => null,
                'model' => null,
                'serial_number' => null,
                'acquisition_year' => $year,
                'acquisition_date' => null,
                'acquisition_price' => $price,
                'condition' => 'baik',
                'status' => 'aktif',
                'description' => 'Import dari Excel Aktiva Tetap baris ' . $rowNumber,
                'created_by' => auth()->id() ?: 1,
            ]);

            $imported++;
        }

        return [
            'total_rows' => $rows->count(),
            'imported' => $imported,
            'skipped' => $skipped,
        ];
    }

    private function cell(Collection $values, int $index): ?string
    {
        $value = $values->get($index);

        if ($value === null) {
            return null;
        }

        $text = trim((string) $value);

        return $text === '' ? null : $text;
    }

    private function isEmptyRow(Collection $values): bool
    {
        return $values
            ->filter(fn ($value) => $value !== null && trim((string) $value) !== '')
            ->isEmpty();
    }

    private function isCategoryRow(?string $columnA, ?string $columnB): bool
    {
        if (! $columnA || ! $columnB) {
            return false;
        }

        $categoryCode = strtoupper(trim($columnA));
        $categoryText = strtoupper(trim($columnB));

        return in_array($categoryCode, ['A', 'B', 'C', 'D', 'E'], true)
            && (
                str_contains($categoryText, 'TANAH')
                || str_contains($categoryText, 'BANGUNAN')
                || str_contains($categoryText, 'KENDARAAN')
                || str_contains($categoryText, 'MESIN')
                || str_contains($categoryText, 'INVENTARIS KANTOR')
                || str_contains($categoryText, 'INVENTARIS BENGKEL')
            );
    }

    private function cleanCategoryName(string $value): string
    {
        $value = str_replace(':', '', $value);
        $value = trim($value);

        return ucwords(strtolower($value));
    }

    private function isHeaderRow(Collection $values): bool
    {
        $joined = strtoupper($values->implode(' '));

        return str_contains($joined, 'IDENTIFIKASI')
            || str_contains($joined, 'LOKASI')
            || str_contains($joined, 'TAHUN')
            || str_contains($joined, 'HARGA')
            || str_contains($joined, 'PEROLEHAN');
    }

    private function isTotalRow(Collection $values): bool
    {
        $joined = strtoupper($values->implode(' '));

        if (str_contains($joined, 'TOTAL')) {
            return true;
        }

        $assetName = $this->cell($values, 2);
        $price = $this->toNumber($values->get(8));

        return ! $assetName && $price > 0;
    }

    private function normalizeLocationName(string $value): string
    {
        $value = trim($value);

        return match (strtoupper($value)) {
            'JL. BARU', 'JALAN BARU' => 'Jl. Baru',
            'DAON' => 'Daon',
            'DAUN' => 'Daun',
            'CILONGOK' => 'Cilongok',
            default => ucwords(strtolower($value)),
        };
    }

    private function makeLicensePlate(mixed $prefix, mixed $number, mixed $suffix): ?string
    {
        $parts = collect([$prefix, $number, $suffix])
            ->map(fn ($value) => trim((string) $value))
            ->filter(fn ($value) => $value !== '')
            ->values();

        if ($parts->isEmpty()) {
            return null;
        }

        return strtoupper($parts->implode(' '));
    }

    private function toYear(mixed $value): ?int
    {
        if ($value === null || $value === '') {
            return null;
        }

        $year = (int) $value;

        if ($year < 1900 || $year > ((int) now()->format('Y') + 1)) {
            return null;
        }

        return $year;
    }

    private function toNumber(mixed $value): float
    {
        if ($value === null || $value === '') {
            return 0;
        }

        if (is_numeric($value)) {
            return (float) $value;
        }

        $clean = preg_replace('/[^0-9,.-]/', '', (string) $value);
        $clean = str_replace('.', '', $clean);
        $clean = str_replace(',', '.', $clean);

        return is_numeric($clean) ? (float) $clean : 0;
    }
}