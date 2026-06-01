<?php

namespace App\Filament\Admin\Resources\StockBalances\Pages;

use App\Filament\Admin\Resources\StockBalances\StockBalanceResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Filament\Support\Enums\Width;

class ListStockBalances extends ListRecords
{
    protected static string $resource = StockBalanceResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()
                ->label('Tambah Data Stok')
                ->icon('heroicon-o-plus'),
        ];
    }
}