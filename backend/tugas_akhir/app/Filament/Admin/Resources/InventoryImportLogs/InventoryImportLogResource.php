<?php

namespace App\Filament\Admin\Resources\InventoryImportLogs;

use App\Filament\Admin\Resources\InventoryImportLogs\Pages\CreateInventoryImportLog;
use App\Filament\Admin\Resources\InventoryImportLogs\Pages\EditInventoryImportLog;
use App\Filament\Admin\Resources\InventoryImportLogs\Pages\ListInventoryImportLogs;
use App\Filament\Admin\Resources\InventoryImportLogs\Pages\ViewInventoryImportLog;
use App\Filament\Admin\Resources\InventoryImportLogs\Schemas\InventoryImportLogForm;
use App\Filament\Admin\Resources\InventoryImportLogs\Schemas\InventoryImportLogInfolist;
use App\Models\InventoryImportLog;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Table;

class InventoryImportLogResource extends Resource
{
    protected static ?string $model = InventoryImportLog::class;

    protected static \BackedEnum|string|null $navigationIcon = 'heroicon-o-clock';

    protected static \UnitEnum|string|null $navigationGroup = 'Transaksi Inventory';

    protected static ?int $navigationSort = 4;

    protected static ?string $navigationLabel = 'Log Import Inventory';

    protected static ?string $modelLabel = 'Log Import Inventory';

    protected static ?string $pluralModelLabel = 'Log Import Inventory';

    protected static ?string $recordTitleAttribute = 'file_name';

    public static function form(Schema $schema): Schema
    {
        return InventoryImportLogForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return InventoryImportLogInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('file_name')
                    ->label('Nama File')
                    ->searchable(),

                Tables\Columns\TextColumn::make('transaction_type')
                    ->label('Jenis')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'inbound' => 'success',
                        'outbound' => 'warning',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'inbound' => 'Barang Masuk',
                        'outbound' => 'Barang Keluar',
                        default => $state,
                    }),

                Tables\Columns\TextColumn::make('import_mode')
                    ->label('Mode')
                    ->badge()
                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                        'historical' => 'Histori Lama',
                        'operational' => 'Operasional',
                        default => $state ?? '-',
                    }),

                Tables\Columns\TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'processing' => 'warning',
                        'success' => 'success',
                        'failed' => 'danger',
                        'success_with_warning' => 'gray',
                        default => 'gray',
                    }),

                Tables\Columns\TextColumn::make('total_rows')
                    ->label('Total'),

                Tables\Columns\TextColumn::make('imported_rows')
                    ->label('Berhasil'),

                Tables\Columns\TextColumn::make('skipped_rows')
                    ->label('Dilewati'),

                Tables\Columns\TextColumn::make('message')
                    ->label('Pesan')
                    ->limit(40)
                    ->toggleable(),

                Tables\Columns\TextColumn::make('error_message')
                    ->label('Error')
                    ->limit(40)
                    ->toggleable(isToggledHiddenByDefault: true),

                Tables\Columns\TextColumn::make('started_at')
                    ->label('Mulai')
                    ->dateTime('d M Y H:i'),

                Tables\Columns\TextColumn::make('finished_at')
                    ->label('Selesai')
                    ->dateTime('d M Y H:i'),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListInventoryImportLogs::route('/'),
            'create' => CreateInventoryImportLog::route('/create'),
            'view' => ViewInventoryImportLog::route('/{record}'),
            'edit' => EditInventoryImportLog::route('/{record}/edit'),
        ];
    }
}