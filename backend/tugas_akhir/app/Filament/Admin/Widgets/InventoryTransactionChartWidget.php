<?php

namespace App\Filament\Admin\Widgets;

use App\Models\InboundTransaction;
use App\Models\OutboundTransaction;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Collection;

class InventoryTransactionChartWidget extends ChartWidget
{
    protected ?string $heading = 'Grafik Transaksi Inventory';

    protected ?string $description = 'Perbandingan barang masuk dan barang keluar yang sudah disetujui dalam 6 bulan terakhir.';

    protected static ?int $sort = 2;

    protected function getData(): array
    {
        $months = collect(range(5, 0))
            ->map(fn (int $monthBack) => now()->subMonths($monthBack)->startOfMonth());

        return [
            'datasets' => [
                [
                    'label' => 'Barang Masuk Approved',
                    'data' => $this->getInboundData($months),
                ],
                [
                    'label' => 'Barang Keluar Approved',
                    'data' => $this->getOutboundData($months),
                ],
            ],
            'labels' => $months
                ->map(fn ($date): string => $date->translatedFormat('M Y'))
                ->toArray(),
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }

    private function getInboundData(Collection $months): array
    {
        return $months
            ->map(function ($date): int {
                return InboundTransaction::query()
                    ->where('status', 'approved')
                    ->whereBetween('approved_at', [
                        $date->copy()->startOfMonth(),
                        $date->copy()->endOfMonth(),
                    ])
                    ->count();
            })
            ->toArray();
    }

    private function getOutboundData(Collection $months): array
    {
        return $months
            ->map(function ($date): int {
                return OutboundTransaction::query()
                    ->where('status', 'approved')
                    ->whereBetween('approved_at', [
                        $date->copy()->startOfMonth(),
                        $date->copy()->endOfMonth(),
                    ])
                    ->count();
            })
            ->toArray();
    }
}