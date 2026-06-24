<?php

namespace App\Filament\Admin\Widgets;

use Carbon\Carbon;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

class DataWarehouseOverviewWidget extends StatsOverviewWidget
{
    protected ?string $heading = 'Ringkasan Kinerja Persediaan';

    protected static ?int $sort = 1;

    public string $period = 'all';

    public ?string $startDate = null;

    public ?string $endDate = null;

    public string|int|null $warehouseId = null;

    public static function canView(): bool
    {
        return request()->is('admin/data-warehouse-dashboard*');
    }

    protected function getStats(): array
    {
        $warehouseId = $this->selectedWarehouseId();
        $periodLabel = $this->periodLabel();

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

        return [
            Stat::make('Produk Terdaftar', number_format($totalProducts, 0, ',', '.'))
                ->description('Total produk yang tersedia pada data warehouse')
                ->descriptionIcon('heroicon-m-cube')
                ->color('primary'),

            Stat::make('Gudang Terdaftar', number_format($totalWarehouses, 0, ',', '.'))
                ->description('Total gudang yang tersedia pada data warehouse')
                ->descriptionIcon('heroicon-m-building-storefront')
                ->color('info'),

            Stat::make('Transaksi Barang Masuk', number_format($totalInbound, 0, ',', '.'))
                ->description("Jumlah transaksi penerimaan barang {$periodLabel}")
                ->descriptionIcon('heroicon-m-arrow-down-tray')
                ->color('success'),

            Stat::make('Transaksi Barang Keluar', number_format($totalOutbound, 0, ',', '.'))
                ->description("Jumlah transaksi pengeluaran barang {$periodLabel}")
                ->descriptionIcon('heroicon-m-arrow-up-tray')
                ->color('warning'),

            Stat::make('Nilai Barang Masuk Disetujui', 'Rp ' . number_format((float) $totalInboundValue, 0, ',', '.'))
                ->description("Total nilai penerimaan barang yang telah disetujui {$periodLabel}")
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('success'),

            Stat::make('Nilai Barang Keluar Disetujui', 'Rp ' . number_format((float) $totalOutboundValue, 0, ',', '.'))
                ->description("Total nilai pengeluaran barang yang telah disetujui {$periodLabel}")
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('danger'),

            Stat::make('Kuantitas Barang Masuk', number_format((float) $totalMovementIn, 0, ',', '.'))
                ->description("Akumulasi kuantitas barang masuk {$periodLabel}")
                ->descriptionIcon('heroicon-m-plus-circle')
                ->color('success'),

            Stat::make('Kuantitas Barang Keluar', number_format((float) $totalMovementOut, 0, ',', '.'))
                ->description("Akumulasi kuantitas barang keluar {$periodLabel}")
                ->descriptionIcon('heroicon-m-minus-circle')
                ->color('danger'),

            Stat::make('Stok Aman', number_format($stockAman, 0, ',', '.'))
                ->description('Jumlah item dengan kondisi stok aman')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('success'),

            Stat::make('Stok Perlu Perhatian', number_format($stockMenipis, 0, ',', '.'))
                ->description('Jumlah item dengan stok mendekati batas minimum')
                ->descriptionIcon('heroicon-m-exclamation-triangle')
                ->color('warning'),

            Stat::make('Stok Habis', number_format($stockHabis, 0, ',', '.'))
                ->description('Jumlah item tanpa stok tersedia')
                ->descriptionIcon('heroicon-m-x-circle')
                ->color('danger'),
        ];
    }

    private function applyFactFilters(Builder $query, ?int $warehouseId = null): Builder
    {
        $dateRange = $this->dateKeyRange();

        if ($dateRange !== null) {
            if (! empty($dateRange['start']) && ! empty($dateRange['end'])) {
                $query->whereBetween('date_key', [
                    $dateRange['start'],
                    $dateRange['end'],
                ]);
            } elseif (! empty($dateRange['start'])) {
                $query->where('date_key', '>=', $dateRange['start']);
            } elseif (! empty($dateRange['end'])) {
                $query->where('date_key', '<=', $dateRange['end']);
            }
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
            if (! empty($dateRange['start']) && ! empty($dateRange['end'])) {
                $baseQuery->whereBetween('date_key', [
                    $dateRange['start'],
                    $dateRange['end'],
                ]);
            } elseif (! empty($dateRange['start'])) {
                $baseQuery->where('date_key', '>=', $dateRange['start']);
            } elseif (! empty($dateRange['end'])) {
                $baseQuery->where('date_key', '<=', $dateRange['end']);
            }
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
        if ($this->startDate || $this->endDate) {
            return [
                'start' => $this->startDate
                    ? (int) Carbon::parse($this->startDate)->format('Ymd')
                    : null,
                'end' => $this->endDate
                    ? (int) Carbon::parse($this->endDate)->format('Ymd')
                    : null,
            ];
        }

        if ($this->period === 'all') {
            return null;
        }

        $now = now();

        if (str_starts_with($this->period, 'year_')) {
            $year = (int) str_replace('year_', '', $this->period);

            return [
                'start' => (int) Carbon::create($year, 1, 1)->startOfYear()->format('Ymd'),
                'end' => (int) Carbon::create($year, 12, 31)->endOfYear()->format('Ymd'),
            ];
        }

        [$start, $end] = match ($this->period) {
            'day' => [
                $now->copy()->startOfDay(),
                $now->copy()->endOfDay(),
            ],
            'week' => [
                $now->copy()->startOfWeek(),
                $now->copy()->endOfWeek(),
            ],
            'month' => [
                $now->copy()->startOfMonth(),
                $now->copy()->endOfMonth(),
            ],
            'year' => [
                $now->copy()->startOfYear(),
                $now->copy()->endOfYear(),
            ],
            default => [
                null,
                null,
            ],
        };

        if (! $start || ! $end) {
            return null;
        }

        return [
            'start' => (int) Carbon::parse($start)->format('Ymd'),
            'end' => (int) Carbon::parse($end)->format('Ymd'),
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
        if ($this->startDate && $this->endDate) {
            return 'periode ' .
                Carbon::parse($this->startDate)->format('d M Y') .
                ' sampai ' .
                Carbon::parse($this->endDate)->format('d M Y');
        }

        if ($this->startDate) {
            return 'mulai ' . Carbon::parse($this->startDate)->format('d M Y');
        }

        if ($this->endDate) {
            return 'sampai ' . Carbon::parse($this->endDate)->format('d M Y');
        }

        if (str_starts_with($this->period, 'year_')) {
            return 'tahun ' . str_replace('year_', '', $this->period);
        }

        return match ($this->period) {
            'day' => 'hari ini',
            'week' => 'minggu ini',
            'month' => 'bulan ini',
            'year' => 'tahun ini',
            'all' => 'pada seluruh periode',
            default => 'pada seluruh periode',
        };
    }
}