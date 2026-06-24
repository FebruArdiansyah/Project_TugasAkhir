<?php

namespace App\Filament\Admin\Widgets;

use Carbon\Carbon;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DataWarehouseEtlInfoWidget extends StatsOverviewWidget
{
    protected ?string $heading = null;

    protected static ?int $sort = 2;

    public static function canView(): bool
    {
        return request()->is('admin/data-warehouse-dashboard*');
    }

    protected function getStats(): array
    {
        $lastSyncAt = $this->lastSyncAt();
        $latestMovementDate = $this->latestMovementDate();

        $movementRows = Schema::hasTable('dw_fact_inventory_movements')
            ? DB::table('dw_fact_inventory_movements')->count()
            : 0;

        $etlStatus = $lastSyncAt && $movementRows > 0
            ? 'Aktif'
            : 'Belum Sinkron';

        return [
            Stat::make(
                'Terakhir Sinkronisasi ETL',
                $lastSyncAt ? $lastSyncAt->format('d M Y H:i') : '-'
            )
                ->description($lastSyncAt ? $lastSyncAt->diffForHumans() : 'Belum ada data sinkronisasi')
                ->descriptionIcon('heroicon-m-arrow-path')
                ->color($lastSyncAt ? 'success' : 'gray'),

            Stat::make(
                'Status ETL',
                $etlStatus
            )
                ->description($etlStatus === 'Aktif'
                    ? 'Data warehouse tersedia dan dapat digunakan'
                    : 'Data warehouse belum memiliki hasil sinkronisasi'
                )
                ->descriptionIcon($etlStatus === 'Aktif'
                    ? 'heroicon-m-check-circle'
                    : 'heroicon-m-exclamation-triangle'
                )
                ->color($etlStatus === 'Aktif' ? 'success' : 'warning'),

            Stat::make(
                'Tanggal Data Terbaru',
                $latestMovementDate ? $latestMovementDate->format('d M Y') : '-'
            )
                ->description('Tanggal transaksi terbaru pada data warehouse')
                ->descriptionIcon('heroicon-m-calendar-days')
                ->color($latestMovementDate ? 'info' : 'gray'),

            Stat::make(
                'Baris Fact Movement',
                number_format($movementRows, 0, ',', '.')
            )
                ->description('Jumlah baris pada tabel dw_fact_inventory_movements')
                ->descriptionIcon('heroicon-m-circle-stack')
                ->color('primary'),
        ];
    }

    private function lastSyncAt(): ?Carbon
    {
        $tables = [
            'dw_fact_inventory_movements',
            'dw_fact_inbound_transactions',
            'dw_fact_outbound_transactions',
            'dw_fact_stock_snapshots',
            'dw_dim_products',
            'dw_dim_warehouses',
            'dw_dim_dates',
        ];

        $latest = null;

        foreach ($tables as $table) {
            if (! Schema::hasTable($table)) {
                continue;
            }

            $column = null;

            if (Schema::hasColumn($table, 'updated_at')) {
                $column = 'updated_at';
            } elseif (Schema::hasColumn($table, 'created_at')) {
                $column = 'created_at';
            }

            if (! $column) {
                continue;
            }

            $value = DB::table($table)->max($column);

            if (! $value) {
                continue;
            }

            $date = Carbon::parse($value);

            if (! $latest || $date->greaterThan($latest)) {
                $latest = $date;
            }
        }

        return $latest;
    }

    private function latestMovementDate(): ?Carbon
    {
        if (! Schema::hasTable('dw_fact_inventory_movements')) {
            return null;
        }

        if (! Schema::hasColumn('dw_fact_inventory_movements', 'date_key')) {
            return null;
        }

        $dateKey = DB::table('dw_fact_inventory_movements')->max('date_key');

        if (! $dateKey) {
            return null;
        }

        return Carbon::createFromFormat('Ymd', (string) $dateKey);
    }
}