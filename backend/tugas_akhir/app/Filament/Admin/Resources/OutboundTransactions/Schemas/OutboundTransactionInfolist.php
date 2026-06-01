<?php

namespace App\Filament\Admin\Resources\OutboundTransactions\Schemas;

use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Schema;

class OutboundTransactionInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextEntry::make('transaction_number'),
                TextEntry::make('transaction_date')
                    ->date(),
                TextEntry::make('outbound_type'),
                TextEntry::make('reference_number')
                    ->placeholder('-'),
                TextEntry::make('customer.name')
                    ->label('Customer')
                    ->placeholder('-'),
                TextEntry::make('warehouse.name')
                    ->label('Warehouse'),
                TextEntry::make('sales_name')
                    ->placeholder('-'),
                TextEntry::make('driver_name')
                    ->placeholder('-'),
                TextEntry::make('due_date')
                    ->date()
                    ->placeholder('-'),
                TextEntry::make('note')
                    ->placeholder('-')
                    ->columnSpanFull(),
                TextEntry::make('status'),
                TextEntry::make('sub_total')
                    ->numeric(),
                TextEntry::make('discount_amount')
                    ->numeric(),
                TextEntry::make('vat_percent')
                    ->numeric(),
                TextEntry::make('vat_amount')
                    ->numeric(),
                TextEntry::make('other_cost')
                    ->numeric(),
                TextEntry::make('grand_total')
                    ->numeric(),
                TextEntry::make('paid_amount')
                    ->numeric(),
                TextEntry::make('remaining_amount')
                    ->numeric(),
                TextEntry::make('submitted_by')
                    ->numeric()
                    ->placeholder('-'),
                TextEntry::make('submitted_at')
                    ->dateTime()
                    ->placeholder('-'),
                TextEntry::make('approved_by')
                    ->numeric()
                    ->placeholder('-'),
                TextEntry::make('approved_at')
                    ->dateTime()
                    ->placeholder('-'),
                TextEntry::make('rejected_by')
                    ->numeric()
                    ->placeholder('-'),
                TextEntry::make('rejected_at')
                    ->dateTime()
                    ->placeholder('-'),
                TextEntry::make('rejection_reason')
                    ->placeholder('-')
                    ->columnSpanFull(),
                TextEntry::make('approval_note')
                    ->placeholder('-')
                    ->columnSpanFull(),
                TextEntry::make('source'),
                TextEntry::make('created_at')
                    ->dateTime()
                    ->placeholder('-'),
                TextEntry::make('updated_at')
                    ->dateTime()
                    ->placeholder('-'),
            ]);
    }
}
