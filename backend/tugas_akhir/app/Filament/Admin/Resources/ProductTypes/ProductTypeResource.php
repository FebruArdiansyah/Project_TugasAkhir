<?php

namespace App\Filament\Admin\Resources\ProductTypes;

use App\Filament\Admin\Resources\ProductTypes\Pages\CreateProductType;
use App\Filament\Admin\Resources\ProductTypes\Pages\EditProductType;
use App\Filament\Admin\Resources\ProductTypes\Pages\ListProductTypes;
use App\Filament\Admin\Resources\ProductTypes\Pages\ViewProductType;
use App\Filament\Admin\Resources\ProductTypes\Schemas\ProductTypeForm;
use App\Filament\Admin\Resources\ProductTypes\Schemas\ProductTypeInfolist;
use App\Filament\Admin\Resources\ProductTypes\Tables\ProductTypesTable;
use App\Models\ProductType;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class ProductTypeResource extends Resource
{
    protected static ?string $model = ProductType::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedRectangleStack;

    protected static ?string $navigationLabel = 'Type Produk';

    protected static ?string $modelLabel = 'Type Produk';

    protected static ?string $pluralModelLabel = 'Type Produk';

    protected static string|\UnitEnum|null $navigationGroup = 'Master Data';

    protected static ?int $navigationSort = 60;

    protected static ?string $recordTitleAttribute = 'name';

    public static function form(Schema $schema): Schema
    {
        return ProductTypeForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return ProductTypeInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return ProductTypesTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListProductTypes::route('/'),
            'create' => CreateProductType::route('/create'),
            'view' => ViewProductType::route('/{record}'),
            'edit' => EditProductType::route('/{record}/edit'),
        ];
    }
}