<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

final class MobileStockController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $warehouseId = $request->query('warehouse_id');
        $productId = $request->query('product_id');
        $search = $request->query('search');

        $data = DB::table('stock_balances')
            ->join('products', 'products.id', '=', 'stock_balances.product_id')
            ->join('warehouses', 'warehouses.id', '=', 'stock_balances.warehouse_id')
            ->where('products.is_active', true)
            ->where('warehouses.is_active', true)
            ->when($warehouseId, function ($query) use ($warehouseId): void {
                $query->where('stock_balances.warehouse_id', $warehouseId);
            })
            ->when($productId, function ($query) use ($productId): void {
                $query->where('stock_balances.product_id', $productId);
            })
            ->when($search, function ($query) use ($search): void {
                $query->where(function ($subQuery) use ($search): void {
                    $subQuery
                        ->where('products.code', 'like', "%{$search}%")
                        ->orWhere('products.name', 'like', "%{$search}%")
                        ->orWhere('products.full_name', 'like', "%{$search}%")
                        ->orWhere('products.size_text', 'like', "%{$search}%")
                        ->orWhere('warehouses.name', 'like', "%{$search}%");
                });
            })
            ->orderBy('products.name')
            ->get([
                'stock_balances.id',
                'stock_balances.product_id',
                'stock_balances.warehouse_id',
                'stock_balances.qty_on_hand',
                'stock_balances.qty_reserved',
                'stock_balances.minimum_stock',
                'products.code as product_code',
                'products.name as product_name',
                'products.full_name as product_full_name',
                'products.size_text as product_size_text',
                'products.unit_id as unit_id',
                'warehouses.code as warehouse_code',
                'warehouses.name as warehouse_name',
            ])
            ->map(function ($stock): array {
                $qtyOnHand = (float) $stock->qty_on_hand;
                $qtyReserved = (float) $stock->qty_reserved;
                $availableQty = $qtyOnHand - $qtyReserved;
                $minimumStock = (float) $stock->minimum_stock;

                return [
                    'id' => $stock->id,
                    'product_id' => $stock->product_id,
                    'warehouse_id' => $stock->warehouse_id,
                    'product_code' => $stock->product_code,
                    'product_name' => $stock->product_name,
                    'product_display_name' => $stock->product_full_name ?: $stock->product_name,
                    'product_size_text' => $stock->product_size_text,
                    'unit_id' => $stock->unit_id,
                    'warehouse_code' => $stock->warehouse_code,
                    'warehouse_name' => $stock->warehouse_name,
                    'qty_on_hand' => $qtyOnHand,
                    'qty_reserved' => $qtyReserved,
                    'available_qty' => $availableQty,
                    'minimum_stock' => $minimumStock,
                    'is_low_stock' => $availableQty <= $minimumStock,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }
}