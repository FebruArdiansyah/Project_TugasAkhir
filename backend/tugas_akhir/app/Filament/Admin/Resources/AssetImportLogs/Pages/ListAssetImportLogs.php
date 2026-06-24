<?php

namespace App\Filament\Admin\Resources\AssetImportLogs\Pages;

use App\Filament\Admin\Resources\AssetImportLogs\AssetImportLogResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListAssetImportLogs extends ListRecords
{
    protected static string $resource = AssetImportLogResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
