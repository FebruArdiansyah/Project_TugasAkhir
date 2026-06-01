<?php

namespace App\Filament\Admin\Resources\StockBalances;

use App\Filament\Admin\Resources\StockBalances\Pages\CreateStockBalance;
use App\Filament\Admin\Resources\StockBalances\Pages\EditStockBalance;
use App\Filament\Admin\Resources\StockBalances\Pages\ListStockBalances;
use App\Filament\Admin\Resources\StockBalances\Pages\ViewStockBalance;
use App\Filament\Admin\Resources\StockBalances\Schemas\StockBalanceForm;
use App\Filament\Admin\Resources\StockBalances\Schemas\StockBalanceInfolist;
use App\Filament\Admin\Resources\StockBalances\Tables\StockBalancesTable;
use App\Models\StockBalance;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class StockBalanceResource extends Resource
{
    protected static ?string $model = StockBalance::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedArchiveBox;

    protected static ?string $navigationLabel = 'Stok Gudang';

    protected static ?string $modelLabel = 'Stok Gudang';

    protected static ?string $pluralModelLabel = 'Stok Gudang';

    protected static string|\UnitEnum|null $navigationGroup = 'Inventory Management';

    protected static ?int $navigationSort = 20;

    protected static ?string $recordTitleAttribute = null;

    public static function form(Schema $schema): Schema
    {
        return StockBalanceForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return StockBalanceInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return StockBalancesTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListStockBalances::route('/'),
            'create' => CreateStockBalance::route('/create'),
            'view' => ViewStockBalance::route('/{record}'),
            'edit' => EditStockBalance::route('/{record}/edit'),
        ];
    }
}