<?php

namespace App\Filament\Admin\Resources\Customers\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class CustomerForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Customer')
                    ->description('Data customer atau tujuan barang keluar.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('code')
                                    ->label('Kode Customer')
                                    ->placeholder('Contoh: CUS-001')
                                    ->required()
                                    ->unique(ignoreRecord: true)
                                    ->maxLength(255)
                                    ->helperText('Kode customer harus unik.')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('name')
                                    ->label('Nama Customer')
                                    ->placeholder('Contoh: CV Sumber Jaya')
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

                                Select::make('customer_type')
                                    ->label('Tipe Customer')
                                    ->options([
                                        'customer' => 'Customer',
                                        'internal' => 'Internal',
                                        'project' => 'Project',
                                        'other' => 'Lainnya',
                                    ])
                                    ->default('customer')
                                    ->native(false)
                                    ->required()
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                Textarea::make('address')
                                    ->label('Alamat')
                                    ->placeholder('Alamat customer...')
                                    ->rows(4)
                                    ->columnSpanFull(),

                                Toggle::make('is_active')
                                    ->label('Customer Aktif')
                                    ->helperText('Customer aktif dapat dipilih pada transaksi barang keluar.')
                                    ->default(true),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }
}