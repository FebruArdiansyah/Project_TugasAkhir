<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\ApprovalLog;
use App\Models\InboundTransaction;
use App\Models\OutboundTransaction;
use App\Models\StockBalance;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

final class InventorySubmissionService
{
    public function submitInbound(InboundTransaction $transaction): void
    {
        ApprovalLog::query()->create([
            'approvable_type' => InboundTransaction::class,
            'approvable_id' => $transaction->id,
            'action' => 'submitted',
            'old_status' => null,
            'new_status' => $transaction->status,
            'note' => 'Transaksi barang masuk dibuat dan menunggu approval.',
            'acted_by' => Auth::id(),
            'acted_at' => now(),
        ]);
    }

    public function submitOutbound(OutboundTransaction $transaction): void
    {
        DB::transaction(function () use ($transaction): void {
            $transaction = OutboundTransaction::query()
                ->with('items')
                ->lockForUpdate()
                ->findOrFail($transaction->id);

            if ($transaction->status !== 'pending') {
                return;
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
                        'stock' => 'Stok produk tidak ditemukan untuk barang keluar.',
                    ]);
                }

                $availableStock = (float) $balance->qty_on_hand - (float) $balance->qty_reserved;
                $qtyOut = (float) $itemRow->qty;

                if ($availableStock < $qtyOut) {
                    throw ValidationException::withMessages([
                        'stock' => 'Stok tersedia tidak cukup. Stok tersedia: ' . $availableStock,
                    ]);
                }

                $balance->update([
                    'qty_reserved' => (float) $balance->qty_reserved + $qtyOut,
                ]);
            }

            ApprovalLog::query()->create([
                'approvable_type' => OutboundTransaction::class,
                'approvable_id' => $transaction->id,
                'action' => 'submitted',
                'old_status' => null,
                'new_status' => $transaction->status,
                'note' => 'Transaksi barang keluar dibuat dan stok di-reserve menunggu approval.',
                'acted_by' => Auth::id(),
                'acted_at' => now(),
            ]);
        });
    }
}