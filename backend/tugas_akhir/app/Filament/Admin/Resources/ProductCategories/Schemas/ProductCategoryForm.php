<?php

namespace App\Filament\Admin\Resources\ProductCategories\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ProductCategoryForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Kategori Produk')
                    ->description('Master kategori produk jadi, seperti LG++, VACUM, KARUNG, LIGHT GREEN, dan lainnya.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('name')
                                    ->label('Nama Kategori')
                                    ->placeholder('Contoh: LG++')
                                    ->required()
                                    ->unique(ignoreRecord: true)
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 8,
                                    ]),

                                Toggle::make('is_active')
                                    ->label('Kategori Aktif')
                                    ->helperText('Kategori aktif dapat dipilih pada master produk.')
                                    ->default(true)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }
}