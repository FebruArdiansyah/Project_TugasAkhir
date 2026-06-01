<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\InboundTransaction;
use App\Models\OutboundTransaction;
use Illuminate\Support\Facades\DB;

final class InventoryTransactionTotalService
{
    public function recalculateInbound(InboundTransaction $transaction): void
    {
        DB::transaction(function () use ($transaction): void {
            $transaction->load('items');

            $subTotal = 0;

            foreach ($transaction->items as $item) {
                $qty = (float) $item->qty;
                $unitCost = (float) $item->unit_cost;
                $subtotal = max(0, $qty * $unitCost);

                $item->forceFill([
                    'subtotal' => $subtotal,
                ])->save();

                $subTotal += $subtotal;
            }

            $discountAmount = (float) $transaction->discount_amount;
            $otherCost = (float) $transaction->other_cost;
            $grandTotal = max(0, $subTotal - $discountAmount + $otherCost);

            $transaction->forceFill([
                'sub_total' => $subTotal,
                'grand_total' => $grandTotal,
            ])->save();
        });
    }

    public function recalculateOutbound(OutboundTransaction $transaction): void
    {
        DB::transaction(function () use ($transaction): void {
            $transaction->load('items');

            $subTotal = 0;

            foreach ($transaction->items as $item) {
                $qty = (float) $item->qty;
                $unitPrice = (float) $item->unit_price;
                $itemDiscount = (float) $item->discount_amount;

                $subtotal = max(0, ($qty * $unitPrice) - $itemDiscount);

                $item->forceFill([
                    'subtotal' => $subtotal,
                ])->save();

                $subTotal += $subtotal;
            }

            $documentDiscount = (float) $transaction->discount_amount;
            $vatAmount = (float) $transaction->vat_amount;
            $otherCost = (float) $transaction->other_cost;
            $paidAmount = (float) $transaction->paid_amount;

            $grandTotal = max(0, $subTotal - $documentDiscount + $vatAmount + $otherCost);
            $remainingAmount = max(0, $grandTotal - $paidAmount);

            $transaction->forceFill([
                'sub_total' => $subTotal,
                'grand_total' => $grandTotal,
                'remaining_amount' => $remainingAmount,
            ])->save();
        });
    }
}