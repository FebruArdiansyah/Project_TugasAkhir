<?php

namespace App\Filament\Admin\Resources\AssetCategories\Schemas;

use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use App\Services\AssetCodeService;

class AssetCategoryForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Kategori Aset')
                    ->description('Master kategori aset seperti Tanah & Bangunan, Kendaraan, Mesin, Inventaris Kantor, dan Inventaris Bengkel.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('code')
                                ->label('Kode Kategori')
                                ->default(fn (): string => app(AssetCodeService::class)->nextAssetCategoryCode())
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
                                    ->label('Nama Kategori')
                                    ->placeholder('Contoh: Kendaraan')
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

                                Textarea::make('description')
                                    ->label('Deskripsi')
                                    ->placeholder('Catatan kategori aset...')
                                    ->rows(3)
                                    ->columnSpanFull(),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }
}