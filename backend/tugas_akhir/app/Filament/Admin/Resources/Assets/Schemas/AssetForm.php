<?php

namespace App\Filament\Admin\Resources\Assets\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use App\Services\AssetCodeService;

class AssetForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Identitas Aset')
                    ->description('Data utama aset tetap perusahaan.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('asset_code')
                                ->label('Kode Aset')
                                ->default(fn (): string => app(AssetCodeService::class)->nextAssetCode())
                                ->required()
                                ->readOnly()
                                ->dehydrated(true)
                                ->unique(ignoreRecord: true)
                                ->maxLength(255)
                                ->columnSpan([
                                    'default' => 12,
                                    'md' => 4,
                                ]),

                                TextInput::make('name')
                                    ->label('Nama Aset')
                                    ->placeholder('Contoh: Truck Fuso Kuning')
                                    ->required()
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 8,
                                    ]),

                                Select::make('asset_category_id')
                                    ->label('Kategori Aset')
                                    ->relationship('category', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->required()
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                Select::make('asset_location_id')
                                    ->label('Lokasi Aset')
                                    ->relationship('location', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->required()
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),
                            ]),
                    ])
                    ->columnSpanFull(),

                Section::make('Detail Aset')
                    ->description('Detail tambahan seperti nomor kendaraan, merk, model, dan serial number.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('license_plate')
                                    ->label('No Polisi / No Kendaraan')
                                    ->placeholder('Contoh: A 9233 VM')
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('brand')
                                    ->label('Merk')
                                    ->placeholder('Contoh: Mitsubishi')
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('model')
                                    ->label('Model / Tipe')
                                    ->placeholder('Contoh: Fuso')
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('serial_number')
                                    ->label('Serial Number')
                                    ->placeholder('Nomor seri aset')
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                TextInput::make('acquisition_year')
                                    ->label('Tahun Perolehan')
                                    ->numeric()
                                    ->minValue(1900)
                                    ->maxValue((int) now()->format('Y') + 1)
                                    ->placeholder('Contoh: 2022')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 3,
                                    ]),

                                DatePicker::make('acquisition_date')
                                    ->label('Tanggal Perolehan')
                                    ->native(false)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 3,
                                    ]),

                                TextInput::make('acquisition_price')
                                    ->label('Harga Perolehan')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->minValue(0)
                                    ->default(0)
                                    ->required()
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),
                            ]),
                    ])
                    ->columnSpanFull(),

                Section::make('Kondisi dan Status')
                    ->description('Status pemakaian dan kondisi aset saat ini.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                Select::make('condition')
                                    ->label('Kondisi')
                                    ->options([
                                        'baik' => 'Baik',
                                        'rusak_ringan' => 'Rusak Ringan',
                                        'rusak_berat' => 'Rusak Berat',
                                    ])
                                    ->default('baik')
                                    ->native(false)
                                    ->required()
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                Select::make('status')
                                    ->label('Status')
                                    ->options([
                                        'aktif' => 'Aktif',
                                        'maintenance' => 'Maintenance',
                                        'dipinjam' => 'Dipinjam',
                                        'rusak' => 'Rusak',
                                        'tidak_aktif' => 'Tidak Aktif',
                                    ])
                                    ->default('aktif')
                                    ->native(false)
                                    ->required()
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                Textarea::make('description')
                                    ->label('Keterangan')
                                    ->placeholder('Catatan tambahan aset...')
                                    ->rows(4)
                                    ->columnSpanFull(),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }
}