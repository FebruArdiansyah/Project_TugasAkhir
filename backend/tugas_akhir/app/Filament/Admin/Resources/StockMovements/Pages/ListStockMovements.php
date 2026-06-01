<?php

namespace App\Filament\Admin\Resources\StockMovements\Pages;

use App\Filament\Admin\Resources\StockMovements\StockMovementResource;
use Filament\Resources\Pages\ListRecords;
use Filament\Support\Enums\Width;

class ListStockMovements extends ListRecords
{
    protected static string $resource = StockMovementResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}