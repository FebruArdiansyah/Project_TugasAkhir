<?php

namespace App\Filament\Admin\Widgets;

use Carbon\Carbon;
use Filament\Widgets\ChartWidget;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DataWarehouseTopProductMovementChart extends ChartWidget
{
    protected ?string $heading = 'Top Produk Berdasarkan Qty Keluar';

    protected static ?int $sort = 4;

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

        $productLabelColumn = $this->productLabelColumn();

        $query = DB::table('dw_fact_inventory_movements as movement')
            ->where('movement.qty_out', '>', 0);

        $hasProductDimension = Schema::hasTable('dw_dim_products')
            && Schema::hasColumn('dw_fact_inventory_movements', 'product_dim_id');

        if ($hasProductDimension) {
            $query->leftJoin('dw_dim_products as product', 'product.id', '=', 'movement.product_dim_id');

            if ($productLabelColumn) {
                $query->selectRaw("COALESCE(product.{$productLabelColumn}, 'Produk Tidak Diketahui') as product_name");
            } else {
                $query->selectRaw("CONCAT('Produk #', movement.product_dim_id) as product_name");
            }
        } else {
            $query->selectRaw("CONCAT('Produk #', movement.product_dim_id) as product_name");
        }

        $query->selectRaw('COALESCE(SUM(movement.qty_out), 0) as total_qty_out')
            ->groupBy('product_name')
            ->orderByDesc('total_qty_out')
            ->limit(10);

        $this->applyFilters($query, $hasProductDimension);

        $rows = $query->get();

        return [
            'datasets' => [
                [
                    'label' => 'Qty Keluar',
                    'data' => $rows->pluck('total_qty_out')
                        ->map(fn ($value) => (float) $value)
                        ->toArray(),
                    'backgroundColor' => '#ef4444',
                    'borderColor' => '#dc2626',
                    'borderWidth' => 1,
                    'borderRadius' => 8,
                ],
            ],
            'labels' => $rows->pluck('product_name')
                ->map(fn ($name) => $this->shortProductName((string) $name))
                ->toArray(),
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }

    protected function getOptions(): array
    {
        return [
            'indexAxis' => 'y',
            'responsive' => true,
            'maintainAspectRatio' => false,
            'plugins' => [
                'legend' => [
                    'display' => false,
                ],
                'tooltip' => [
                    'enabled' => true,
                ],
            ],
            'scales' => [
                'x' => [
                    'beginAtZero' => true,
                    'ticks' => [
                        'precision' => 0,
                    ],
                    'title' => [
                        'display' => true,
                        'text' => 'Qty Keluar',
                    ],
                ],
                'y' => [
                    'ticks' => [
                        'autoSkip' => false,
                        'font' => [
                            'size' => 11,
                        ],
                    ],
                ],
            ],
        ];
    }

    private function shortProductName(string $name): string
    {
        $name = trim(preg_replace('/\s+/', ' ', $name));

        $name = str_replace([
            'INOAC ',
            'QUANTUM ',
            'KASUR ',
            'STANDAR ',
        ], '', $name);

        return str($name)->limit(42)->toString();
    }

    private function productLabelColumn(): ?string
    {
        if (! Schema::hasTable('dw_dim_products')) {
            return null;
        }

        foreach (['name', 'product_name', 'full_name', 'product_code', 'code', 'sku'] as $column) {
            if (Schema::hasColumn('dw_dim_products', $column)) {
                return $column;
            }
        }

        return null;
    }

    private function applyFilters(Builder $query, bool $hasProductDimension): void
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
            $hasProductDimension &&
            $this->productCategory !== null &&
            $this->productCategory !== ''
        ) {
            $categoryColumn = $this->productCategoryColumn();

            if ($categoryColumn) {
                $query->where('product.' . $categoryColumn, $this->productCategory);
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