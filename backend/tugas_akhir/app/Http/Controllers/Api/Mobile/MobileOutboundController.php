<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

final class MobileOutboundController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $status = $request->query('status');
        $search = $request->query('search');

        $data = DB::table('outbound_transactions')
            ->leftJoin('customers', 'customers.id', '=', 'outbound_transactions.customer_id')
            ->join('warehouses', 'warehouses.id', '=', 'outbound_transactions.warehouse_id')
            ->where('outbound_transactions.submitted_by', $user->id)
            ->when($status, function ($query) use ($status): void {
                $query->where('outbound_transactions.status', $status);
            })
            ->when($search, function ($query) use ($search): void {
                $query->where(function ($subQuery) use ($search): void {
                    $subQuery
                        ->where('outbound_transactions.transaction_number', 'like', "%{$search}%")
                        ->orWhere('outbound_transactions.reference_number', 'like', "%{$search}%")
                        ->orWhere('customers.name', 'like', "%{$search}%")
                        ->orWhere('warehouses.name', 'like', "%{$search}%");
                });
            })
            ->orderByDesc('outbound_transactions.transaction_date')
            ->orderByDesc('outbound_transactions.id')
            ->get([
                'outbound_transactions.id',
                'outbound_transactions.transaction_number',
                'outbound_transactions.transaction_date',
                'outbound_transactions.outbound_type',
                'outbound_transactions.reference_number',
                'outbound_transactions.status',
                'outbound_transactions.note',
                'outbound_transactions.grand_total',
                'outbound_transactions.submitted_at',
                'outbound_transactions.approved_at',
                'outbound_transactions.rejected_at',
                'outbound_transactions.rejection_reason',
                'customers.id as customer_id',
                'customers.name as customer_name',
                'warehouses.id as warehouse_id',
                'warehouses.name as warehouse_name',
            ])
            ->map(function ($transaction): array {
                $items = DB::table('outbound_transaction_items')
                    ->where('outbound_transaction_id', $transaction->id)
                    ->get(['qty']);

                $totalQty = $items->sum(fn ($item) => (float) $item->qty);

                return [
                    'id' => $transaction->id,
                    'transaction_number' => $transaction->transaction_number,
                    'transaction_date' => $transaction->transaction_date,
                    'outbound_type' => $transaction->outbound_type,
                    'reference_number' => $transaction->reference_number,
                    'status' => $transaction->status,
                    'customer' => [
                        'id' => $transaction->customer_id,
                        'name' => $transaction->customer_name,
                    ],
                    'warehouse' => [
                        'id' => $transaction->warehouse_id,
                        'name' => $transaction->warehouse_name,
                    ],
                    'total_items' => $items->count(),
                    'total_qty' => $totalQty,
                    'grand_total' => (float) $transaction->grand_total,
                    'note' => $transaction->note,
                    'submitted_at' => $transaction->submitted_at,
                    'approved_at' => $transaction->approved_at,
                    'rejected_at' => $transaction->rejected_at,
                    'rejection_reason' => $transaction->rejection_reason,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'transaction_date' => ['required', 'date'],
            'outbound_type' => ['required', 'string', 'max:255'],
            'reference_number' => ['nullable', 'string', 'max:255'],
            'customer_id' => ['nullable', 'integer', 'exists:customers,id'],
            'warehouse_id' => ['required', 'integer', 'exists:warehouses,id'],
            'sales_name' => ['nullable', 'string', 'max:255'],
            'driver_name' => ['nullable', 'string', 'max:255'],
            'due_date' => ['nullable', 'date'],
            'note' => ['nullable', 'string'],

            'discount_amount' => ['nullable', 'numeric', 'min:0'],
            'vat_percent' => ['nullable', 'numeric', 'min:0'],
            'vat_amount' => ['nullable', 'numeric', 'min:0'],
            'other_cost' => ['nullable', 'numeric', 'min:0'],
            'paid_amount' => ['nullable', 'numeric', 'min:0'],

            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.qty' => ['required', 'numeric', 'min:0.01'],
            'items.*.unit_price' => ['nullable', 'numeric', 'min:0'],
            'items.*.discount_amount' => ['nullable', 'numeric', 'min:0'],
            'items.*.note' => ['nullable', 'string'],

            'attachments' => ['nullable', 'array', 'max:3'],
            'attachments.*' => ['file', 'mimes:jpg,jpeg,png,webp,pdf', 'max:5120'],
        ]);

        $user = $request->user();

        $transaction = DB::transaction(function () use ($request, $validated, $user) {
            $transactionNumber = $this->generateTransactionNumber();

            $warehouseId = (int) $validated['warehouse_id'];

            $subTotal = 0;

            foreach ($validated['items'] as $item) {
                $product = DB::table('products')
                    ->where('id', $item['product_id'])
                    ->first([
                        'id',
                        'code',
                        'name',
                        'full_name',
                        'unit_id',
                        'last_selling_price',
                        'default_selling_price',
                    ]);

                $qty = (float) $item['qty'];

                $stockBalance = DB::table('stock_balances')
                    ->where('product_id', $product->id)
                    ->where('warehouse_id', $warehouseId)
                    ->lockForUpdate()
                    ->first(['qty_on_hand', 'qty_reserved']);

                $qtyOnHand = $stockBalance ? (float) $stockBalance->qty_on_hand : 0;
                $qtyReserved = $stockBalance ? (float) $stockBalance->qty_reserved : 0;
                $availableQty = $qtyOnHand - $qtyReserved;

                if ($qty > $availableQty) {
                    abort(response()->json([
                        'success' => false,
                        'message' => 'Stok tidak mencukupi untuk produk '.$product->code.' - '.($product->full_name ?: $product->name).'.',
                        'errors' => [
                            'stock' => [
                                'available_qty' => $availableQty,
                                'requested_qty' => $qty,
                            ],
                        ],
                    ], 422));
                }

                $unitPrice = isset($item['unit_price'])
                    ? (float) $item['unit_price']
                    : (float) ($product->last_selling_price ?: $product->default_selling_price ?: 0);

                $itemDiscount = isset($item['discount_amount'])
                    ? (float) $item['discount_amount']
                    : 0;

                $subTotal += max(($qty * $unitPrice) - $itemDiscount, 0);
            }

            $discountAmount = isset($validated['discount_amount']) ? (float) $validated['discount_amount'] : 0;
            $vatPercent = isset($validated['vat_percent']) ? (float) $validated['vat_percent'] : 0;
            $manualVatAmount = isset($validated['vat_amount']) ? (float) $validated['vat_amount'] : 0;
            $otherCost = isset($validated['other_cost']) ? (float) $validated['other_cost'] : 0;
            $paidAmount = isset($validated['paid_amount']) ? (float) $validated['paid_amount'] : 0;

            $vatAmount = $manualVatAmount > 0
                ? $manualVatAmount
                : max(($subTotal - $discountAmount) * ($vatPercent / 100), 0);

            $grandTotal = max($subTotal - $discountAmount + $vatAmount + $otherCost, 0);
            $remainingAmount = max($grandTotal - $paidAmount, 0);

            $transactionId = DB::table('outbound_transactions')->insertGetId([
                'transaction_number' => $transactionNumber,
                'transaction_date' => $validated['transaction_date'],
                'outbound_type' => $validated['outbound_type'],
                'reference_number' => $validated['reference_number'] ?? null,
                'customer_id' => $validated['customer_id'] ?? null,
                'warehouse_id' => $warehouseId,
                'sales_name' => $validated['sales_name'] ?? null,
                'driver_name' => $validated['driver_name'] ?? null,
                'due_date' => $validated['due_date'] ?? null,
                'note' => $validated['note'] ?? null,
                'status' => 'pending',
                'sub_total' => $subTotal,
                'discount_amount' => $discountAmount,
                'vat_percent' => $vatPercent,
                'vat_amount' => $vatAmount,
                'other_cost' => $otherCost,
                'grand_total' => $grandTotal,
                'paid_amount' => $paidAmount,
                'remaining_amount' => $remainingAmount,
                'submitted_by' => $user->id,
                'submitted_at' => now(),
                'source' => 'mobile',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach ($validated['items'] as $item) {
                $product = DB::table('products')
                    ->where('id', $item['product_id'])
                    ->first([
                        'id',
                        'code',
                        'name',
                        'full_name',
                        'unit_id',
                        'last_selling_price',
                        'default_selling_price',
                    ]);

                $stockBalance = DB::table('stock_balances')
                    ->where('product_id', $product->id)
                    ->where('warehouse_id', $warehouseId)
                    ->first(['qty_on_hand', 'qty_reserved']);

                $qtyOnHand = $stockBalance ? (float) $stockBalance->qty_on_hand : 0;
                $qtyReserved = $stockBalance ? (float) $stockBalance->qty_reserved : 0;
                $availableQty = $qtyOnHand - $qtyReserved;

                $qty = (float) $item['qty'];

                $unitPrice = isset($item['unit_price'])
                    ? (float) $item['unit_price']
                    : (float) ($product->last_selling_price ?: $product->default_selling_price ?: 0);

                $itemDiscount = isset($item['discount_amount'])
                    ? (float) $item['discount_amount']
                    : 0;

                $subtotal = max(($qty * $unitPrice) - $itemDiscount, 0);

                $unitName = null;

                if ($product->unit_id) {
                    $unitName = DB::table('units')
                        ->where('id', $product->unit_id)
                        ->value('name');
                }

                DB::table('outbound_transaction_items')->insert([
                    'outbound_transaction_id' => $transactionId,
                    'product_id' => $product->id,
                    'warehouse_id' => $warehouseId,
                    'unit_id' => $product->unit_id,
                    'qty' => $qty,
                    'unit_price' => $unitPrice,
                    'discount_amount' => $itemDiscount,
                    'subtotal' => $subtotal,
                    'stock_before_submit' => $availableQty,
                    'stock_after_submit' => $availableQty - $qty,
                    'product_code_snapshot' => $product->code,
                    'product_name_snapshot' => $product->full_name ?: $product->name,
                    'unit_name_snapshot' => $unitName,
                    'note' => $item['note'] ?? null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            if ($request->hasFile('attachments')) {
                foreach ($request->file('attachments') as $file) {
                    $path = $file->store('inventory/outbounds/'.$transactionId, 'public');

                    DB::table('outbound_transaction_attachments')->insert([
                        'outbound_transaction_id' => $transactionId,
                        'file_path' => $path,
                        'file_name' => $file->getClientOriginalName(),
                        'mime_type' => $file->getClientMimeType(),
                        'file_size' => $file->getSize(),
                        'uploaded_by' => $user->id,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }

            return DB::table('outbound_transactions')
                ->where('id', $transactionId)
                ->first();
        });

        return response()->json([
            'success' => true,
            'message' => 'Pengajuan barang keluar berhasil dikirim. Menunggu approval admin.',
            'data' => [
                'id' => $transaction->id,
                'transaction_number' => $transaction->transaction_number,
                'transaction_date' => $transaction->transaction_date,
                'status' => $transaction->status,
            ],
        ], 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        $transaction = DB::table('outbound_transactions')
            ->leftJoin('customers', 'customers.id', '=', 'outbound_transactions.customer_id')
            ->join('warehouses', 'warehouses.id', '=', 'outbound_transactions.warehouse_id')
            ->leftJoin('users as submitter', 'submitter.id', '=', 'outbound_transactions.submitted_by')
            ->where('outbound_transactions.id', $id)
            ->where('outbound_transactions.submitted_by', $user->id)
            ->first([
                'outbound_transactions.id',
                'outbound_transactions.transaction_number',
                'outbound_transactions.transaction_date',
                'outbound_transactions.outbound_type',
                'outbound_transactions.reference_number',
                'outbound_transactions.sales_name',
                'outbound_transactions.driver_name',
                'outbound_transactions.due_date',
                'outbound_transactions.status',
                'outbound_transactions.note',
                'outbound_transactions.sub_total',
                'outbound_transactions.discount_amount',
                'outbound_transactions.vat_percent',
                'outbound_transactions.vat_amount',
                'outbound_transactions.other_cost',
                'outbound_transactions.grand_total',
                'outbound_transactions.paid_amount',
                'outbound_transactions.remaining_amount',
                'outbound_transactions.submitted_at',
                'outbound_transactions.approved_at',
                'outbound_transactions.rejected_at',
                'outbound_transactions.rejection_reason',
                'outbound_transactions.approval_note',
                'customers.id as customer_id',
                'customers.code as customer_code',
                'customers.name as customer_name',
                'warehouses.id as warehouse_id',
                'warehouses.code as warehouse_code',
                'warehouses.name as warehouse_name',
                'submitter.id as submitted_by_id',
                'submitter.name as submitted_by_name',
            ]);

        if (! $transaction) {
            return response()->json([
                'success' => false,
                'message' => 'Data barang keluar tidak ditemukan.',
            ], 404);
        }

        $items = DB::table('outbound_transaction_items')
            ->leftJoin('products', 'products.id', '=', 'outbound_transaction_items.product_id')
            ->where('outbound_transaction_items.outbound_transaction_id', $transaction->id)
            ->orderBy('outbound_transaction_items.id')
            ->get([
                'outbound_transaction_items.id',
                'outbound_transaction_items.product_id',
                'outbound_transaction_items.warehouse_id',
                'outbound_transaction_items.unit_id',
                'outbound_transaction_items.qty',
                'outbound_transaction_items.unit_price',
                'outbound_transaction_items.discount_amount',
                'outbound_transaction_items.subtotal',
                'outbound_transaction_items.stock_before_submit',
                'outbound_transaction_items.stock_after_submit',
                'outbound_transaction_items.product_code_snapshot',
                'outbound_transaction_items.product_name_snapshot',
                'outbound_transaction_items.unit_name_snapshot',
                'outbound_transaction_items.note',
                'products.code as current_product_code',
                'products.name as current_product_name',
                'products.full_name as current_product_full_name',
                'products.size_text as product_size_text',
            ])
            ->map(function ($item): array {
                return [
                    'id' => $item->id,
                    'product_id' => $item->product_id,
                    'warehouse_id' => $item->warehouse_id,
                    'unit_id' => $item->unit_id,
                    'product_code' => $item->product_code_snapshot ?: $item->current_product_code,
                    'product_name' => $item->product_name_snapshot ?: ($item->current_product_full_name ?: $item->current_product_name),
                    'product_size_text' => $item->product_size_text,
                    'unit_name' => $item->unit_name_snapshot,
                    'qty' => (float) $item->qty,
                    'unit_price' => (float) $item->unit_price,
                    'discount_amount' => (float) $item->discount_amount,
                    'subtotal' => (float) $item->subtotal,
                    'stock_before_submit' => (float) $item->stock_before_submit,
                    'stock_after_submit' => (float) $item->stock_after_submit,
                    'note' => $item->note,
                ];
            });

        $attachments = DB::table('outbound_transaction_attachments')
            ->where('outbound_transaction_id', $transaction->id)
            ->orderBy('id')
            ->get([
                'id',
                'file_path',
                'file_name',
                'mime_type',
                'file_size',
                'uploaded_by',
                'created_at',
            ])
            ->map(function ($attachment): array {
                return [
                    'id' => $attachment->id,
                    'file_path' => $attachment->file_path,
                    'file_url' => asset('storage/'.$attachment->file_path),
                    'file_name' => $attachment->file_name,
                    'mime_type' => $attachment->mime_type,
                    'file_size' => $attachment->file_size,
                    'uploaded_by' => $attachment->uploaded_by,
                    'created_at' => $attachment->created_at,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $transaction->id,
                'transaction_number' => $transaction->transaction_number,
                'transaction_date' => $transaction->transaction_date,
                'outbound_type' => $transaction->outbound_type,
                'reference_number' => $transaction->reference_number,
                'status' => $transaction->status,
                'customer' => [
                    'id' => $transaction->customer_id,
                    'code' => $transaction->customer_code,
                    'name' => $transaction->customer_name,
                ],
                'warehouse' => [
                    'id' => $transaction->warehouse_id,
                    'code' => $transaction->warehouse_code,
                    'name' => $transaction->warehouse_name,
                ],
                'submitted_by' => [
                    'id' => $transaction->submitted_by_id,
                    'name' => $transaction->submitted_by_name,
                ],
                'sales_name' => $transaction->sales_name,
                'driver_name' => $transaction->driver_name,
                'due_date' => $transaction->due_date,
                'items' => $items,
                'attachments' => $attachments,
                'summary' => [
                    'total_items' => $items->count(),
                    'total_qty' => $items->sum(fn ($item) => (float) $item['qty']),
                    'sub_total' => (float) $transaction->sub_total,
                    'discount_amount' => (float) $transaction->discount_amount,
                    'vat_percent' => (float) $transaction->vat_percent,
                    'vat_amount' => (float) $transaction->vat_amount,
                    'other_cost' => (float) $transaction->other_cost,
                    'grand_total' => (float) $transaction->grand_total,
                    'paid_amount' => (float) $transaction->paid_amount,
                    'remaining_amount' => (float) $transaction->remaining_amount,
                ],
                'note' => $transaction->note,
                'submitted_at' => $transaction->submitted_at,
                'approved_at' => $transaction->approved_at,
                'rejected_at' => $transaction->rejected_at,
                'rejection_reason' => $transaction->rejection_reason,
                'approval_note' => $transaction->approval_note,
            ],
        ]);
    }

    private function generateTransactionNumber(): string
    {
        $prefix = 'BK-'.now()->format('Ym').'-';

        $lastNumber = DB::table('outbound_transactions')
            ->where('transaction_number', 'like', $prefix.'%')
            ->lockForUpdate()
            ->orderByDesc('transaction_number')
            ->value('transaction_number');

        if (! $lastNumber) {
            return $prefix.'001';
        }

        $lastSequence = (int) Str::afterLast($lastNumber, '-');
        $nextSequence = $lastSequence + 1;

        return $prefix.str_pad((string) $nextSequence, 3, '0', STR_PAD_LEFT);
    }
}