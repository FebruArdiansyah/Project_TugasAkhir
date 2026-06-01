<?php

namespace App\Filament\Admin\Resources\AssetLocations;

use App\Filament\Admin\Resources\AssetLocations\Pages\CreateAssetLocation;
use App\Filament\Admin\Resources\AssetLocations\Pages\EditAssetLocation;
use App\Filament\Admin\Resources\AssetLocations\Pages\ListAssetLocations;
use App\Filament\Admin\Resources\AssetLocations\Pages\ViewAssetLocation;
use App\Filament\Admin\Resources\AssetLocations\Schemas\AssetLocationForm;
use App\Filament\Admin\Resources\AssetLocations\Schemas\AssetLocationInfolist;
use App\Filament\Admin\Resources\AssetLocations\Tables\AssetLocationsTable;
use App\Models\AssetLocation;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class AssetLocationResource extends Resource
{
    protected static ?string $model = AssetLocation::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedMapPin;

    protected static ?string $navigationLabel = 'Lokasi Aset';

    protected static ?string $modelLabel = 'Lokasi Aset';

    protected static ?string $pluralModelLabel = 'Lokasi Aset';

    protected static string|\UnitEnum|null $navigationGroup = 'Manajemen Aset';

    protected static ?int $navigationSort = 20;

    protected static ?string $recordTitleAttribute = 'name';

    public static function form(Schema $schema): Schema
    {
        return AssetLocationForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return AssetLocationInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return AssetLocationsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListAssetLocations::route('/'),
            'create' => CreateAssetLocation::route('/create'),
            'view' => ViewAssetLocation::route('/{record}'),
            'edit' => EditAssetLocation::route('/{record}/edit'),
        ];
    }
}