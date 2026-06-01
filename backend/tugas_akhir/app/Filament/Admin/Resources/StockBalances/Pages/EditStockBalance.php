<?php

namespace App\Filament\Admin\Resources\StockBalances\Pages;

use App\Filament\Admin\Resources\StockBalances\StockBalanceResource;
use Filament\Actions\DeleteAction;
use Filament\Actions\ViewAction;
use Filament\Resources\Pages\EditRecord;

class EditStockBalance extends EditRecord
{
    protected static string $resource = StockBalanceResource::class;

    protected function getHeaderActions(): array
    {
        return [
            ViewAction::make(),
            DeleteAction::make(),
        ];
    }
}
