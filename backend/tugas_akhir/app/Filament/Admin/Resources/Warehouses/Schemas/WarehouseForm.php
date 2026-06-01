<?php

namespace App\Filament\Admin\Resources\Warehouses\Schemas;

use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class WarehouseForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Gudang')
                    ->description('Data gudang yang digunakan untuk stok, transaksi barang masuk, dan barang keluar.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('code')
                                    ->label('Kode Gudang')
                                    ->placeholder('Contoh: GDG-001')
                                    ->required()
                                    ->unique(ignoreRecord: true)
                                    ->maxLength(255)
                                    ->helperText('Kode gudang harus unik.')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('name')
                                    ->label('Nama Gudang')
                                    ->placeholder('Contoh: Gudang Utama')
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
                                    ->label('Gudang Aktif')
                                    ->helperText('Gudang aktif dapat dipilih pada transaksi dan stok.')
                                    ->default(true)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                Textarea::make('address')
                                    ->label('Alamat Gudang')
                                    ->placeholder('Alamat lengkap gudang...')
                                    ->rows(4)
                                    ->columnSpanFull(),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }
}