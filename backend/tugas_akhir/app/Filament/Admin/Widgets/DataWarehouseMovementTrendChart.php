<?php

namespace App\Filament\Admin\Widgets;

use Carbon\Carbon;
use Filament\Widgets\ChartWidget;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DataWarehouseMovementTrendChart extends ChartWidget
{
    protected ?string $heading = 'Tren Qty Barang Masuk dan Keluar per Bulan';

    protected static ?int $sort = 3;

    public string $period = 'all';

    public ?string $startDate = null;

    public ?string $endDate = null;

    public string|int|null $warehouseId = null;

    public string|int|null $chartYear = '';

    public string|int|null $productId = '';

    public ?string $productCategory = '';

    public static function canView(): bool
    {
        return request()->is('admin/data-warehouse-dashboard*');
    }

    protected function getData(): array
    {
        if (! Schema::hasTable('dw_fact_inventory_movements')) {
            return [
                'datasets' => [],
                'labels' => [],
            ];
        }

        $query = DB::table('dw_fact_inventory_movements as movement')
            ->selectRaw("
                DATE_FORMAT(STR_TO_DATE(CAST(movement.date_key AS CHAR), '%Y%m%d'), '%Y-%m') as month_key,
                COALESCE(SUM(movement.qty_in), 0) as total_in,
                COALESCE(SUM(movement.qty_out), 0) as total_out
            ")
            ->groupBy('month_key')
            ->orderBy('month_key');

        $this->applyFilters($query);

        $rows = $query->get();

        return [
            'datasets' => [
                [
                    'label' => 'Qty Barang Masuk',
                    'data' => $rows->pluck('total_in')
                        ->map(fn ($value) => (float) $value)
                        ->toArray(),
                    'borderColor' => '#16a34a',
                    'backgroundColor' => 'rgba(22, 163, 74, 0.18)',
                    'tension' => 0.35,
                    'fill' => true,
                ],
                [
                    'label' => 'Qty Barang Keluar',
                    'data' => $rows->pluck('total_out')
                        ->map(fn ($value) => (float) $value)
                        ->toArray(),
                    'borderColor' => '#dc2626',
                    'backgroundColor' => 'rgba(220, 38, 38, 0.14)',
                    'tension' => 0.35,
                    'fill' => true,
                ],
            ],
            'labels' => $rows->pluck('month_key')
                ->map(fn ($month) => Carbon::createFromFormat('Y-m', $month)->translatedFormat('M Y'))
                ->toArray(),
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }

    private function applyFilters(Builder $query): void
    {
        $dateRange = $this->dateKeyRange();

        if ($dateRange !== null) {
            if (! empty($dateRange['start']) && ! empty($dateRange['end'])) {
                $query->whereBetween('movement.date_key', [
                    $dateRange['start'],
                    $dateRange['end'],
                ]);
            } elseif (! empty($dateRange['start'])) {
                $query->where('movement.date_key', '>=', $dateRange['start']);
            } elseif (! empty($dateRange['end'])) {
                $query->where('movement.date_key', '<=', $dateRange['end']);
            }
        }

        $warehouseId = $this->selectedWarehouseId();

        if ($warehouseId !== null && Schema::hasColumn('dw_fact_inventory_movements', 'warehouse_dim_id')) {
            $query->where('movement.warehouse_dim_id', $warehouseId);
        }

        $productId = $this->selectedProductId();

        if ($productId !== null && Schema::hasColumn('dw_fact_inventory_movements', 'product_dim_id')) {
            $query->where('movement.product_dim_id', $productId);
        }

        if (
            $this->productCategory !== null &&
            $this->productCategory !== '' &&
            Schema::hasTable('dw_dim_products') &&
            Schema::hasColumn('dw_fact_inventory_movements', 'product_dim_id')
        ) {
            $categoryColumn = $this->productCategoryColumn();

            if ($categoryColumn) {
                $query->join('dw_dim_products as product_filter', 'product_filter.id', '=', 'movement.product_dim_id')
                    ->where('product_filter.' . $categoryColumn, $this->productCategory);
            }
        }
    }

    private function selectedWarehouseId(): ?int
    {
        if ($this->warehouseId === null || $this->warehouseId === '') {
            return null;
        }

        return (int) $this->warehouseId;
    }

    private function selectedProductId(): ?int
    {
        if ($this->productId === null || $this->productId === '') {
            return null;
        }

        return (int) $this->productId;
    }

    private function productCategoryColumn(): ?string
    {
        if (! Schema::hasTable('dw_dim_products')) {
            return null;
        }

        foreach (['category_name', 'category', 'product_category', 'group_name', 'type', 'brand'] as $column) {
            if (Schema::hasColumn('dw_dim_products', $column)) {
                return $column;
            }
        }

        return null;
    }

    private function dateKeyRange(): ?array
    {
        if ($this->chartYear !== null && $this->chartYear !== '') {
            $year = (int) $this->chartYear;

            return [
                'start' => (int) Carbon::create($year, 1, 1)->startOfYear()->format('Ymd'),
                'end' => (int) Carbon::create($year, 12, 31)->endOfYear()->format('Ymd'),
            ];
        }

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
            'day' => [$now->copy()->startOfDay(), $now->copy()->endOfDay()],
            'week' => [$now->copy()->startOfWeek(), $now->copy()->endOfWeek()],
            'month' => [$now->copy()->startOfMonth(), $now->copy()->endOfMonth()],
            'year' => [$now->copy()->startOfYear(), $now->copy()->endOfYear()],
            default => [null, null],
        };

        if (! $start || ! $end) {
            return null;
        }

        return [
            'start' => (int) $start->format('Ymd'),
            'end' => (int) $end->format('Ymd'),
        ];
    }
}