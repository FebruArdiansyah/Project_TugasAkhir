<?php

namespace App\Filament\Admin\Resources\OutboundTransactions\Schemas;

use Filament\Infolists\Components\RepeatableEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class OutboundTransactionInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Ringkasan Barang Keluar')
                    ->description('Informasi utama transaksi barang keluar.')
                    ->icon('heroicon-o-arrow-up-tray')
                    ->schema([
                        Grid::make(3)
                            ->schema([
                                TextEntry::make('transaction_number')
                                    ->label('No. Transaksi')
                                    ->badge()
                                    ->color('primary')
                                    ->copyable(),

                                TextEntry::make('transaction_date')
                                    ->label('Tanggal Transaksi')
                                    ->date('d M Y'),

                                TextEntry::make('status')
                                    ->label('Status')
                                    ->badge()
                                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                                        'pending' => 'Pending',
                                        'approved' => 'Disetujui',
                                        'rejected' => 'Ditolak',
                                        'cancelled' => 'Dibatalkan',
                                        default => $state ? ucfirst($state) : '-',
                                    })
                                    ->color(fn (?string $state): string => match ($state) {
                                        'pending' => 'warning',
                                        'approved' => 'success',
                                        'rejected' => 'danger',
                                        'cancelled' => 'gray',
                                        default => 'gray',
                                    }),
                            ]),
                    ])
                    ->collapsible(),

                Section::make('Informasi Transaksi')
                    ->description('Detail tujuan, gudang, dan referensi transaksi.')
                    ->icon('heroicon-o-document-text')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('outbound_type')
                                    ->label('Jenis Barang Keluar')
                                    ->badge()
                                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                                        'penjualan' => 'Penjualan',
                                        'sample' => 'Sample',
                                        'transfer' => 'Transfer',
                                        'rusak' => 'Rusak',
                                        'lainnya' => 'Lainnya',
                                        default => $state ? ucfirst($state) : '-',
                                    })
                                    ->color('info'),

                                TextEntry::make('reference_number')
                                    ->label('No. Invoice / Referensi')
                                    ->placeholder('-')
                                    ->copyable(),

                                TextEntry::make('customer.name')
                                    ->label('Customer / Tujuan')
                                    ->placeholder('-'),

                                TextEntry::make('warehouse.name')
                                    ->label('Gudang')
                                    ->badge()
                                    ->color('primary')
                                    ->placeholder('-'),

                                TextEntry::make('sales_name')
                                    ->label('Nama Sales')
                                    ->placeholder('-'),

                                TextEntry::make('driver_name')
                                    ->label('Nama Driver')
                                    ->placeholder('-'),

                                TextEntry::make('due_date')
                                    ->label('Tanggal Jatuh Tempo')
                                    ->date('d M Y')
                                    ->placeholder('-'),

                                TextEntry::make('source')
                                    ->label('Sumber Data')
                                    ->badge()
                                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                                        'import_excel' => 'Import Excel',
                                        'import_database' => 'Import Database',
                                        'manual' => 'Input Manual',
                                        default => $state ? ucfirst(str_replace('_', ' ', $state)) : '-',
                                    })
                                    ->color('gray')
                                    ->placeholder('-'),
                            ]),
                    ])
                    ->collapsible(),

                Section::make('Detail Nilai Transaksi')
                    ->description('Rincian nilai transaksi barang keluar.')
                    ->icon('heroicon-o-banknotes')
                    ->schema([
                        Grid::make(3)
                            ->schema([
                                TextEntry::make('sub_total')
                                    ->label('Sub Total')
                                    ->money('IDR'),

                                TextEntry::make('discount_amount')
                                    ->label('Diskon')
                                    ->money('IDR'),

                                TextEntry::make('vat_percent')
                                    ->label('PPN (%)')
                                    ->suffix('%'),

                                TextEntry::make('vat_amount')
                                    ->label('Nilai PPN')
                                    ->money('IDR'),

                                TextEntry::make('other_cost')
                                    ->label('Biaya Lain')
                                    ->money('IDR'),

                                TextEntry::make('grand_total')
                                    ->label('Grand Total')
                                    ->money('IDR')
                                    ->weight('bold')
                                    ->color('success'),

                                TextEntry::make('paid_amount')
                                    ->label('Sudah Dibayar')
                                    ->money('IDR'),

                                TextEntry::make('remaining_amount')
                                    ->label('Sisa Pembayaran')
                                    ->money('IDR')
                                    ->color('warning'),
                            ]),
                    ])
                    ->collapsible(),

                Section::make('Detail Barang')
                    ->description('Daftar item barang yang keluar pada transaksi ini.')
                    ->icon('heroicon-o-archive-box')
                    ->schema([
                        RepeatableEntry::make('items')
                            ->label('')
                            ->schema([
                                Grid::make(5)
                                    ->schema([
                                        TextEntry::make('product.name')
                                            ->label('Produk')
                                            ->placeholder('-')
                                            ->columnSpan(2),

                                        TextEntry::make('qty')
                                            ->label('Qty')
                                            ->numeric(decimalPlaces: 0)
                                            ->suffix(' PCS'),

                                        TextEntry::make('unit_price')
                                            ->label('Harga')
                                            ->money('IDR'),

                                        TextEntry::make('subtotal')
                                            ->label('Subtotal')
                                            ->money('IDR')
                                            ->weight('bold'),
                                    ]),
                            ])
                            ->contained(false),
                    ])
                    ->collapsible(),

                Section::make('Catatan dan Approval')
                    ->description('Informasi catatan, pembuat, dan approval transaksi.')
                    ->icon('heroicon-o-check-badge')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextEntry::make('note')
                                    ->label('Catatan')
                                    ->placeholder('-')
                                    ->columnSpanFull(),

                                TextEntry::make('submittedBy.name')
                                    ->label('Dibuat Oleh')
                                    ->placeholder('-'),

                                TextEntry::make('submitted_at')
                                    ->label('Waktu Submit')
                                    ->dateTime('d M Y H:i')
                                    ->placeholder('-'),

                                TextEntry::make('approvedBy.name')
                                    ->label('Disetujui Oleh')
                                    ->placeholder('-'),

                                TextEntry::make('approved_at')
                                    ->label('Waktu Disetujui')
                                    ->dateTime('d M Y H:i')
                                    ->placeholder('-'),

                                TextEntry::make('approval_note')
                                    ->label('Catatan Approval')
                                    ->placeholder('-')
                                    ->columnSpanFull(),
                            ]),
                    ])
                    ->collapsible(),
            ]);
    }
}