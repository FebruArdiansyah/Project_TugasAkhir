<?php

namespace App\Filament\Admin\Resources\Profiles\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ProfileForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Akun')
                    ->description('Hubungkan user login dengan data profile staff.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                Select::make('user_id')
                                    ->label('User')
                                    ->relationship('user', 'name')
                                    ->getOptionLabelFromRecordUsing(fn ($record): string => "{$record->name} ({$record->email})")
                                    ->searchable(['name', 'email'])
                                    ->preload()
                                    ->native(false)
                                    ->required()
                                    ->unique(ignoreRecord: true)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                Select::make('warehouse_id')
                                    ->label('Gudang / Area Tugas')
                                    ->relationship('warehouse', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->placeholder('Pilih gudang')
                                    ->helperText('Gudang ini bisa dipakai untuk membatasi operasional user mobile.')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                TextInput::make('username')
                                    ->label('Username')
                                    ->placeholder('Contoh: arhan_gudang')
                                    ->unique(ignoreRecord: true)
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('employee_code')
                                    ->label('Kode Karyawan')
                                    ->placeholder('Contoh: EMP-001')
                                    ->unique(ignoreRecord: true)
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('position')
                                    ->label('Jabatan')
                                    ->placeholder('Contoh: Staff Gudang')
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),
                            ]),
                    ])
                    ->columnSpanFull(),

                Section::make('Kontak dan Status')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('phone')
                                    ->label('No. Telepon')
                                    ->placeholder('Contoh: 08123456789')
                                    ->tel()
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                DateTimePicker::make('last_login_at')
                                    ->label('Login Terakhir')
                                    ->native(false)
                                    ->disabled()
                                    ->dehydrated(true)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                Toggle::make('is_active')
                                    ->label('Profile Aktif')
                                    ->helperText('User aktif dapat digunakan untuk operasional sistem.')
                                    ->default(true)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                Textarea::make('address')
                                    ->label('Alamat')
                                    ->placeholder('Alamat staff...')
                                    ->rows(4)
                                    ->columnSpanFull(),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }
}