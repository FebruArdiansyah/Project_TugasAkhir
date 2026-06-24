<?php

namespace App\Filament\Admin\Resources\InventoryImportLogs\Pages;

use App\Filament\Admin\Resources\InventoryImportLogs\InventoryImportLogResource;
use Filament\Actions\DeleteAction;
use Filament\Actions\ViewAction;
use Filament\Resources\Pages\EditRecord;

class EditInventoryImportLog extends EditRecord
{
    protected static string $resource = InventoryImportLogResource::class;

    protected function getHeaderActions(): array
    {
        return [
            ViewAction::make(),
            DeleteAction::make(),
        ];
    }
}
