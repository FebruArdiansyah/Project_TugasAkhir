<?php

namespace App\Filament\Admin\Resources\InboundTransactions\Schemas;

use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class InboundTransactionInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Barang Masuk')
                    ->schema([
                        Grid::make(3)
                            ->schema([
                                TextEntry::make('transaction_number')
                                    ->label('No. Transaksi')
                                    ->badge(),

                                TextEntry::make('transaction_date')
                                    ->label('Tanggal')
                                    ->date('d M Y'),

                                TextEntry::make('invoice_number')
                                    ->label('No. Invoice')
                                    ->placeholder('-'),

                                TextEntry::make('supplier.name')
                                    ->label('Supplier')
                                    ->placeholder('-'),

                                TextEntry::make('warehouse.name')
                                    ->label('Gudang Tujuan')
                                    ->badge(),

                                TextEntry::make('status')
                                    ->label('Status')
                                    ->badge()
                                    ->formatStateUsing(fn (string $state): string => match ($state) {
                                        'pending' => 'Pending',
                                        'approved' => 'Disetujui',
                                        'rejected' => 'Ditolak',
                                        'cancelled' => 'Dibatalkan',
                                        default => ucfirst($state),
                                    })
                                    ->color(fn (string $state): string => match ($state) {
                                        'pending' => 'warning',
                                        'approved' => 'success',
                                        'rejected' => 'danger',
                                        'cancelled' => 'gray',
                                        default => 'gray',
                                    }),
                            ]),

                        TextEntry::make('note')
                            ->label('Catatan')
                            ->placeholder('-')
                            ->columnSpanFull(),
                    ]),

                Section::make('Total Dokumen')
                    ->schema([
                        Grid::make(4)
                            ->schema([
                                TextEntry::make('sub_total')
                                    ->label('Sub Total')
                                    ->money('IDR'),

                                TextEntry::make('discount_amount')
                                    ->label('Diskon')
                                    ->money('IDR'),

                                TextEntry::make('other_cost')
                                    ->label('Biaya Lain')
                                    ->money('IDR'),

                                TextEntry::make('grand_total')
                                    ->label('Grand Total')
                                    ->money('IDR')
                                    ->weight('bold'),
                            ]),
                    ]),

                Section::make('Informasi Approval')
                    ->schema([
                        Grid::make(3)
                            ->schema([
                                TextEntry::make('submittedBy.name')
                                    ->label('Submitted By')
                                    ->placeholder('-'),

                                TextEntry::make('approvedBy.name')
                                    ->label('Approved By')
                                    ->placeholder('-'),

                                TextEntry::make('approved_at')
                                    ->label('Approved At')
                                    ->dateTime('d M Y H:i')
                                    ->placeholder('-'),

                                TextEntry::make('rejectedBy.name')
                                    ->label('Rejected By')
                                    ->placeholder('-'),

                                TextEntry::make('rejected_at')
                                    ->label('Rejected At')
                                    ->dateTime('d M Y H:i')
                                    ->placeholder('-'),

                                TextEntry::make('rejection_reason')
                                    ->label('Alasan Reject')
                                    ->placeholder('-'),
                            ]),
                    ])
                    ->collapsible(),
            ]);
    }
}