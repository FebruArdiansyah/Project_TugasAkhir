<?php

namespace App\Filament\Admin\Resources\StockBalances\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class StockBalanceForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Stok')
                    ->description('Saldo stok produk per gudang. Stok fisik berubah otomatis melalui approval transaksi.')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                Select::make('product_id')
                                    ->label('Produk')
                                    ->relationship('product', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->required()
                                    ->disabledOn('edit'),

                                Select::make('warehouse_id')
                                    ->label('Gudang')
                                    ->relationship('warehouse', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->required()
                                    ->disabledOn('edit'),
                            ]),

                        Grid::make(3)
                            ->schema([
                                TextInput::make('qty_on_hand')
                                    ->label('Stok Fisik')
                                    ->numeric()
                                    ->default(0)
                                    ->suffix('PCS')
                                    ->disabled()
                                    ->dehydrated(true)
                                    ->helperText('Berubah otomatis setelah transaksi disetujui.'),

                                TextInput::make('qty_reserved')
                                    ->label('Stok Pending / Reserved')
                                    ->numeric()
                                    ->default(0)
                                    ->suffix('PCS')
                                    ->disabled()
                                    ->dehydrated(true)
                                    ->helperText('Stok yang sedang menunggu approval barang keluar.'),

                                TextInput::make('minimum_stock')
                                    ->label('Minimum Stok')
                                    ->numeric()
                                    ->default(0)
                                    ->minValue(0)
                                    ->suffix('PCS')
                                    ->required()
                                    ->helperText('Dipakai untuk menentukan status stok menipis.'),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }
}