<?php

namespace App\Filament\Admin\Resources\AssetImportLogs\Pages;

use App\Filament\Admin\Resources\AssetImportLogs\AssetImportLogResource;
use Filament\Actions\EditAction;
use Filament\Resources\Pages\ViewRecord;

class ViewAssetImportLog extends ViewRecord
{
    protected static string $resource = AssetImportLogResource::class;

    protected function getHeaderActions(): array
    {
        return [
            EditAction::make(),
        ];
    }
}
