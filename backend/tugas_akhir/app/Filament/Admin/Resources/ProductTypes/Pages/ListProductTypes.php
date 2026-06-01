<?php

namespace App\Filament\Admin\Resources\ProductTypes\Pages;

use App\Filament\Admin\Resources\ProductTypes\ProductTypeResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Filament\Support\Enums\Width;

class ListProductTypes extends ListRecords
{
    protected static string $resource = ProductTypeResource::class;

    protected Width|string|null $maxContentWidth = Width::Full;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()
                ->label('Tambah Type Produk')
                ->icon('heroicon-o-plus'),
        ];
    }
}