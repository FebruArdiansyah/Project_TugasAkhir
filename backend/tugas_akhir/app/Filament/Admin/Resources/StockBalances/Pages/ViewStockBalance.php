<?php

namespace App\Filament\Admin\Resources\StockBalances\Pages;

use App\Filament\Admin\Resources\StockBalances\StockBalanceResource;
use Filament\Actions\EditAction;
use Filament\Resources\Pages\ViewRecord;

class ViewStockBalance extends ViewRecord
{
    protected static string $resource = StockBalanceResource::class;

    protected function getHeaderActions(): array
    {
        return [
            EditAction::make(),
        ];
    }
}
