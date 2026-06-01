<?php

namespace App\Filament\Admin\Resources\ProductCategories\Schemas;

use Filament\Infolists\Components\IconEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ProductCategoryInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Kategori Produk')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('name')
                                    ->label('Nama Kategori')
                                    ->weight('bold'),

                                IconEntry::make('is_active')
                                    ->label('Status Aktif')
                                    ->boolean(),

                                TextEntry::make('products_count')
                                    ->label('Jumlah Produk')
                                    ->state(fn ($record): int => $record->products()->count())
                                    ->badge(),
                            ]),
                    ]),

                Section::make('Waktu Data')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('created_at')
                                    ->label('Dibuat')
                                    ->dateTime('d M Y H:i'),

                                TextEntry::make('updated_at')
                                    ->label('Diupdate')
                                    ->dateTime('d M Y H:i'),
                            ]),
                    ])
                    ->collapsible(),
            ]);
    }
}