<?php

namespace App\Filament\Admin\Resources\AssetLocations\Schemas;

use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use App\Services\AssetCodeService;

class AssetLocationForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Lokasi Aset')
                    ->description('Master lokasi aset seperti DAON, DAUN, JL. BARU, CILONGOK, Gudang Utama, atau Kantor.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('code')
                                ->label('Kode Lokasi')
                                ->default(fn (): string => app(AssetCodeService::class)->nextAssetLocationCode())
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
                                    ->label('Nama Lokasi')
                                    ->placeholder('Contoh: Gudang Utama')
                                    ->required()
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                Toggle::make('is_active')
                                    ->label('Aktif')
                                    ->default(true)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 2,
                                    ]),

                                Textarea::make('address')
                                    ->label('Alamat / Keterangan Lokasi')
                                    ->placeholder('Alamat atau detail lokasi aset...')
                                    ->rows(3)
                                    ->columnSpanFull(),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }
}