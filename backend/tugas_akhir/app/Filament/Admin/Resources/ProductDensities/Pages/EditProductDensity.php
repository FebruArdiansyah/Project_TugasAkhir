<?php

namespace App\Filament\Admin\Resources\ProductDensities\Pages;

use App\Filament\Admin\Resources\ProductDensities\ProductDensityResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;
use Filament\Support\Enums\Width;

class EditProductDensity extends EditRecord
{
    protected static string $resource = ProductDensityResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}