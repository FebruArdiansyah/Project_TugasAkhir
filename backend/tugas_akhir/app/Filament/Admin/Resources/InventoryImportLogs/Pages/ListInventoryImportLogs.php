<?php

namespace App\Filament\Admin\Resources\InventoryImportLogs\Pages;

use App\Filament\Admin\Resources\InventoryImportLogs\InventoryImportLogResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListInventoryImportLogs extends ListRecords
{
    protected static string $resource = InventoryImportLogResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
