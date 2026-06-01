<?php

namespace App\Console\Commands;

use App\Models\Customer;
use App\Models\InboundTransaction;
use App\Models\OutboundTransaction;
use App\Models\Product;
use App\Models\StockBalance;
use App\Models\StockMovement;
use App\Models\Supplier;
use App\Models\User;
use App\Models\Warehouse;
use App\Models\Asset;
use App\Models\AssetCategory;
use App\Models\AssetLocation;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Throwable;

class SyncInventoryDataWarehouse extends Command
{
    protected $signature = 'dw:sync-inventory';

    protected $description = 'Sync operational inventory data into data warehouse tables.';

    public function handle(): int
    {
        $this->info('Starting inventory data warehouse sync...');

        try {
            DB::transaction(function (): void {
                $this->syncDimensions();
                $this->syncFacts();
            });

            $this->info('Inventory data warehouse sync completed successfully.');

            return self::SUCCESS;
        } catch (Throwable $e) {
            $this->error('Sync failed: ' . $e->getMessage());

            report($e);

            return self::FAILURE;
        }
    }

    private function syncDimensions(): void
    {
        $this->info('Syncing dimensions...');

        $this->syncDimProducts();
        $this->syncDimWarehouses();
        $this->syncDimSuppliers();
        $this->syncDimCustomers();
        $this->syncDimUsers();
        $this->syncDimAssetCategories();
        $this->syncDimAssetLocations();
        $this->syncDimAssets();
    }

    private function syncFacts(): void
    {
        $this->info('Syncing facts...');

        $this->syncFactInventoryMovements();
        $this->syncFactInboundTransactions();
        $this->syncFactOutboundTransactions();
        $this->syncFactStockSnapshots();
        $this->syncFactAssetSnapshots();
    }

    private function syncDimProducts(): void
    {
        Product::query()
            ->with(['productType', 'productDensity', 'productCategory', 'unit'])
            ->chunkById(200, function ($products): void {
                foreach ($products as $product) {
                    DB::table('dw_dim_products')->updateOrInsert(
                        ['source_product_id' => $product->id],
                        [
                            'code' => $product->code,
                            'name' => $product->name,
                            'full_name' => $product->full_name,
                            'type_name' => $product->productType?->name,
                            'density_name' => $product->productDensity?->name,
                            'category_name' => $product->productCategory?->name,
                            'unit_name' => $product->unit?->name,
                            'default_purchase_price' => (float) ($product->default_purchase_price ?? 0),
                            'default_selling_price' => (float) ($product->default_selling_price ?? 0),
                            'is_active' => (bool) ($product->is_active ?? true),
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]
                    );
                }
            });
    }

    private function syncDimWarehouses(): void
    {
        Warehouse::query()
            ->chunkById(200, function ($warehouses): void {
                foreach ($warehouses as $warehouse) {
                    DB::table('dw_dim_warehouses')->updateOrInsert(
                        ['source_warehouse_id' => $warehouse->id],
                        [
                            'code' => $warehouse->code,
                            'name' => $warehouse->name,
                            'address' => $warehouse->address,
                            'phone' => $warehouse->phone,
                            'is_active' => (bool) ($warehouse->is_active ?? true),
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]
                    );
                }
            });
    }

    private function syncDimSuppliers(): void
    {
        Supplier::query()
            ->chunkById(200, function ($suppliers): void {
                foreach ($suppliers as $supplier) {
                    DB::table('dw_dim_suppliers')->updateOrInsert(
                        ['source_supplier_id' => $supplier->id],
                        [
                            'code' => $supplier->code,
                            'name' => $supplier->name,
                            'phone' => $supplier->phone,
                            'address' => $supplier->address,
                            'is_active' => (bool) ($supplier->is_active ?? true),
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]
                    );
                }
            });
    }

    private function syncDimCustomers(): void
    {
        Customer::query()
            ->chunkById(200, function ($customers): void {
                foreach ($customers as $customer) {
                    DB::table('dw_dim_customers')->updateOrInsert(
                        ['source_customer_id' => $customer->id],
                        [
                            'code' => $customer->code,
                            'name' => $customer->name,
                            'phone' => $customer->phone,
                            'address' => $customer->address,
                            'customer_type' => $customer->customer_type,
                            'is_active' => (bool) ($customer->is_active ?? true),
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]
                    );
                }
            });
    }

    private function syncDimUsers(): void
    {
        User::query()
            ->with(['profile.warehouse'])
            ->chunkById(200, function ($users): void {
                foreach ($users as $user) {
                    DB::table('dw_dim_users')->updateOrInsert(
                        ['source_user_id' => $user->id],
                        [
                            'name' => $user->name,
                            'email' => $user->email,
                            'username' => $user->profile?->username,
                            'employee_code' => $user->profile?->employee_code,
                            'position' => $user->profile?->position,
                            'warehouse_name' => $user->profile?->warehouse?->name,
                            'is_active' => (bool) ($user->profile?->is_active ?? true),
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]
                    );
                }
            });
    }

    private function syncFactInventoryMovements(): void
    {
        StockMovement::query()
            ->chunkById(200, function ($movements): void {
                foreach ($movements as $movement) {
                    $date = $movement->created_at ?? now();
                    $dateKey = $this->ensureDateDimension($date);

                    $productDimId = $this->getProductDimId((int) $movement->product_id);
                    $warehouseDimId = $this->getWarehouseDimId((int) $movement->warehouse_id);

                    if (! $productDimId || ! $warehouseDimId) {
                        continue;
                    }

                    $movementType = strtoupper((string) $movement->movement_type);

                    $qty = (float) (
                        $movement->qty
                        ?? $movement->quantity
                        ?? $movement->qty_in
                        ?? $movement->qty_out
                        ?? 0
                    );

                    $qtyIn = (float) ($movement->qty_in ?? 0);
                    $qtyOut = (float) ($movement->qty_out ?? 0);

                    if ($qtyIn <= 0 && $qtyOut <= 0) {
                        if (in_array($movementType, ['IN', 'MASUK', 'INBOUND'], true)) {
                            $qtyIn = $qty;
                        }

                        if (in_array($movementType, ['OUT', 'KELUAR', 'OUTBOUND'], true)) {
                            $qtyOut = $qty;
                        }
                    }

                    $userId = $movement->created_by
                        ?? $movement->user_id
                        ?? $movement->submitted_by
                        ?? null;

                    $userDimId = $userId ? $this->getUserDimId((int) $userId) : null;

                    DB::table('dw_fact_inventory_movements')->updateOrInsert(
                        ['source_stock_movement_id' => $movement->id],
                        [
                            'movement_number' => $movement->movement_number ?? null,
                            'movement_type' => $movement->movement_type,

                            'date_key' => $dateKey,
                            'product_dim_id' => $productDimId,
                            'warehouse_dim_id' => $warehouseDimId,
                            'user_dim_id' => $userDimId,

                            'qty_in' => $qtyIn,
                            'qty_out' => $qtyOut,
                            'stock_before' => (float) ($movement->stock_before ?? 0),
                            'stock_after' => (float) ($movement->stock_after ?? 0),

                            'reference_type' => $movement->reference_type ?? null,
                            'reference_id' => $movement->reference_id ?? null,
                            'description' => $movement->description ?? $movement->note ?? null,

                            'movement_created_at' => $movement->created_at,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]
                    );
                }
            });
    }

    private function syncFactInboundTransactions(): void
    {
        InboundTransaction::query()
            ->with(['items'])
            ->chunkById(100, function ($transactions): void {
                foreach ($transactions as $transaction) {
                    $date = $transaction->transaction_date ?? $transaction->created_at ?? now();
                    $dateKey = $this->ensureDateDimension($date);

                    $warehouseDimId = $this->getWarehouseDimId((int) $transaction->warehouse_id);
                    $supplierDimId = $transaction->supplier_id
                        ? $this->getSupplierDimId((int) $transaction->supplier_id)
                        : null;

                    $submittedUserDimId = $transaction->submitted_by
                        ? $this->getUserDimId((int) $transaction->submitted_by)
                        : null;

                    $approvedUserDimId = $transaction->approved_by
                        ? $this->getUserDimId((int) $transaction->approved_by)
                        : null;

                    if (! $warehouseDimId) {
                        continue;
                    }

                    DB::table('dw_fact_inbound_transactions')->updateOrInsert(
                        ['source_inbound_id' => $transaction->id],
                        [
                            'transaction_number' => $transaction->transaction_number,
                            'invoice_number' => $transaction->invoice_number,

                            'date_key' => $dateKey,
                            'warehouse_dim_id' => $warehouseDimId,
                            'supplier_dim_id' => $supplierDimId,
                            'submitted_user_dim_id' => $submittedUserDimId,
                            'approved_user_dim_id' => $approvedUserDimId,

                            'total_items' => $transaction->items->count(),
                            'total_qty' => (float) $transaction->items->sum('qty'),
                            'sub_total' => (float) ($transaction->sub_total ?? 0),
                            'discount_amount' => (float) ($transaction->discount_amount ?? 0),
                            'other_cost' => (float) ($transaction->other_cost ?? 0),
                            'grand_total' => (float) ($transaction->grand_total ?? 0),

                            'status' => $transaction->status,
                            'source' => $transaction->source,

                            'submitted_at' => $transaction->submitted_at,
                            'approved_at' => $transaction->approved_at,
                            'transaction_created_at' => $transaction->created_at,

                            'created_at' => now(),
                            'updated_at' => now(),
                        ]
                    );
                }
            });
    }

    private function syncFactOutboundTransactions(): void
    {
        OutboundTransaction::query()
            ->with(['items'])
            ->chunkById(100, function ($transactions): void {
                foreach ($transactions as $transaction) {
                    $date = $transaction->transaction_date ?? $transaction->created_at ?? now();
                    $dateKey = $this->ensureDateDimension($date);

                    $warehouseDimId = $this->getWarehouseDimId((int) $transaction->warehouse_id);
                    $customerDimId = $transaction->customer_id
                        ? $this->getCustomerDimId((int) $transaction->customer_id)
                        : null;

                    $submittedUserDimId = $transaction->submitted_by
                        ? $this->getUserDimId((int) $transaction->submitted_by)
                        : null;

                    $approvedUserDimId = $transaction->approved_by
                        ? $this->getUserDimId((int) $transaction->approved_by)
                        : null;

                    if (! $warehouseDimId) {
                        continue;
                    }

                    DB::table('dw_fact_outbound_transactions')->updateOrInsert(
                        ['source_outbound_id' => $transaction->id],
                        [
                            'transaction_number' => $transaction->transaction_number,
                            'reference_number' => $transaction->reference_number,
                            'outbound_type' => $transaction->outbound_type,

                            'date_key' => $dateKey,
                            'warehouse_dim_id' => $warehouseDimId,
                            'customer_dim_id' => $customerDimId,
                            'submitted_user_dim_id' => $submittedUserDimId,
                            'approved_user_dim_id' => $approvedUserDimId,

                            'total_items' => $transaction->items->count(),
                            'total_qty' => (float) $transaction->items->sum('qty'),
                            'sub_total' => (float) ($transaction->sub_total ?? 0),
                            'discount_amount' => (float) ($transaction->discount_amount ?? 0),
                            'vat_amount' => (float) ($transaction->vat_amount ?? 0),
                            'other_cost' => (float) ($transaction->other_cost ?? 0),
                            'grand_total' => (float) ($transaction->grand_total ?? 0),
                            'paid_amount' => (float) ($transaction->paid_amount ?? 0),
                            'remaining_amount' => (float) ($transaction->remaining_amount ?? 0),

                            'status' => $transaction->status,
                            'source' => $transaction->source,

                            'submitted_at' => $transaction->submitted_at,
                            'approved_at' => $transaction->approved_at,
                            'transaction_created_at' => $transaction->created_at,

                            'created_at' => now(),
                            'updated_at' => now(),
                        ]
                    );
                }
            });
    }

    private function syncFactStockSnapshots(): void
    {
        $snapshotDate = now();
        $dateKey = $this->ensureDateDimension($snapshotDate);

        StockBalance::query()
            ->chunkById(200, function ($balances) use ($dateKey, $snapshotDate): void {
                foreach ($balances as $balance) {
                    $productDimId = $this->getProductDimId((int) $balance->product_id);
                    $warehouseDimId = $this->getWarehouseDimId((int) $balance->warehouse_id);

                    if (! $productDimId || ! $warehouseDimId) {
                        continue;
                    }

                    $qtyOnHand = (float) ($balance->qty_on_hand ?? 0);
                    $qtyReserved = (float) ($balance->qty_reserved ?? 0);
                    $minimumStock = (float) ($balance->minimum_stock ?? 0);
                    $qtyAvailable = $qtyOnHand - $qtyReserved;

                    $stockStatus = match (true) {
                        $qtyAvailable <= 0 => 'habis',
                        $qtyAvailable <= $minimumStock => 'menipis',
                        default => 'aman',
                    };

                    DB::table('dw_fact_stock_snapshots')->updateOrInsert(
                        [
                            'date_key' => $dateKey,
                            'product_dim_id' => $productDimId,
                            'warehouse_dim_id' => $warehouseDimId,
                        ],
                        [
                            'qty_on_hand' => $qtyOnHand,
                            'qty_reserved' => $qtyReserved,
                            'qty_available' => $qtyAvailable,
                            'minimum_stock' => $minimumStock,
                            'stock_status' => $stockStatus,
                            'snapshot_at' => $snapshotDate,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]
                    );
                }
            });
    }

    private function syncDimAssetCategories(): void
{
    AssetCategory::query()
        ->chunkById(200, function ($categories): void {
            foreach ($categories as $category) {
                DB::table('dw_dim_asset_categories')->updateOrInsert(
                    [
                        'source_asset_category_id' => $category->id,
                    ],
                    [
                        'code' => $category->code,
                        'name' => $category->name,
                        'is_active' => (bool) ($category->is_active ?? true),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                );
            }
        });
}

private function syncDimAssetLocations(): void
{
    AssetLocation::query()
        ->chunkById(200, function ($locations): void {
            foreach ($locations as $location) {
                DB::table('dw_dim_asset_locations')->updateOrInsert(
                    [
                        'source_asset_location_id' => $location->id,
                    ],
                    [
                        'code' => $location->code,
                        'name' => $location->name,
                        'address' => $location->address,
                        'is_active' => (bool) ($location->is_active ?? true),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                );
            }
        });
}

private function syncDimAssets(): void
{
    Asset::query()
        ->with(['category', 'location'])
        ->chunkById(200, function ($assets): void {
            foreach ($assets as $asset) {
                $categoryDimId = $asset->asset_category_id
                    ? $this->getAssetCategoryDimId((int) $asset->asset_category_id)
                    : null;

                $locationDimId = $asset->asset_location_id
                    ? $this->getAssetLocationDimId((int) $asset->asset_location_id)
                    : null;

                DB::table('dw_dim_assets')->updateOrInsert(
                    [
                        'source_asset_id' => $asset->id,
                    ],
                    [
                        'asset_category_dim_id' => $categoryDimId,
                        'asset_location_dim_id' => $locationDimId,

                        'asset_code' => $asset->asset_code,
                        'name' => $asset->name,
                        'license_plate' => $asset->license_plate,

                        'brand' => $asset->brand,
                        'model' => $asset->model,
                        'serial_number' => $asset->serial_number,

                        'acquisition_year' => $asset->acquisition_year,
                        'acquisition_date' => $asset->acquisition_date,
                        'acquisition_price' => (float) ($asset->acquisition_price ?? 0),

                        'condition' => $asset->condition,
                        'status' => $asset->status,

                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                );
            }
        });
}

private function syncFactAssetSnapshots(): void
{
    $snapshotDate = now();
    $dateKey = $this->ensureDateDimension($snapshotDate);

    Asset::query()
        ->chunkById(200, function ($assets) use ($dateKey, $snapshotDate): void {
            foreach ($assets as $asset) {
                $assetDimId = $this->getAssetDimId((int) $asset->id);

                if (! $assetDimId) {
                    continue;
                }

                $categoryDimId = $asset->asset_category_id
                    ? $this->getAssetCategoryDimId((int) $asset->asset_category_id)
                    : null;

                $locationDimId = $asset->asset_location_id
                    ? $this->getAssetLocationDimId((int) $asset->asset_location_id)
                    : null;

                DB::table('dw_fact_asset_snapshots')->updateOrInsert(
                    [
                        'date_key' => $dateKey,
                        'asset_dim_id' => $assetDimId,
                    ],
                    [
                        'asset_category_dim_id' => $categoryDimId,
                        'asset_location_dim_id' => $locationDimId,

                        'acquisition_price' => (float) ($asset->acquisition_price ?? 0),
                        'condition' => $asset->condition,
                        'status' => $asset->status,
                        'is_active' => $asset->status !== 'tidak_aktif',

                        'snapshot_at' => $snapshotDate,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                );
            }
        });
}

    private function ensureDateDimension($date): int
    {
        $carbon = Carbon::parse($date)->startOfDay();
        $dateKey = (int) $carbon->format('Ymd');

        DB::table('dw_dim_dates')->updateOrInsert(
            ['date_key' => $dateKey],
            [
                'full_date' => $carbon->toDateString(),
                'day' => (int) $carbon->format('d'),
                'month' => (int) $carbon->format('m'),
                'month_name' => $carbon->translatedFormat('F'),
                'quarter' => (int) ceil(((int) $carbon->format('m')) / 3),
                'year' => (int) $carbon->format('Y'),
                'day_name' => $carbon->translatedFormat('l'),
                'is_weekend' => $carbon->isWeekend(),
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        return $dateKey;
    }

    private function getAssetCategoryDimId(?int $sourceId): ?int
    {
        return $sourceId
            ? DB::table('dw_dim_asset_categories')->where('source_asset_category_id', $sourceId)->value('id')
            : null;
    }

    private function getAssetLocationDimId(?int $sourceId): ?int
    {
        return $sourceId
            ? DB::table('dw_dim_asset_locations')->where('source_asset_location_id', $sourceId)->value('id')
            : null;
    }

    private function getAssetDimId(?int $sourceId): ?int
    {
        return $sourceId
            ? DB::table('dw_dim_assets')->where('source_asset_id', $sourceId)->value('id')
            : null;
    }

    private function getProductDimId(?int $sourceId): ?int
    {
        return $sourceId
            ? DB::table('dw_dim_products')->where('source_product_id', $sourceId)->value('id')
            : null;
    }

    private function getWarehouseDimId(?int $sourceId): ?int
    {
        return $sourceId
            ? DB::table('dw_dim_warehouses')->where('source_warehouse_id', $sourceId)->value('id')
            : null;
    }

    private function getSupplierDimId(?int $sourceId): ?int
    {
        return $sourceId
            ? DB::table('dw_dim_suppliers')->where('source_supplier_id', $sourceId)->value('id')
            : null;
    }

    private function getCustomerDimId(?int $sourceId): ?int
    {
        return $sourceId
            ? DB::table('dw_dim_customers')->where('source_customer_id', $sourceId)->value('id')
            : null;
    }

    private function getUserDimId(?int $sourceId): ?int
    {
        return $sourceId
            ? DB::table('dw_dim_users')->where('source_user_id', $sourceId)->value('id')
            : null;
    }
}