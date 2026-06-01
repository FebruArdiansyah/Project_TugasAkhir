<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

final class MobileTransactionHistoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $type = $request->query('type');     // inbound / outbound / null
        $status = $request->query('status'); // pending / approved / rejected / null
        $search = $request->query('search');

        $histories = collect();

        if ($type !== 'outbound') {
            $inbounds = DB::table('inbound_transactions')
                ->leftJoin('suppliers', 'suppliers.id', '=', 'inbound_transactions.supplier_id')
                ->join('warehouses', 'warehouses.id', '=', 'inbound_transactions.warehouse_id')
                ->where('inbound_transactions.submitted_by', $user->id)
                ->when($status, function ($query) use ($status): void {
                    $query->where('inbound_transactions.status', $status);
                })
                ->when($search, function ($query) use ($search): void {
                    $query->where(function ($subQuery) use ($search): void {
                        $subQuery
                            ->where('inbound_transactions.transaction_number', 'like', "%{$search}%")
                            ->orWhere('inbound_transactions.invoice_number', 'like', "%{$search}%")
                            ->orWhere('suppliers.name', 'like', "%{$search}%")
                            ->orWhere('warehouses.name', 'like', "%{$search}%");
                    });
                })
                ->get([
                    'inbound_transactions.id',
                    'inbound_transactions.transaction_number',
                    'inbound_transactions.transaction_date',
                    'inbound_transactions.invoice_number',
                    'inbound_transactions.status',
                    'inbound_transactions.note',
                    'inbound_transactions.grand_total',
                    'inbound_transactions.submitted_at',
                    'inbound_transactions.approved_at',
                    'inbound_transactions.rejected_at',
                    'inbound_transactions.rejection_reason',
                    'inbound_transactions.created_at',
                    'suppliers.name as partner_name',
                    'warehouses.name as warehouse_name',
                ])
                ->map(function ($transaction): array {
                    $items = DB::table('inbound_transaction_items')
                        ->where('inbound_transaction_id', $transaction->id)
                        ->get(['qty']);

                    return [
                        'id' => $transaction->id,
                        'type' => 'inbound',
                        'type_label' => 'Barang Masuk',
                        'detail_url' => '/api/mobile/v1/inbounds/'.$transaction->id,
                        'transaction_number' => $transaction->transaction_number,
                        'transaction_date' => $transaction->transaction_date,
                        'reference_number' => $transaction->invoice_number,
                        'partner_label' => 'Supplier',
                        'partner_name' => $transaction->partner_name,
                        'warehouse_name' => $transaction->warehouse_name,
                        'status' => $transaction->status,
                        'total_items' => $items->count(),
                        'total_qty' => $items->sum(fn ($item) => (float) $item->qty),
                        'grand_total' => (float) $transaction->grand_total,
                        'note' => $transaction->note,
                        'submitted_at' => $transaction->submitted_at,
                        'approved_at' => $transaction->approved_at,
                        'rejected_at' => $transaction->rejected_at,
                        'rejection_reason' => $transaction->rejection_reason,
                        'created_at' => $transaction->created_at,
                    ];
                });

            $histories = $histories->merge($inbounds);
        }

        if ($type !== 'inbound') {
            $outbounds = DB::table('outbound_transactions')
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
                ->get([
                    'outbound_transactions.id',
                    'outbound_transactions.transaction_number',
                    'outbound_transactions.transaction_date',
                    'outbound_transactions.reference_number',
                    'outbound_transactions.outbound_type',
                    'outbound_transactions.status',
                    'outbound_transactions.note',
                    'outbound_transactions.grand_total',
                    'outbound_transactions.submitted_at',
                    'outbound_transactions.approved_at',
                    'outbound_transactions.rejected_at',
                    'outbound_transactions.rejection_reason',
                    'outbound_transactions.created_at',
                    'customers.name as partner_name',
                    'warehouses.name as warehouse_name',
                ])
                ->map(function ($transaction): array {
                    $items = DB::table('outbound_transaction_items')
                        ->where('outbound_transaction_id', $transaction->id)
                        ->get(['qty']);

                    return [
                        'id' => $transaction->id,
                        'type' => 'outbound',
                        'type_label' => 'Barang Keluar',
                        'detail_url' => '/api/mobile/v1/outbounds/'.$transaction->id,
                        'transaction_number' => $transaction->transaction_number,
                        'transaction_date' => $transaction->transaction_date,
                        'reference_number' => $transaction->reference_number,
                        'outbound_type' => $transaction->outbound_type,
                        'partner_label' => 'Customer / Tujuan',
                        'partner_name' => $transaction->partner_name,
                        'warehouse_name' => $transaction->warehouse_name,
                        'status' => $transaction->status,
                        'total_items' => $items->count(),
                        'total_qty' => $items->sum(fn ($item) => (float) $item->qty),
                        'grand_total' => (float) $transaction->grand_total,
                        'note' => $transaction->note,
                        'submitted_at' => $transaction->submitted_at,
                        'approved_at' => $transaction->approved_at,
                        'rejected_at' => $transaction->rejected_at,
                        'rejection_reason' => $transaction->rejection_reason,
                        'created_at' => $transaction->created_at,
                    ];
                });

            $histories = $histories->merge($outbounds);
        }

        $histories = $histories
            ->sortByDesc('created_at')
            ->values();

        return response()->json([
            'success' => true,
            'data' => $histories,
            'meta' => [
                'total' => $histories->count(),
                'filter' => [
                    'type' => $type,
                    'status' => $status,
                    'search' => $search,
                ],
            ],
        ]);
    }
}