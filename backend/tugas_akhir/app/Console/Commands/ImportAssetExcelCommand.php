<?php

namespace App\Console\Commands;

use App\Models\Asset;
use App\Models\AssetCategory;
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

    public function handle(): int
    {
        $file = base_path($this->argument('file'));

        if (! file_exists($file)) {
            $this->error("File tidak ditemukan: {$file}");

            return self::FAILURE;
        }

        $this->info("Membaca file: {$file}");

        try {
            $sheets = Excel::toCollection(null, $file);

            if ($sheets->isEmpty()) {
                $this->error('File Excel kosong.');

                return self::FAILURE;
            }

            $rows = $sheets->first();

            DB::transaction(function () use ($rows): void {
                if ($this->option('fresh')) {
                    Asset::query()
                        ->where('description', 'like', 'Import dari Excel Aktiva Tetap%')
                        ->delete();

                    $this->warn('Asset hasil import Excel sebelumnya sudah dihapus.');
                }

                $this->importRows($rows);
            });

            $this->info('Import asset selesai.');

            return self::SUCCESS;
        } catch (Throwable $e) {
            $this->error('Import gagal: ' . $e->getMessage());

            report($e);

            return self::FAILURE;
        }
    }

    private function importRows(Collection $rows): void
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

                $this->line("Kategori ditemukan: {$categoryName}");

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

        $this->info("Total asset berhasil diproses: {$imported}");
        $this->warn("Total baris dilewati: {$skipped}");
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