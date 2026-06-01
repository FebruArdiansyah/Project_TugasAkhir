<?php

namespace App\Filament\Admin\Resources\ProductTypes\Pages;

use App\Filament\Admin\Resources\ProductTypes\ProductTypeResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;
use Filament\Support\Enums\Width;

class EditProductType extends EditRecord
{
    protected static string $resource = ProductTypeResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}