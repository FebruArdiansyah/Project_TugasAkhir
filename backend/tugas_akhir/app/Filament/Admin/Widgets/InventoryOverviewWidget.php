<?php

namespace App\Filament\Admin\Widgets;

use App\Models\InboundTransaction;
use App\Models\OutboundTransaction;
use App\Models\Product;
use App\Models\StockBalance;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class InventoryOverviewWidget extends StatsOverviewWidget
{
    protected ?string $heading = 'Ringkasan Inventory';

    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $totalProducts = Product::query()->count();

        $totalStock = StockBalance::query()
            ->sum('qty_on_hand');

        $lowStock = StockBalance::query()
            ->whereRaw('(qty_on_hand - qty_reserved) > 0')
            ->whereRaw('(qty_on_hand - qty_reserved) <= minimum_stock')
            ->count();

        $emptyStock = StockBalance::query()
            ->whereRaw('(qty_on_hand - qty_reserved) <= 0')
            ->count();

        $pendingInbound = InboundTransaction::query()
            ->where('status', 'pending')
            ->count();

        $pendingOutbound = OutboundTransaction::query()
            ->where('status', 'pending')
            ->count();

        $approvedInboundThisMonth = InboundTransaction::query()
            ->where('status', 'approved')
            ->whereMonth('approved_at', now()->month)
            ->whereYear('approved_at', now()->year)
            ->count();

        $approvedOutboundThisMonth = OutboundTransaction::query()
            ->where('status', 'approved')
            ->whereMonth('approved_at', now()->month)
            ->whereYear('approved_at', now()->year)
            ->count();

        return [
            Stat::make('Total Produk', number_format($totalProducts, 0, ',', '.'))
                ->description('Master produk jadi')
                ->descriptionIcon('heroicon-m-cube')
                ->color('primary'),

            Stat::make('Total Stok Fisik', number_format((float) $totalStock, 0, ',', '.'))
                ->description('Akumulasi seluruh gudang')
                ->descriptionIcon('heroicon-m-archive-box')
                ->color('success'),

            Stat::make('Stok Menipis', number_format($lowStock, 0, ',', '.'))
                ->description('Produk perlu perhatian')
                ->descriptionIcon('heroicon-m-exclamation-triangle')
                ->color('warning'),

            Stat::make('Stok Habis', number_format($emptyStock, 0, ',', '.'))
                ->description('Produk tidak tersedia')
                ->descriptionIcon('heroicon-m-x-circle')
                ->color('danger'),

            Stat::make('Barang Masuk Pending', number_format($pendingInbound, 0, ',', '.'))
                ->description('Menunggu approval admin')
                ->descriptionIcon('heroicon-m-arrow-down-tray')
                ->color('warning'),

            Stat::make('Barang Keluar Pending', number_format($pendingOutbound, 0, ',', '.'))
                ->description('Menunggu approval admin')
                ->descriptionIcon('heroicon-m-arrow-up-tray')
                ->color('warning'),

            Stat::make('Masuk Approved Bulan Ini', number_format($approvedInboundThisMonth, 0, ',', '.'))
                ->description('Transaksi masuk disetujui')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('success'),

            Stat::make('Keluar Approved Bulan Ini', number_format($approvedOutboundThisMonth, 0, ',', '.'))
                ->description('Transaksi keluar disetujui')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('success'),
        ];
    }
}