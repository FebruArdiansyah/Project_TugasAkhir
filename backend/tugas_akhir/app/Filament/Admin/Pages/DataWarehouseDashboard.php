<?php

namespace App\Filament\Admin\Pages;

use BackedEnum;
use Carbon\Carbon;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Support\Enums\Width;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Throwable;

class DataWarehouseDashboard extends Page
{
    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-chart-bar-square';

    protected static string|\UnitEnum|null $navigationGroup = 'Data Warehouse';

    protected static ?string $navigationLabel = 'Analitik Persediaan';

    protected static ?string $title = 'Dashboard Analitik Persediaan';

    protected static ?int $navigationSort = 1;

    protected string $view = 'filament.admin.pages.data-warehouse-dashboard';

    protected Width|string|null $maxContentWidth = Width::Full;

    public string $period = 'all';

    public ?string $startDate = null;

    public ?string $endDate = null;

    public string $warehouseId = '';

    public string|int|null $chartYear = '';

    public string|int|null $productId = '';

    public ?string $productCategory = '';

    public function getWarehouses(): array
    {
        if (! Schema::hasTable('dw_dim_warehouses')) {
            return [];
        }

        return DB::table('dw_dim_warehouses')
            ->orderBy('name')
            ->pluck('name', 'id')
            ->toArray();
    }

    public function getProducts(): array
    {
        if (! Schema::hasTable('dw_dim_products')) {
            return [];
        }

        $nameColumn = $this->productNameColumn();

        if (! $nameColumn) {
            return DB::table('dw_dim_products')
                ->orderBy('id')
                ->limit(500)
                ->pluck('id', 'id')
                ->toArray();
        }

        return DB::table('dw_dim_products')
            ->select('id', $nameColumn)
            ->whereNotNull($nameColumn)
            ->orderBy($nameColumn)
            ->limit(500)
            ->pluck($nameColumn, 'id')
            ->toArray();
    }

    public function getProductCategories(): array
    {
        if (! Schema::hasTable('dw_dim_products')) {
            return [];
        }

        $categoryColumn = $this->productCategoryColumn();

        if (! $categoryColumn) {
            return [];
        }

        return DB::table('dw_dim_products')
            ->whereNotNull($categoryColumn)
            ->where($categoryColumn, '!=', '')
            ->select($categoryColumn)
            ->distinct()
            ->orderBy($categoryColumn)
            ->pluck($categoryColumn, $categoryColumn)
            ->toArray();
    }

    public function getPeriodOptions(): array
    {
        $options = [
            'all' => 'Seluruh Periode',
            'day' => 'Hari Ini',
            'week' => 'Minggu Ini',
            'month' => 'Bulan Ini',
            'year' => 'Tahun Ini',
        ];

        $years = collect();

        if (
            Schema::hasTable('dw_fact_inventory_movements') &&
            Schema::hasColumn('dw_fact_inventory_movements', 'date_key')
        ) {
            $years = $years->merge(
                DB::table('dw_fact_inventory_movements')
                    ->whereNotNull('date_key')
                    ->selectRaw('LEFT(CAST(date_key AS CHAR), 4) as year')
                    ->distinct()
                    ->pluck('year')
            );
        }

        if (
            Schema::hasTable('outbound_transactions') &&
            Schema::hasColumn('outbound_transactions', 'transaction_date')
        ) {
            $years = $years->merge(
                DB::table('outbound_transactions')
                    ->whereNotNull('transaction_date')
                    ->selectRaw('YEAR(transaction_date) as year')
                    ->distinct()
                    ->pluck('year')
            );
        }

        if (
            Schema::hasTable('inbound_transactions') &&
            Schema::hasColumn('inbound_transactions', 'transaction_date')
        ) {
            $years = $years->merge(
                DB::table('inbound_transactions')
                    ->whereNotNull('transaction_date')
                    ->selectRaw('YEAR(transaction_date) as year')
                    ->distinct()
                    ->pluck('year')
            );
        }

        $years = $years
            ->filter()
            ->map(fn ($year) => (int) $year)
            ->unique()
            ->sortDesc()
            ->values();

        foreach ($years as $year) {
            $options['year_' . $year] = 'Tahun ' . $year;
        }

        return $options;
    }

    public function getChartYearOptions(): array
    {
        $years = collect();

        if (
            Schema::hasTable('dw_fact_inventory_movements') &&
            Schema::hasColumn('dw_fact_inventory_movements', 'date_key')
        ) {
            $years = $years->merge(
                DB::table('dw_fact_inventory_movements')
                    ->whereNotNull('date_key')
                    ->selectRaw('LEFT(CAST(date_key AS CHAR), 4) as year')
                    ->distinct()
                    ->pluck('year')
            );
        }

        if (
            Schema::hasTable('inbound_transactions') &&
            Schema::hasColumn('inbound_transactions', 'transaction_date')
        ) {
            $years = $years->merge(
                DB::table('inbound_transactions')
                    ->whereNotNull('transaction_date')
                    ->selectRaw('YEAR(transaction_date) as year')
                    ->distinct()
                    ->pluck('year')
            );
        }

        if (
            Schema::hasTable('outbound_transactions') &&
            Schema::hasColumn('outbound_transactions', 'transaction_date')
        ) {
            $years = $years->merge(
                DB::table('outbound_transactions')
                    ->whereNotNull('transaction_date')
                    ->selectRaw('YEAR(transaction_date) as year')
                    ->distinct()
                    ->pluck('year')
            );
        }

        if ($years->isEmpty()) {
            $years = collect([now()->year]);
        }

        return $years
            ->filter()
            ->map(fn ($year) => (int) $year)
            ->unique()
            ->sortDesc()
            ->mapWithKeys(fn ($year) => [
                (string) $year => (string) $year,
            ])
            ->toArray();
    }

    public function getPeriodLabel(): string
    {
        if ($this->startDate && $this->endDate) {
            return Carbon::parse($this->startDate)->format('d M Y') . ' - ' . Carbon::parse($this->endDate)->format('d M Y');
        }

        if ($this->startDate) {
            return 'Mulai ' . Carbon::parse($this->startDate)->format('d M Y');
        }

        if ($this->endDate) {
            return 'Sampai ' . Carbon::parse($this->endDate)->format('d M Y');
        }

        if (str_starts_with($this->period, 'year_')) {
            return 'Tahun ' . str_replace('year_', '', $this->period);
        }

        return match ($this->period) {
            'day' => 'Hari Ini',
            'week' => 'Minggu Ini',
            'month' => 'Bulan Ini',
            'year' => 'Tahun Ini',
            'all' => 'Seluruh Periode',
            default => 'Seluruh Periode',
        };
    }

    public function getWarehouseLabel(): string
    {
        if (! $this->warehouseId) {
            return 'Seluruh Gudang';
        }

        if (! Schema::hasTable('dw_dim_warehouses')) {
            return 'Gudang Tidak Ditemukan';
        }

        return DB::table('dw_dim_warehouses')
            ->where('id', $this->warehouseId)
            ->value('name') ?? 'Gudang Tidak Ditemukan';
    }

    public function getProductLabel(): string
    {
        if (! $this->productId) {
            return 'Semua Produk';
        }

        if (! Schema::hasTable('dw_dim_products')) {
            return 'Produk Tidak Ditemukan';
        }

        $nameColumn = $this->productNameColumn();

        if (! $nameColumn) {
            return 'Produk #' . $this->productId;
        }

        return DB::table('dw_dim_products')
            ->where('id', $this->productId)
            ->value($nameColumn) ?? 'Produk Tidak Ditemukan';
    }

    public function getProductCategoryLabel(): string
    {
        return $this->productCategory ?: 'Semua Kategori';
    }

    public function getPeriodRange(): array
    {
        if ($this->startDate || $this->endDate) {
            return [
                'start' => $this->startDate,
                'end' => $this->endDate,
            ];
        }

        if ($this->period === 'all') {
            return [
                'start' => null,
                'end' => null,
            ];
        }

        if ($this->period === 'day') {
            return [
                'start' => now()->startOfDay()->toDateString(),
                'end' => now()->endOfDay()->toDateString(),
            ];
        }

        if ($this->period === 'week') {
            return [
                'start' => now()->startOfWeek()->toDateString(),
                'end' => now()->endOfWeek()->toDateString(),
            ];
        }

        if ($this->period === 'month') {
            return [
                'start' => now()->startOfMonth()->toDateString(),
                'end' => now()->endOfMonth()->toDateString(),
            ];
        }

        if ($this->period === 'year') {
            return [
                'start' => now()->startOfYear()->toDateString(),
                'end' => now()->endOfYear()->toDateString(),
            ];
        }

        if (str_starts_with($this->period, 'year_')) {
            $year = (int) str_replace('year_', '', $this->period);

            return [
                'start' => Carbon::create($year, 1, 1)->startOfYear()->toDateString(),
                'end' => Carbon::create($year, 12, 31)->endOfYear()->toDateString(),
            ];
        }

        return [
            'start' => null,
            'end' => null,
        ];
    }

    public function applyPeriodFilter(Builder $query, string $dateColumn): Builder
    {
        $range = $this->getPeriodRange();

        if ($range['start'] && $range['end']) {
            $query->whereBetween($dateColumn, [
                $range['start'],
                $range['end'],
            ]);

            return $query;
        }

        if ($range['start']) {
            $query->whereDate($dateColumn, '>=', $range['start']);
        }

        if ($range['end']) {
            $query->whereDate($dateColumn, '<=', $range['end']);
        }

        return $query;
    }

    public function applyWarehouseFilter(Builder $query, string $warehouseColumn = 'warehouse_id'): Builder
    {
        if ($this->warehouseId !== '') {
            $query->where($warehouseColumn, $this->warehouseId);
        }

        return $query;
    }

    public function updatedPeriod(): void
    {
        $this->startDate = null;
        $this->endDate = null;
    }

    public function updatedProductCategory(): void
    {
        $this->productId = '';
    }

    public function clearCustomDate(): void
    {
        $this->startDate = null;
        $this->endDate = null;

        Notification::make()
            ->title('Rentang tanggal berhasil dikosongkan')
            ->success()
            ->send();
    }

    public function resetFilters(): void
    {
        $this->period = 'all';
        $this->startDate = null;
        $this->endDate = null;
        $this->warehouseId = '';
        $this->chartYear = '';
        $this->productId = '';
        $this->productCategory = '';

        Notification::make()
            ->title('Filter berhasil dikembalikan')
            ->body('Dashboard kembali menampilkan seluruh periode, seluruh gudang, dan seluruh produk.')
            ->success()
            ->send();
    }

    public function syncNow(): void
    {
        try {
            Artisan::call('dw:sync-inventory');

            Notification::make()
                ->title('Sinkronisasi Data Warehouse Berhasil')
                ->body('Data analitik persediaan telah diperbarui dari database operasional.')
                ->success()
                ->send();
        } catch (Throwable $e) {
            Notification::make()
                ->title('Sinkronisasi Data Warehouse Gagal')
                ->body($e->getMessage())
                ->danger()
                ->send();
        }
    }

    private function productNameColumn(): ?string
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
}