<?php

namespace App\Console\Commands;

use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\AssetImportLog;
use App\Models\AssetLocation;
use App\Services\AssetCodeService;
use Illuminate\Console\Command;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Facades\Excel;
use Throwable;

class ImportAssetExcelCommand extends Command
{
    protected $signature = 'asset:import-excel 
                            {file : Path file Excel, contoh storage/app/imports/aktiva_tetap.xlsx}
                            {--fresh : Hapus asset hasil import Excel sebelumnya sebelum import ulang}';

    protected $description = 'Import data aktiva tetap dari Excel ke modul manajemen aset.';

    private int $importedRows = 0;

    private int $skippedRows = 0;

    public function handle(): int
    {
        $file = base_path($this->argument('file'));

        if (! file_exists($file)) {
            $this->error("File tidak ditemukan: {$file}");

            AssetImportLog::create([
                'file_name' => basename((string) $this->argument('file')),
                'total_rows' => 0,
                'imported_rows' => 0,
                'skipped_rows' => 0,
                'status' => 'failed',
                'message' => 'File tidak ditemukan.',
                'error_message' => "File tidak ditemukan: {$file}",
                'imported_by' => 1,
                'started_at' => now(),
                'finished_at' => now(),
            ]);

            return self::FAILURE;
        }

        $this->info("Membaca file: {$file}");

        $log = AssetImportLog::create([
            'file_name' => basename($file),
            'total_rows' => 0,
            'imported_rows' => 0,
            'skipped_rows' => 0,
            'status' => 'processing',
            'message' => 'Proses import asset sedang berjalan.',
            'error_message' => null,
            'imported_by' => 1,
            'started_at' => now(),
            'finished_at' => null,
        ]);

        try {
            $sheets = Excel::toCollection(null, $file);

            if ($sheets->isEmpty()) {
                $this->error('File Excel kosong.');

                $log->update([
                    'status' => 'failed',
                    'message' => 'File Excel kosong.',
                    'error_message' => 'Tidak ada sheet yang bisa dibaca dari file Excel.',
                    'finished_at' => now(),
                ]);

                return self::FAILURE;
            }

            $rows = $sheets->first();

            if (! $rows instanceof Collection || $rows->isEmpty()) {
                $this->error('Sheet pertama kosong.');

                $log->update([
                    'status' => 'failed',
                    'message' => 'Sheet pertama kosong.',
                    'error_message' => 'Sheet pertama tidak memiliki data yang bisa diproses.',
                    'finished_at' => now(),
                ]);

                return self::FAILURE;
            }

            $result = DB::transaction(function () use ($rows): array {
                if ($this->option('fresh')) {
                    Asset::query()
                        ->where('description', 'like', 'Import dari Excel Aktiva Tetap%')
                        ->delete();

                    $this->warn('Asset hasil import Excel sebelumnya sudah dihapus.');
                }

                return $this->importRows($rows);
            });

            $status = $result['skipped_rows'] > 0
                ? 'success_with_warning'
                : 'success';

            $message = $result['skipped_rows'] > 0
                ? 'Import berhasil, tetapi ada beberapa baris yang dilewati.'
                : 'Import asset berhasil.';

            $log->update([
                'total_rows' => $result['total_rows'],
                'imported_rows' => $result['imported_rows'],
                'skipped_rows' => $result['skipped_rows'],
                'status' => $status,
                'message' => $message,
                'error_message' => null,
                'finished_at' => now(),
            ]);

            $this->info('Import asset selesai.');
            $this->info("Total baris dibaca: {$result['total_rows']}");
            $this->info("Total asset berhasil diproses: {$result['imported_rows']}");
            $this->warn("Total baris dilewati: {$result['skipped_rows']}");

            return self::SUCCESS;
        } catch (Throwable $e) {
            $this->error('Import gagal: ' . $e->getMessage());

            $log->update([
                'status' => 'failed',
                'message' => 'Import gagal.',
                'error_message' => $e->getMessage(),
                'imported_rows' => $this->importedRows,
                'skipped_rows' => $this->skippedRows,
                'finished_at' => now(),
            ]);

            report($e);

            return self::FAILURE;
        }
    }

    private function importRows(Collection $rows): array
    {
        $currentCategory = null;

        $this->importedRows = 0;
        $this->skippedRows = 0;

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

                $this->line("Kategori ditemukan: {$categoryName}");

                continue;
            }

            if ($this->isHeaderRow($values) || $this->isTotalRow($values)) {
                continue;
            }

            if (! $currentCategory) {
                $this->skippedRows++;
                $this->warn("Baris {$rowNumber} dilewati: kategori belum ditemukan.");
                continue;
            }

            $assetName = $columnC;

            if (! $assetName || strlen($assetName) < 2) {
                $this->skippedRows++;
                $this->warn("Baris {$rowNumber} dilewati: nama asset kosong/tidak valid.");
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
                $this->skippedRows++;
                $this->warn("Baris {$rowNumber} dilewati: harga perolehan kosong/tidak valid.");
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
                'created_by' => 1,
            ]);

            $this->importedRows++;
        }

        return [
            'total_rows' => $rows->count(),
            'imported_rows' => $this->importedRows,
            'skipped_rows' => $this->skippedRows,
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