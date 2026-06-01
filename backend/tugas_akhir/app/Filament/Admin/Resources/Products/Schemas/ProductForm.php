<?php

namespace App\Filament\Admin\Resources\Products\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ProductForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Produk')
                    ->description('Data utama produk jadi yang akan digunakan untuk inventory, stok gudang, dan transaksi.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('code')
                                    ->label('Kode Produk')
                                    ->placeholder('Contoh: BRG-001')
                                    ->required()
                                    ->maxLength(255)
                                    ->unique(ignoreRecord: true)
                                    ->helperText('Kode produk harus unik.')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('name')
                                    ->label('Nama Produk')
                                    ->placeholder('Contoh: EON D-22 LG++')
                                    ->required()
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 8,
                                    ]),

                                TextInput::make('full_name')
                                    ->label('Nama Lengkap Produk')
                                    ->placeholder('Contoh: EON D-22 LG++ 200 x 145 x 30 CM')
                                    ->maxLength(255)
                                    ->helperText('Nama lengkap yang tampil di transaksi dan laporan.')
                                    ->columnSpanFull(),

                                Select::make('product_type_id')
                                    ->label('Type Produk')
                                    ->relationship('type', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->placeholder('Pilih type')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 3,
                                    ]),

                                Select::make('product_density_id')
                                    ->label('Density / Grade')
                                    ->relationship('density', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->placeholder('Pilih density')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 3,
                                    ]),

                                Select::make('product_category_id')
                                    ->label('Kategori')
                                    ->relationship('category', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->placeholder('Pilih kategori')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 3,
                                    ]),

                                Select::make('unit_id')
                                    ->label('Satuan')
                                    ->relationship('unit', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->placeholder('Pilih satuan')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 3,
                                    ]),
                            ]),
                    ])
                    ->columnSpanFull(),

                Section::make('Spesifikasi Ukuran')
                    ->description('Isi ukuran produk jika produk memiliki dimensi. Untuk VACUM atau KARUNG boleh dikosongkan.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('length')
                                    ->label('Panjang')
                                    ->numeric()
                                    ->minValue(0)
                                    ->suffix('CM')
                                    ->placeholder('200')
                                    ->columnSpan([
                                        'default' => 12,
                                        'sm' => 4,
                                        'md' => 3,
                                    ]),

                                TextInput::make('width')
                                    ->label('Lebar')
                                    ->numeric()
                                    ->minValue(0)
                                    ->suffix('CM')
                                    ->placeholder('145')
                                    ->columnSpan([
                                        'default' => 12,
                                        'sm' => 4,
                                        'md' => 3,
                                    ]),

                                TextInput::make('thickness')
                                    ->label('Tebal')
                                    ->numeric()
                                    ->minValue(0)
                                    ->suffix('CM')
                                    ->placeholder('30')
                                    ->columnSpan([
                                        'default' => 12,
                                        'sm' => 4,
                                        'md' => 3,
                                    ]),

                                TextInput::make('size_text')
                                    ->label('Label Ukuran')
                                    ->placeholder('200 x 145 x 30 CM')
                                    ->maxLength(255)
                                    ->helperText('Boleh diisi manual sesuai format produk.')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 3,
                                    ]),
                            ]),
                    ])
                    ->columnSpanFull(),

                Section::make('Harga Produk')
                    ->description('Harga di master hanya sebagai referensi. Harga invoice asli tetap disimpan di detail transaksi.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('default_purchase_price')
                                    ->label('Harga Beli Default')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->minValue(0)
                                    ->default(0)
                                    ->required()
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                TextInput::make('default_selling_price')
                                    ->label('Harga Jual Default')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->minValue(0)
                                    ->default(0)
                                    ->required()
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                TextInput::make('last_purchase_price')
                                    ->label('Harga Beli Terakhir')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->minValue(0)
                                    ->default(0)
                                    ->disabled()
                                    ->dehydrated(true)
                                    ->helperText('Akan ter-update otomatis dari transaksi barang masuk.')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                TextInput::make('last_selling_price')
                                    ->label('Harga Jual Terakhir')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->minValue(0)
                                    ->default(0)
                                    ->disabled()
                                    ->dehydrated(true)
                                    ->helperText('Akan ter-update otomatis dari transaksi barang keluar.')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),
                            ]),
                    ])
                    ->columnSpanFull(),

                Section::make('Deskripsi dan Status')
                    ->schema([
                        Textarea::make('description')
                            ->label('Deskripsi')
                            ->placeholder('Catatan tambahan produk...')
                            ->rows(4)
                            ->columnSpanFull(),

                        Toggle::make('is_active')
                            ->label('Produk Aktif')
                            ->helperText('Produk aktif dapat digunakan pada transaksi barang masuk dan barang keluar.')
                            ->default(true),
                    ])
                    ->columnSpanFull(),
            ]);
    }
}