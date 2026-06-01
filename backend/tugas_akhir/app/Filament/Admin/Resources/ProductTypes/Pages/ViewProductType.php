<?php

namespace App\Filament\Admin\Resources\ProductTypes\Pages;

use App\Filament\Admin\Resources\ProductTypes\ProductTypeResource;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Enums\Width;

class ViewProductType extends ViewRecord
{
    protected static string $resource = ProductTypeResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}