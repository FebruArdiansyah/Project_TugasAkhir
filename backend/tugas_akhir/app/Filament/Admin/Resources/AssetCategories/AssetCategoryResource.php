<?php

namespace App\Filament\Admin\Resources\AssetCategories;

use App\Filament\Admin\Resources\AssetCategories\Pages\CreateAssetCategory;
use App\Filament\Admin\Resources\AssetCategories\Pages\EditAssetCategory;
use App\Filament\Admin\Resources\AssetCategories\Pages\ListAssetCategories;
use App\Filament\Admin\Resources\AssetCategories\Pages\ViewAssetCategory;
use App\Filament\Admin\Resources\AssetCategories\Schemas\AssetCategoryForm;
use App\Filament\Admin\Resources\AssetCategories\Schemas\AssetCategoryInfolist;
use App\Filament\Admin\Resources\AssetCategories\Tables\AssetCategoriesTable;
use App\Models\AssetCategory;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;


class AssetCategoryResource extends Resource
{
    protected static ?string $model = AssetCategory::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedRectangleStack;

    protected static ?string $navigationLabel = 'Kategori Aset';

    protected static ?string $modelLabel = 'Kategori Aset';

    protected static ?string $pluralModelLabel = 'Kategori Aset';

    protected static string|\UnitEnum|null $navigationGroup = 'Manajemen Aset';

    protected static ?int $navigationSort = 10;

    protected static ?string $recordTitleAttribute = 'name';

    public static function form(Schema $schema): Schema
    {
        return AssetCategoryForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return AssetCategoryInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return AssetCategoriesTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListAssetCategories::route('/'),
            'create' => CreateAssetCategory::route('/create'),
            'view' => ViewAssetCategory::route('/{record}'),
            'edit' => EditAssetCategory::route('/{record}/edit'),
        ];
    }
}