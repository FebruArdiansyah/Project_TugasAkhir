<?php

namespace App\Console\Commands;

use App\Models\InventoryOutImportLog;
use App\Models\InventoryOut;
use App\Models\Product;
use Illuminate\Console\Command;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Facades\Excel;
use Throwable;

class ImportInventoryOutExcelCommand extends Command
{
    protected $signature = 'inventory-out:import-excel 
                            {file : Path file Excel, contoh storage/app/imports/barang_keluar.xlsx}';

    protected $description = 'Import data Barang Keluar dari Excel ke modul Inventory (Pending, tidak merubah stok langsung).';

    public function handle(): int
    {
        $file = base_path($this->argument('file'));

        if (! file_exists($file)) {
            $this->error("File tidak ditemukan: {$file}");
            return self::FAILURE;
        }

        $this->info("Membaca file: {$file}");

        $log = InventoryOutImportLog::create([
            'file_name' => basename($file),
            'status' => 'pending',
            'imported_by' => auth()->id() ?: 1,
            'started_at' => now(),
        ]);

        try {
            $sheets = Excel::toCollection(null, $file);
            $rows = $sheets->first();

            $imported = 0;
            $skipped = 0;

            DB::transaction(function () use ($rows, &$imported, &$skipped, $log) {
                foreach ($rows as $index => $row) {
                    $values = collect($row)->map(fn($v) => is_string($v) ? trim($v) : $v)->values();

                    // contoh kolom: Invoice | Produk | Qty | Harga
                    $invoice = $values->get(0);
                    $productName = $values->get(1);
                    $qty = (int) $values->get(2);
                    $price = (float) $values->get(3);

                    if (!$invoice || !$productName || $qty <= 0) {
                        $skipped++;
                        continue;
                    }

                    $product = Product::firstWhere('name', $productName);
                    if (!$product) {
                        $skipped++;
                        continue;
                    }

                    InventoryOut::create([
                        'invoice_number' => $invoice,
                        'product_id' => $product->id,
                        'quantity' => $qty,
                        'price' => $price,
                        'status' => 'pending', // pending supaya stok tidak berubah
                    ]);

                    $imported++;
                }
            });

            $log->update([
                'total_rows' => count($rows),
                'imported_rows' => $imported,
                'skipped_rows' => $skipped,
                'status' => 'imported',
                'finished_at' => now(),
            ]);

            $this->info("Import selesai: {$imported} baris berhasil, {$skipped} dilewati.");
            return self::SUCCESS;

        } catch (Throwable $e) {
            $log->update([
                'status' => 'failed',
                'error_message' => $e->getMessage(),
                'finished_at' => now(),
            ]);

            $this->error('Import gagal: ' . $e->getMessage());
            report($e);
            return self::FAILURE;
        }
    }
}