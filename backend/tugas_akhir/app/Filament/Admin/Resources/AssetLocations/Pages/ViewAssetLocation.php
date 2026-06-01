<?php

namespace App\Filament\Admin\Resources\AssetLocations\Pages;

use App\Filament\Admin\Resources\AssetLocations\AssetLocationResource;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Enums\Width;

class ViewAssetLocation extends ViewRecord
{
    protected static string $resource = AssetLocationResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}