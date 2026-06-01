<?php

namespace App\Filament\Admin\Resources\Units\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class UnitForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Satuan')
                    ->description('Master satuan yang digunakan pada produk dan transaksi inventory.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('code')
                                    ->label('Kode Satuan')
                                    ->placeholder('Contoh: PCS')
                                    ->required()
                                    ->unique(ignoreRecord: true)
                                    ->maxLength(255)
                                    ->helperText('Kode satuan harus unik.')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('name')
                                    ->label('Nama Satuan')
                                    ->placeholder('Contoh: Pieces')
                                    ->required()
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 8,
                                    ]),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }
}