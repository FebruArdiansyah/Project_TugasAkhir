<?php

namespace App\Filament\Admin\Resources\AssetImportLogs\Pages;

use App\Filament\Admin\Resources\AssetImportLogs\AssetImportLogResource;
use Filament\Actions\DeleteAction;
use Filament\Actions\ViewAction;
use Filament\Resources\Pages\EditRecord;

class EditAssetImportLog extends EditRecord
{
    protected static string $resource = AssetImportLogResource::class;

    protected function getHeaderActions(): array
    {
        return [
            ViewAction::make(),
            DeleteAction::make(),
        ];
    }
}
