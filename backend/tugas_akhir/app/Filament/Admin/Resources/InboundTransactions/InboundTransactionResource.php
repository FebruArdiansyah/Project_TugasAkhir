<?php

namespace App\Filament\Admin\Resources\InboundTransactions;

use App\Filament\Admin\Resources\InboundTransactions\Pages\CreateInboundTransaction;
use App\Filament\Admin\Resources\InboundTransactions\Pages\EditInboundTransaction;
use App\Filament\Admin\Resources\InboundTransactions\Pages\ListInboundTransactions;
use App\Filament\Admin\Resources\InboundTransactions\Pages\ViewInboundTransaction;
use App\Filament\Admin\Resources\InboundTransactions\Schemas\InboundTransactionForm;
use App\Filament\Admin\Resources\InboundTransactions\Schemas\InboundTransactionInfolist;
use App\Filament\Admin\Resources\InboundTransactions\Tables\InboundTransactionsTable;
use App\Models\InboundTransaction;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class InboundTransactionResource extends Resource
{
    protected static ?string $model = InboundTransaction::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedArrowDownTray;

    protected static ?string $navigationLabel = 'Barang Masuk';

    protected static ?string $modelLabel = 'Barang Masuk';

    protected static ?string $pluralModelLabel = 'Barang Masuk';

    protected static string|\UnitEnum|null $navigationGroup = 'Transaksi Inventory';

    protected static ?int $navigationSort = 10;

    protected static ?string $recordTitleAttribute = 'transaction_number';

    public static function form(Schema $schema): Schema
    {
        return InboundTransactionForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return InboundTransactionInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return InboundTransactionsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListInboundTransactions::route('/'),
            'create' => CreateInboundTransaction::route('/create'),
            'view' => ViewInboundTransaction::route('/{record}'),
            'edit' => EditInboundTransaction::route('/{record}/edit'),
        ];
    }
}