<?php

namespace App\Filament\Admin\Resources\AssetImportLogs;

use App\Filament\Admin\Resources\AssetImportLogs\Pages\CreateAssetImportLog;
use App\Filament\Admin\Resources\AssetImportLogs\Pages\EditAssetImportLog;
use App\Filament\Admin\Resources\AssetImportLogs\Pages\ListAssetImportLogs;
use App\Filament\Admin\Resources\AssetImportLogs\Pages\ViewAssetImportLog;
use App\Filament\Admin\Resources\AssetImportLogs\Schemas\AssetImportLogForm;
use App\Filament\Admin\Resources\AssetImportLogs\Schemas\AssetImportLogInfolist;
use App\Models\AssetImportLog;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables;
use Filament\Tables\Table;

class AssetImportLogResource extends Resource
{
    protected static ?string $model = AssetImportLog::class;

    protected static \BackedEnum|string|null $navigationIcon = 'heroicon-o-clock';

    protected static \UnitEnum|string|null $navigationGroup = 'Manajemen Aset';

    protected static ?string $navigationLabel = 'Log Import Aset';

    protected static ?string $modelLabel = 'Log Import Aset';

    protected static ?string $pluralModelLabel = 'Log Import Aset';

    protected static ?string $recordTitleAttribute = 'file_name';

    public static function form(Schema $schema): Schema
    {
        return AssetImportLogForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return AssetImportLogInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('file_name')
                    ->label('Nama File')
                    ->searchable(),

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
            'index' => ListAssetImportLogs::route('/'),
            'create' => CreateAssetImportLog::route('/create'),
            'view' => ViewAssetImportLog::route('/{record}'),
            'edit' => EditAssetImportLog::route('/{record}/edit'),
        ];
    }
}