<?php

namespace App\Filament\Admin\Resources\AssetCategories\Pages;

use App\Filament\Admin\Resources\AssetCategories\AssetCategoryResource;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Enums\Width;

class ViewAssetCategory extends ViewRecord
{
    protected static string $resource = AssetCategoryResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}