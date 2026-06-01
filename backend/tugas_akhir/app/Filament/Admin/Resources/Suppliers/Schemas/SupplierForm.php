<?php

namespace App\Filament\Admin\Resources\Suppliers\Schemas;

use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class SupplierForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Supplier')
                    ->description('Data pemasok barang masuk.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('code')
                                    ->label('Kode Supplier')
                                    ->placeholder('Contoh: SUP-001')
                                    ->required()
                                    ->unique(ignoreRecord: true)
                                    ->maxLength(255)
                                    ->helperText('Kode supplier harus unik.')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('name')
                                    ->label('Nama Supplier')
                                    ->placeholder('Contoh: PT Sumber Foam')
                                    ->required()
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 8,
                                    ]),

                                TextInput::make('phone')
                                    ->label('No. Telepon')
                                    ->placeholder('Contoh: 08123456789')
                                    ->tel()
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                Toggle::make('is_active')
                                    ->label('Supplier Aktif')
                                    ->helperText('Supplier aktif dapat dipilih pada transaksi barang masuk.')
                                    ->default(true)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                Textarea::make('address')
                                    ->label('Alamat')
                                    ->placeholder('Alamat supplier...')
                                    ->rows(4)
                                    ->columnSpanFull(),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }
}