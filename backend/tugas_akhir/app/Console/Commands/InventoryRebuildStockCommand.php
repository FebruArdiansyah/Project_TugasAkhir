<?php

namespace App\Console\Commands;

use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class InventoryRebuildStockCommand extends Command
{
    protected $signature = 'inventory:rebuild-stock {--force : Jalankan tanpa konfirmasi}';

    protected $description = 'Rebuild stok gudang dan mutasi stok dari transaksi barang masuk dan barang keluar approved.';

    private int $movementSequence = 1;

    public function handle(): int
    {
        if (! Schema::hasTable('stock_balances')) {
            $this->error('Tabel stock_balances tidak ditemukan.');
            return self::FAILURE;
        }

        if (! Schema::hasTable('stock_movements')) {
            $this->error('Tabel stock_movements tidak ditemukan.');
            return self::FAILURE;
        }

        if (! Schema::hasTable('inbound_transactions') || ! Schema::hasTable('inbound_transaction_items')) {
            $this->error('Tabel transaksi barang masuk tidak lengkap.');
            return self::FAILURE;
        }

        if (! Schema::hasTable('outbound_transactions') || ! Schema::hasTable('outbound_transaction_items')) {
            $this->error('Tabel transaksi barang keluar tidak lengkap.');
            return self::FAILURE;
        }

        if (! $this->option('force')) {
            $confirmed = $this->confirm(
                'Command ini akan menghapus isi stock_balances dan stock_movements lalu membangun ulang dari transaksi approved. Lanjutkan?',
                false
            );

            if (! $confirmed) {
                $this->warn('Dibatalkan.');
                return self::SUCCESS;
            }
        }

        DB::transaction(function (): void {
            $this->info('Menghapus stok gudang lama...');
            DB::table('stock_balances')->delete();

            $this->info('Menghapus mutasi stok lama...');
            DB::table('stock_movements')->delete();

            $this->movementSequence = 1;

            $this->info('Memproses transaksi barang masuk...');
            $inboundCount = $this->processInboundTransactions();

            $this->info('Memproses transaksi barang keluar...');
            $outboundCount = $this->processOutboundTransactions();

            $stockBalanceCount = DB::table('stock_balances')->count();
            $stockMovementCount = DB::table('stock_movements')->count();
            $totalQty = DB::table('stock_balances')->sum('qty_on_hand');

            $this->newLine();
            $this->info('Rebuild stok selesai.');
            $this->line("Item barang masuk diproses : {$inboundCount}");
            $this->line("Item barang keluar diproses: {$outboundCount}");
            $this->line("Data stok gudang dibuat    : {$stockBalanceCount}");
            $this->line("Data mutasi stok dibuat    : {$stockMovementCount}");
            $this->line("Total stok fisik           : {$totalQty}");
        });

        return self::SUCCESS;
    }

    private function processInboundTransactions(): int
    {
        $query = DB::table('inbound_transaction_items as item')
            ->join('inbound_transactions as trx', 'trx.id', '=', 'item.inbound_transaction_id')
            ->whereNotNull('item.product_id')
            ->whereNotNull('item.warehouse_id')
            ->where('item.qty', '>', 0)
            ->orderBy('trx.transaction_date')
            ->orderBy('trx.id')
            ->orderBy('item.id')
            ->select([
                'item.id as item_id',
                'item.inbound_transaction_id as transaction_id',
                'item.product_id',
                'item.warehouse_id',
                'item.qty',
                'item.created_at as item_created_at',
                'trx.transaction_number',
                'trx.transaction_date',
                'trx.created_at as transaction_created_at',
            ]);

        if (Schema::hasColumn('inbound_transactions', 'status')) {
            $query->whereIn(DB::raw('LOWER(trx.status)'), $this->approvedStatuses());
        }

        $processed = 0;

        foreach ($query->get() as $row) {
            $qty = (float) $row->qty;

            if ($qty <= 0) {
                continue;
            }

            $createdAt = $this->dateFromTransaction($row->transaction_date, $row->transaction_created_at, $row->item_created_at);
            $stockBefore = $this->currentStock((int) $row->product_id, (int) $row->warehouse_id);
            $stockAfter = $stockBefore + $qty;

            $this->updateStockBalance(
                productId: (int) $row->product_id,
                warehouseId: (int) $row->warehouse_id,
                qtyOnHand: $stockAfter
            );

            $this->createStockMovement([
                'movement_number' => $this->generateMovementNumber('IN', $createdAt),
                'product_id' => (int) $row->product_id,
                'warehouse_id' => (int) $row->warehouse_id,
                'movement_type' => 'in',
                'reference_type' => 'inbound_transaction',
                'reference_id' => (int) $row->transaction_id,
                'qty_in' => $qty,
                'qty_out' => 0,
                'stock_before' => $stockBefore,
                'stock_after' => $stockAfter,
                'description' => 'Rebuild stok dari barang masuk ' . ($row->transaction_number ?? '-'),
                'created_by' => $this->defaultUserId(),
                'created_at' => $createdAt,
                'updated_at' => now(),
            ]);

            $processed++;
        }

        return $processed;
    }

    private function processOutboundTransactions(): int
    {
        $query = DB::table('outbound_transaction_items as item')
            ->join('outbound_transactions as trx', 'trx.id', '=', 'item.outbound_transaction_id')
            ->whereNotNull('item.product_id')
            ->whereNotNull('item.warehouse_id')
            ->where('item.qty', '>', 0)
            ->orderBy('trx.transaction_date')
            ->orderBy('trx.id')
            ->orderBy('item.id')
            ->select([
                'item.id as item_id',
                'item.outbound_transaction_id as transaction_id',
                'item.product_id',
                'item.warehouse_id',
                'item.qty',
                'item.created_at as item_created_at',
                'trx.transaction_number',
                'trx.transaction_date',
                'trx.created_at as transaction_created_at',
            ]);

        if (Schema::hasColumn('outbound_transactions', 'status')) {
            $query->whereIn(DB::raw('LOWER(trx.status)'), $this->approvedStatuses());
        }

        $processed = 0;

        foreach ($query->get() as $row) {
            $qty = (float) $row->qty;

            if ($qty <= 0) {
                continue;
            }

            $createdAt = $this->dateFromTransaction($row->transaction_date, $row->transaction_created_at, $row->item_created_at);
            $stockBefore = $this->currentStock((int) $row->product_id, (int) $row->warehouse_id);
            $stockAfter = $stockBefore - $qty;

            $this->updateStockBalance(
                productId: (int) $row->product_id,
                warehouseId: (int) $row->warehouse_id,
                qtyOnHand: $stockAfter
            );

            DB::table('outbound_transaction_items')
                ->where('id', $row->item_id)
                ->update([
                    'stock_before_submit' => $stockBefore,
                    'stock_after_submit' => $stockAfter,
                    'updated_at' => now(),
                ]);

            $this->createStockMovement([
                'movement_number' => $this->generateMovementNumber('OUT', $createdAt),
                'product_id' => (int) $row->product_id,
                'warehouse_id' => (int) $row->warehouse_id,
                'movement_type' => 'out',
                'reference_type' => 'outbound_transaction',
                'reference_id' => (int) $row->transaction_id,
                'qty_in' => 0,
                'qty_out' => $qty,
                'stock_before' => $stockBefore,
                'stock_after' => $stockAfter,
                'description' => 'Rebuild stok dari barang keluar ' . ($row->transaction_number ?? '-'),
                'created_by' => $this->defaultUserId(),
                'created_at' => $createdAt,
                'updated_at' => now(),
            ]);

            $processed++;
        }

        return $processed;
    }

    private function currentStock(int $productId, int $warehouseId): float
    {
        $stock = DB::table('stock_balances')
            ->where('product_id', $productId)
            ->where('warehouse_id', $warehouseId)
            ->value('qty_on_hand');

        return (float) ($stock ?? 0);
    }

    private function updateStockBalance(int $productId, int $warehouseId, float $qtyOnHand): void
    {
        $existing = DB::table('stock_balances')
            ->where('product_id', $productId)
            ->where('warehouse_id', $warehouseId)
            ->first();

        if ($existing) {
            DB::table('stock_balances')
                ->where('id', $existing->id)
                ->update([
                    'qty_on_hand' => $qtyOnHand,
                    'qty_reserved' => $existing->qty_reserved ?? 0,
                    'minimum_stock' => $existing->minimum_stock ?? $this->productMinimumStock($productId),
                    'updated_at' => now(),
                ]);

            return;
        }

        DB::table('stock_balances')->insert([
            'product_id' => $productId,
            'warehouse_id' => $warehouseId,
            'qty_on_hand' => $qtyOnHand,
            'qty_reserved' => 0,
            'minimum_stock' => $this->productMinimumStock($productId),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    private function createStockMovement(array $data): void
    {
        DB::table('stock_movements')->insert([
            'movement_number' => $data['movement_number'],
            'product_id' => $data['product_id'],
            'warehouse_id' => $data['warehouse_id'],
            'movement_type' => $data['movement_type'],
            'reference_type' => $data['reference_type'],
            'reference_id' => $data['reference_id'],
            'qty_in' => $data['qty_in'],
            'qty_out' => $data['qty_out'],
            'stock_before' => $data['stock_before'],
            'stock_after' => $data['stock_after'],
            'description' => $data['description'],
            'created_by' => $data['created_by'],
            'created_at' => $data['created_at'],
            'updated_at' => $data['updated_at'],
        ]);
    }

    private function productMinimumStock(int $productId): float
    {
        if (! Schema::hasTable('products')) {
            return 0;
        }

        if (Schema::hasColumn('products', 'minimum_stock')) {
            return (float) (DB::table('products')->where('id', $productId)->value('minimum_stock') ?? 0);
        }

        if (Schema::hasColumn('products', 'min_stock')) {
            return (float) (DB::table('products')->where('id', $productId)->value('min_stock') ?? 0);
        }

        return 0;
    }

    private function defaultUserId(): ?int
    {
        if (! Schema::hasTable('users')) {
            return null;
        }

        $id = DB::table('users')->value('id');

        return $id ? (int) $id : null;
    }

    private function approvedStatuses(): array
    {
        return [
            'approved',
            'approve',
            'disetujui',
            'selesai',
            'completed',
            'success',
        ];
    }

    private function dateFromTransaction(mixed $transactionDate, mixed $transactionCreatedAt, mixed $itemCreatedAt): Carbon
    {
        $value = $transactionDate ?: $transactionCreatedAt ?: $itemCreatedAt ?: now();

        return Carbon::parse($value);
    }

    private function generateMovementNumber(string $type, Carbon $date): string
    {
        $number = 'MOV-' . strtoupper($type) . '-' . $date->format('Ymd') . '-' . str_pad((string) $this->movementSequence, 6, '0', STR_PAD_LEFT);

        $this->movementSequence++;

        return $number;
    }
}