<?php

namespace App\Filament\Admin\Resources\Units\Pages;

use App\Filament\Admin\Resources\Units\UnitResource;
use Filament\Resources\Pages\ViewRecord;
use Filament\Support\Enums\Width;

class ViewUnit extends ViewRecord
{
    protected static string $resource = UnitResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;
}