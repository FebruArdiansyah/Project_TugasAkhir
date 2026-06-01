<?php

namespace App\Filament\Admin\Resources\ProductDensities;

use App\Filament\Admin\Resources\ProductDensities\Pages\CreateProductDensity;
use App\Filament\Admin\Resources\ProductDensities\Pages\EditProductDensity;
use App\Filament\Admin\Resources\ProductDensities\Pages\ListProductDensities;
use App\Filament\Admin\Resources\ProductDensities\Pages\ViewProductDensity;
use App\Filament\Admin\Resources\ProductDensities\Schemas\ProductDensityForm;
use App\Filament\Admin\Resources\ProductDensities\Schemas\ProductDensityInfolist;
use App\Filament\Admin\Resources\ProductDensities\Tables\ProductDensitiesTable;
use App\Models\ProductDensity;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class ProductDensityResource extends Resource
{
    protected static ?string $model = ProductDensity::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedRectangleStack;

    protected static ?string $navigationLabel = 'Density Produk';

    protected static ?string $modelLabel = 'Density Produk';

    protected static ?string $pluralModelLabel = 'Density Produk';

    protected static string|\UnitEnum|null $navigationGroup = 'Master Data';

    protected static ?int $navigationSort = 70;

    protected static ?string $recordTitleAttribute = 'name';

    public static function form(Schema $schema): Schema
    {
        return ProductDensityForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return ProductDensityInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return ProductDensitiesTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListProductDensities::route('/'),
            'create' => CreateProductDensity::route('/create'),
            'view' => ViewProductDensity::route('/{record}'),
            'edit' => EditProductDensity::route('/{record}/edit'),
        ];
    }
}