<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\ApprovalLog;
use App\Models\InboundTransaction;
use App\Models\OutboundTransaction;
use App\Models\Product;
use App\Models\StockBalance;
use App\Models\StockMovement;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class InventoryApprovalService
{
    public function approveInbound(InboundTransaction $transaction, ?string $note = null): void
    {
        DB::transaction(function () use ($transaction, $note): void {
            $transaction = InboundTransaction::query()
                ->with(['items.product', 'items.unit'])
                ->lockForUpdate()
                ->findOrFail($transaction->id);

            if ($transaction->status !== 'pending') {
                throw ValidationException::withMessages([
                    'status' => 'Transaksi barang masuk ini sudah tidak berstatus pending.',
                ]);
            }

            foreach ($transaction->items as $itemRow) {
                $warehouseId = $itemRow->warehouse_id ?: $transaction->warehouse_id;

                $balance = StockBalance::query()
                    ->where('product_id', $itemRow->product_id)
                    ->where('warehouse_id', $warehouseId)
                    ->lockForUpdate()
                    ->first();

                if (! $balance) {
                    $balance = StockBalance::query()->create([
                        'product_id' => $itemRow->product_id,
                        'warehouse_id' => $warehouseId,
                        'qty_on_hand' => 0,
                        'qty_reserved' => 0,
                        'minimum_stock' => 0,
                    ]);
                }

                $stockBefore = (float) $balance->qty_on_hand;
                $qtyIn = (float) $itemRow->qty;
                $stockAfter = $stockBefore + $qtyIn;

                $balance->update([
                    'qty_on_hand' => $stockAfter,
                ]);

                StockMovement::query()->create([
                    'movement_number' => $this->generateMovementNumber('IN'),
                    'product_id' => $itemRow->product_id,
                    'warehouse_id' => $warehouseId,
                    'movement_type' => 'IN',
                    'reference_type' => InboundTransaction::class,
                    'reference_id' => $transaction->id,
                    'qty_in' => $qtyIn,
                    'qty_out' => 0,
                    'stock_before' => $stockBefore,
                    'stock_after' => $stockAfter,
                    'description' => 'Approve barang masuk: ' . $transaction->transaction_number,
                    'created_by' => Auth::id(),
                ]);

                if ((float) $itemRow->unit_cost > 0) {
                    Product::query()
                        ->whereKey($itemRow->product_id)
                        ->update([
                            'last_purchase_price' => $itemRow->unit_cost,
                        ]);
                }
            }

            $oldStatus = $transaction->status;

            $transaction->update([
                'status' => 'approved',
                'approved_by' => Auth::id(),
                'approved_at' => now(),
                'approval_note' => $note,
            ]);

            $this->logApproval($transaction, 'approved', $oldStatus, 'approved', $note);
        });
    }

    public function rejectInbound(InboundTransaction $transaction, string $reason): void
    {
        DB::transaction(function () use ($transaction, $reason): void {
            $transaction = InboundTransaction::query()
                ->lockForUpdate()
                ->findOrFail($transaction->id);

            if ($transaction->status !== 'pending') {
                throw ValidationException::withMessages([
                    'status' => 'Transaksi barang masuk ini sudah tidak berstatus pending.',
                ]);
            }

            $oldStatus = $transaction->status;

            $transaction->update([
                'status' => 'rejected',
                'rejected_by' => Auth::id(),
                'rejected_at' => now(),
                'rejection_reason' => $reason,
            ]);

            $this->logApproval($transaction, 'rejected', $oldStatus, 'rejected', $reason);
        });
    }

    public function approveOutbound(OutboundTransaction $transaction, ?string $note = null): void
    {
        DB::transaction(function () use ($transaction, $note): void {
            $transaction = OutboundTransaction::query()
                ->with(['items.product', 'items.unit'])
                ->lockForUpdate()
                ->findOrFail($transaction->id);

            if ($transaction->status !== 'pending') {
                throw ValidationException::withMessages([
                    'status' => 'Transaksi barang keluar ini sudah tidak berstatus pending.',
                ]);
            }

            foreach ($transaction->items as $itemRow) {
                $warehouseId = $itemRow->warehouse_id ?: $transaction->warehouse_id;

                $balance = StockBalance::query()
                    ->where('product_id', $itemRow->product_id)
                    ->where('warehouse_id', $warehouseId)
                    ->lockForUpdate()
                    ->first();

                if (! $balance) {
                    throw ValidationException::withMessages([
                        'stock' => 'Stok produk tidak ditemukan.',
                    ]);
                }

                $stockBefore = (float) $balance->qty_on_hand;
                $reservedBefore = (float) $balance->qty_reserved;
                $qtyOut = (float) $itemRow->qty;

                if ($stockBefore < $qtyOut) {
                    throw ValidationException::withMessages([
                        'stock' => 'Stok tidak cukup untuk approve barang keluar.',
                    ]);
                }

                $stockAfter = $stockBefore - $qtyOut;
                $reservedAfter = max(0, $reservedBefore - $qtyOut);

                $balance->update([
                    'qty_on_hand' => $stockAfter,
                    'qty_reserved' => $reservedAfter,
                ]);

                StockMovement::query()->create([
                    'movement_number' => $this->generateMovementNumber('OUT'),
                    'product_id' => $itemRow->product_id,
                    'warehouse_id' => $warehouseId,
                    'movement_type' => 'OUT',
                    'reference_type' => OutboundTransaction::class,
                    'reference_id' => $transaction->id,
                    'qty_in' => 0,
                    'qty_out' => $qtyOut,
                    'stock_before' => $stockBefore,
                    'stock_after' => $stockAfter,
                    'description' => 'Approve barang keluar: ' . $transaction->transaction_number,
                    'created_by' => Auth::id(),
                ]);

                if ((float) $itemRow->unit_price > 0) {
                    Product::query()
                        ->whereKey($itemRow->product_id)
                        ->update([
                            'last_selling_price' => $itemRow->unit_price,
                        ]);
                }
            }

            $oldStatus = $transaction->status;

            $transaction->update([
                'status' => 'approved',
                'approved_by' => Auth::id(),
                'approved_at' => now(),
                'approval_note' => $note,
            ]);

            $this->logApproval($transaction, 'approved', $oldStatus, 'approved', $note);
        });
    }

    public function rejectOutbound(OutboundTransaction $transaction, string $reason): void
    {
        DB::transaction(function () use ($transaction, $reason): void {
            $transaction = OutboundTransaction::query()
                ->with('items')
                ->lockForUpdate()
                ->findOrFail($transaction->id);

            if ($transaction->status !== 'pending') {
                throw ValidationException::withMessages([
                    'status' => 'Transaksi barang keluar ini sudah tidak berstatus pending.',
                ]);
            }

            foreach ($transaction->items as $itemRow) {
                $warehouseId = $itemRow->warehouse_id ?: $transaction->warehouse_id;

                $balance = StockBalance::query()
                    ->where('product_id', $itemRow->product_id)
                    ->where('warehouse_id', $warehouseId)
                    ->lockForUpdate()
                    ->first();

                if ($balance) {
                    $balance->update([
                        'qty_reserved' => max(
                            0,
                            (float) $balance->qty_reserved - (float) $itemRow->qty
                        ),
                    ]);
                }
            }

            $oldStatus = $transaction->status;

            $transaction->update([
                'status' => 'rejected',
                'rejected_by' => Auth::id(),
                'rejected_at' => now(),
                'rejection_reason' => $reason,
            ]);

            $this->logApproval($transaction, 'rejected', $oldStatus, 'rejected', $reason);
        });
    }

    private function logApproval(
        object $transaction,
        string $action,
        ?string $oldStatus,
        string $newStatus,
        ?string $note
    ): void {
        ApprovalLog::query()->create([
            'approvable_type' => $transaction::class,
            'approvable_id' => $transaction->id,
            'action' => $action,
            'old_status' => $oldStatus,
            'new_status' => $newStatus,
            'note' => $note,
            'acted_by' => Auth::id(),
            'acted_at' => now(),
        ]);
    }

    private function generateMovementNumber(string $type): string
    {
        return sprintf(
            '%s-%s-%s',
            $type,
            now()->format('YmdHis'),
            random_int(1000, 9999)
        );
    }
}
