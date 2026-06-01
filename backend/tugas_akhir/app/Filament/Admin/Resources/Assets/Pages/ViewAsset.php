<?php

namespace App\Filament\Admin\Resources\Assets\Pages;

use App\Filament\Admin\Resources\Assets\AssetResource;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Enums\Width;

class ViewAsset extends ViewRecord
{
    protected static string $resource = AssetResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}