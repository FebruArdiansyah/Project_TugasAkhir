<?php

namespace App\Filament\Admin\Resources\ProductDensities\Pages;

use App\Filament\Admin\Resources\ProductDensities\ProductDensityResource;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Enums\Width;

class ViewProductDensity extends ViewRecord
{
    protected static string $resource = ProductDensityResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}