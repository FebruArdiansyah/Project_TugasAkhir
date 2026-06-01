<?php

namespace App\Filament\Admin\Resources\AssetLocations\Pages;

use App\Filament\Admin\Resources\AssetLocations\AssetLocationResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;
use Filament\Support\Enums\Width;

class EditAssetLocation extends EditRecord
{
    protected static string $resource = AssetLocationResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}