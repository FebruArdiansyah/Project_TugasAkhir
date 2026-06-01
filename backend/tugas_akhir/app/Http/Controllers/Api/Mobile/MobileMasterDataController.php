<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

final class MobileMasterDataController extends Controller
{
    public function warehouses(): JsonResponse
    {
        $data = DB::table('warehouses')
            ->where('is_active', true)
            ->orderBy('name')
            ->get(['id', 'code', 'name', 'address', 'phone']);

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    public function suppliers(): JsonResponse
    {
        $data = DB::table('suppliers')
            ->where('is_active', true)
            ->orderBy('name')
            ->get(['id', 'code', 'name', 'phone', 'address']);

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    public function customers(): JsonResponse
    {
        $data = DB::table('customers')
            ->where('is_active', true)
            ->orderBy('name')
            ->get(['id', 'code', 'name', 'phone', 'address', 'customer_type']);

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    public function products(Request $request): JsonResponse
    {
        $search = $request->query('search');

        $data = DB::table('products')
            ->where('is_active', true)
            ->when($search, function ($query) use ($search): void {
                $query->where(function ($subQuery) use ($search): void {
                    $subQuery
                        ->where('code', 'like', "%{$search}%")
                        ->orWhere('name', 'like', "%{$search}%")
                        ->orWhere('full_name', 'like', "%{$search}%")
                        ->orWhere('size_text', 'like', "%{$search}%");
                });
            })
            ->orderBy('name')
            ->get([
                'id',
                'code',
                'name',
                'full_name',
                'product_type_id',
                'product_density_id',
                'product_category_id',
                'unit_id',
                'length',
                'width',
                'thickness',
                'size_text',
                'default_purchase_price',
                'default_selling_price',
                'last_purchase_price',
                'last_selling_price',
            ])
            ->map(function ($product): array {
                return [
                    'id' => $product->id,
                    'code' => $product->code,
                    'name' => $product->name,
                    'display_name' => $product->full_name ?: $product->name,
                    'full_name' => $product->full_name,
                    'product_type_id' => $product->product_type_id,
                    'product_density_id' => $product->product_density_id,
                    'product_category_id' => $product->product_category_id,
                    'unit_id' => $product->unit_id,
                    'length' => $product->length !== null ? (float) $product->length : null,
                    'width' => $product->width !== null ? (float) $product->width : null,
                    'thickness' => $product->thickness !== null ? (float) $product->thickness : null,
                    'size_text' => $product->size_text,
                    'default_purchase_price' => (float) $product->default_purchase_price,
                    'default_selling_price' => (float) $product->default_selling_price,
                    'last_purchase_price' => (float) $product->last_purchase_price,
                    'last_selling_price' => (float) $product->last_selling_price,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }
}