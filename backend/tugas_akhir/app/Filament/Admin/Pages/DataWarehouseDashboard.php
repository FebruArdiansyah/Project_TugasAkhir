<?php

namespace App\Filament\Admin\Pages;

use BackedEnum;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Support\Enums\Width;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Throwable;

class DataWarehouseDashboard extends Page
{
    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-chart-bar-square';

    protected static string|\UnitEnum|null $navigationGroup = 'Data Warehouse';

    protected static ?string $navigationLabel = 'Dashboard Analitik';

    protected static ?string $title = 'Dashboard Analitik Data Warehouse';

    protected static ?int $navigationSort = 1;

    protected string $view = 'filament.admin.pages.data-warehouse-dashboard';

    protected Width|string|null $maxContentWidth = Width::Full;

    public string $period = 'month';

    public string $warehouseId = '';

    public function getWarehouses(): array
    {
        return DB::table('dw_dim_warehouses')
            ->orderBy('name')
            ->pluck('name', 'id')
            ->toArray();
    }

    public function getPeriodLabel(): string
    {
        return match ($this->period) {
            'day' => 'Hari ini',
            'week' => 'Minggu ini',
            'month' => 'Bulan ini',
            'year' => 'Tahun ini',
            'all' => 'Semua data',
            default => 'Bulan ini',
        };
    }

    public function getWarehouseLabel(): string
    {
        if (! $this->warehouseId) {
            return 'Semua gudang';
        }

        return DB::table('dw_dim_warehouses')
            ->where('id', $this->warehouseId)
            ->value('name') ?? 'Gudang tidak ditemukan';
    }

    public function resetFilters(): void
    {
        $this->period = 'month';
        $this->warehouseId = '';

        Notification::make()
            ->title('Filter berhasil direset')
            ->success()
            ->send();
    }

    public function syncNow(): void
    {
        try {
            Artisan::call('dw:sync-inventory');

            Notification::make()
                ->title('Sinkronisasi Data Warehouse berhasil')
                ->body('Data analitik sudah diperbarui dari database operasional.')
                ->success()
                ->send();
        } catch (Throwable $e) {
            Notification::make()
                ->title('Sinkronisasi gagal')
                ->body($e->getMessage())
                ->danger()
                ->send();
        }
    }
}