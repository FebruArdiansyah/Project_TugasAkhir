<?php

namespace App\Filament\Admin\Widgets;

use Carbon\Carbon;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

class DataWarehouseOverviewWidget extends StatsOverviewWidget
{
    protected ?string $heading = 'Ringkasan Data Warehouse';

    protected static ?int $sort = 1;

    public string $period = 'month';

    public string|int|null $warehouseId = null;

    public static function canView(): bool
    {
        return request()->is('admin/data-warehouse-dashboard*');
    }

    protected function getStats(): array
    {
        $warehouseId = $this->selectedWarehouseId();

        $totalProducts = DB::table('dw_dim_products')->count();

        $totalWarehouses = DB::table('dw_dim_warehouses')->count();

        $totalInbound = $this->applyFactFilters(
            DB::table('dw_fact_inbound_transactions'),
            $warehouseId
        )->count();

        $totalOutbound = $this->applyFactFilters(
            DB::table('dw_fact_outbound_transactions'),
            $warehouseId
        )->count();

        $totalInboundValue = $this->applyFactFilters(
            DB::table('dw_fact_inbound_transactions')->where('status', 'approved'),
            $warehouseId
        )->sum('grand_total');

        $totalOutboundValue = $this->applyFactFilters(
            DB::table('dw_fact_outbound_transactions')->where('status', 'approved'),
            $warehouseId
        )->sum('grand_total');

        $totalMovementIn = $this->applyFactFilters(
            DB::table('dw_fact_inventory_movements'),
            $warehouseId
        )->sum('qty_in');

        $totalMovementOut = $this->applyFactFilters(
            DB::table('dw_fact_inventory_movements'),
            $warehouseId
        )->sum('qty_out');

        $stockSnapshotQuery = $this->latestStockSnapshotQuery($warehouseId);

        $stockAman = (clone $stockSnapshotQuery)
            ->where('stock_status', 'aman')
            ->count();

        $stockMenipis = (clone $stockSnapshotQuery)
            ->where('stock_status', 'menipis')
            ->count();

        $stockHabis = (clone $stockSnapshotQuery)
            ->where('stock_status', 'habis')
            ->count();

        $periodLabel = $this->periodLabel();

        return [
            Stat::make('DW Produk', number_format($totalProducts, 0, ',', '.'))
                ->description('Total produk di dimensi DW')
                ->descriptionIcon('heroicon-m-cube')
                ->color('primary'),

            Stat::make('DW Gudang', number_format($totalWarehouses, 0, ',', '.'))
                ->description('Total gudang di dimensi DW')
                ->descriptionIcon('heroicon-m-building-storefront')
                ->color('info'),

            Stat::make('DW Barang Masuk', number_format($totalInbound, 0, ',', '.'))
                ->description("Fact inbound {$periodLabel}")
                ->descriptionIcon('heroicon-m-arrow-down-tray')
                ->color('success'),

            Stat::make('DW Barang Keluar', number_format($totalOutbound, 0, ',', '.'))
                ->description("Fact outbound {$periodLabel}")
                ->descriptionIcon('heroicon-m-arrow-up-tray')
                ->color('warning'),

            Stat::make('Nilai Inbound Approved', 'Rp ' . number_format((float) $totalInboundValue, 0, ',', '.'))
                ->description("Nilai masuk approved {$periodLabel}")
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('success'),

            Stat::make('Nilai Outbound Approved', 'Rp ' . number_format((float) $totalOutboundValue, 0, ',', '.'))
                ->description("Nilai keluar approved {$periodLabel}")
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('danger'),

            Stat::make('Total Qty Masuk', number_format((float) $totalMovementIn, 0, ',', '.'))
                ->description("Akumulasi qty_in {$periodLabel}")
                ->descriptionIcon('heroicon-m-plus-circle')
                ->color('success'),

            Stat::make('Total Qty Keluar', number_format((float) $totalMovementOut, 0, ',', '.'))
                ->description("Akumulasi qty_out {$periodLabel}")
                ->descriptionIcon('heroicon-m-minus-circle')
                ->color('danger'),

            Stat::make('Snapshot Aman', number_format($stockAman, 0, ',', '.'))
                ->description('Snapshot stok terakhir sesuai filter')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('success'),

            Stat::make('Snapshot Menipis', number_format($stockMenipis, 0, ',', '.'))
                ->description('Snapshot stok terakhir sesuai filter')
                ->descriptionIcon('heroicon-m-exclamation-triangle')
                ->color('warning'),

            Stat::make('Snapshot Habis', number_format($stockHabis, 0, ',', '.'))
                ->description('Snapshot stok terakhir sesuai filter')
                ->descriptionIcon('heroicon-m-x-circle')
                ->color('danger'),
        ];
    }

    private function applyFactFilters(Builder $query, ?int $warehouseId = null): Builder
    {
        $dateRange = $this->dateKeyRange();

        if ($dateRange !== null) {
            $query->whereBetween('date_key', $dateRange);
        }

        if ($warehouseId !== null) {
            $query->where('warehouse_dim_id', $warehouseId);
        }

        return $query;
    }

    private function latestStockSnapshotQuery(?int $warehouseId = null): Builder
    {
        $baseQuery = DB::table('dw_fact_stock_snapshots');

        $dateRange = $this->dateKeyRange();

        if ($dateRange !== null) {
            $baseQuery->whereBetween('date_key', $dateRange);
        }

        if ($warehouseId !== null) {
            $baseQuery->where('warehouse_dim_id', $warehouseId);
        }

        $latestDateKey = (clone $baseQuery)->max('date_key');

        $query = DB::table('dw_fact_stock_snapshots');

        if (! $latestDateKey) {
            return $query->whereRaw('1 = 0');
        }

        $query->where('date_key', $latestDateKey);

        if ($warehouseId !== null) {
            $query->where('warehouse_dim_id', $warehouseId);
        }

        return $query;
    }

    private function dateKeyRange(): ?array
{
    if ($this->period === 'all') {
        return null;
    }

    $now = now();

    [$start, $end] = match ($this->period) {
        'day' => [
            $now->copy()->startOfDay(),
            $now->copy()->endOfDay(),
        ],
        'week' => [
            $now->copy()->startOfWeek(),
            $now->copy()->endOfWeek(),
        ],
        'year' => [
            $now->copy()->startOfYear(),
            $now->copy()->endOfYear(),
        ],
        default => [
            $now->copy()->startOfMonth(),
            $now->copy()->endOfMonth(),
        ],
    };

    return [
        (int) Carbon::parse($start)->format('Ymd'),
        (int) Carbon::parse($end)->format('Ymd'),
    ];
}

    private function selectedWarehouseId(): ?int
    {
        if ($this->warehouseId === null || $this->warehouseId === '') {
            return null;
        }

        return (int) $this->warehouseId;
    }

    private function periodLabel(): string
    {
        return match ($this->period) {
            'day' => 'hari ini',
            'week' => 'minggu ini',
            'month' => 'bulan ini',
            'all' => 'semua data',
            default => 'bulan ini',
        };
    }
}