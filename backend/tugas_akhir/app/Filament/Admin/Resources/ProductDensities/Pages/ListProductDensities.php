<?php

namespace App\Filament\Admin\Resources\ProductDensities\Pages;

use App\Filament\Admin\Resources\ProductDensities\ProductDensityResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Filament\Support\Enums\Width;

class ListProductDensities extends ListRecords
{
    protected static string $resource = ProductDensityResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()
                ->label('Tambah Density Produk')
                ->icon('heroicon-o-plus'),
        ];
    }
}