<?php

namespace App\Filament\Admin\Resources\InventoryImportLogs\Pages;

use App\Filament\Admin\Resources\InventoryImportLogs\InventoryImportLogResource;
use Filament\Actions\EditAction;
use Filament\Resources\Pages\ViewRecord;

class ViewInventoryImportLog extends ViewRecord
{
    protected static string $resource = InventoryImportLogResource::class;

    protected function getHeaderActions(): array
    {
        return [
            EditAction::make(),
        ];
    }
}
