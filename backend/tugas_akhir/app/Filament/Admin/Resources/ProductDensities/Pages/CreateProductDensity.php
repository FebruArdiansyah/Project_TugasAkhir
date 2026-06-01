<?php

namespace App\Filament\Admin\Resources\ProductDensities\Pages;

use App\Filament\Admin\Resources\ProductDensities\ProductDensityResource;
use Filament\Resources\Pages\CreateRecord;
use Filament\Support\Enums\Width;

class CreateProductDensity extends CreateRecord
{
    protected static string $resource = ProductDensityResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}