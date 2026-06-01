<?php

namespace App\Filament\Admin\Resources\AssetLocations\Pages;

use App\Filament\Admin\Resources\AssetLocations\AssetLocationResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Filament\Support\Enums\Width;

class ListAssetLocations extends ListRecords
{
    protected static string $resource = AssetLocationResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()
                ->label('Tambah Lokasi Aset')
                ->icon('heroicon-o-plus'),
        ];
    }
}