<?php

namespace App\Filament\Admin\Resources\ProductDensities\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ProductDensityForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Density Produk')
                    ->description('Master density / grade produk jadi, seperti D-16, D-22, D-23, dan lainnya.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('name')
                                    ->label('Nama Density / Grade')
                                    ->placeholder('Contoh: D-22')
                                    ->required()
                                    ->unique(ignoreRecord: true)
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 8,
                                    ]),

                                Toggle::make('is_active')
                                    ->label('Density Aktif')
                                    ->helperText('Density aktif dapat dipilih pada master produk.')
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