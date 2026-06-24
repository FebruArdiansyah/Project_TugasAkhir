<?php

namespace App\Filament\Admin\Resources\InventoryImportLogs\Pages;

use App\Filament\Admin\Resources\InventoryImportLogs\InventoryImportLogResource;
use Filament\Resources\Pages\CreateRecord;

class CreateInventoryImportLog extends CreateRecord
{
    protected static string $resource = InventoryImportLogResource::class;
}
