<?php

namespace App\Filament\Admin\Resources\OutboundTransactions\Schemas;

use App\Models\Product;
use App\Models\StockBalance;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class OutboundTransactionForm
{
    public static function configure(Schema $schema): Schema
    {
        $calculateRootTotals = function (callable $get, callable $set): void {
            $items = $get('items') ?? [];

            $subTotal = collect($items)
                ->sum(fn (array $item): float => (float) ($item['subtotal'] ?? 0));

            $documentDiscount = (float) ($get('discount_amount') ?? 0);
            $vatAmount = (float) ($get('vat_amount') ?? 0);
            $otherCost = (float) ($get('other_cost') ?? 0);
            $paidAmount = (float) ($get('paid_amount') ?? 0);

            $grandTotal = max(0, $subTotal - $documentDiscount + $vatAmount + $otherCost);
            $remainingAmount = max(0, $grandTotal - $paidAmount);

            $set('sub_total', $subTotal);
            $set('grand_total', $grandTotal);
            $set('remaining_amount', $remainingAmount);
        };

        $calculateRepeaterTotals = function (callable $get, callable $set): void {
            $items = $get('../../items') ?? [];

            $subTotal = collect($items)
                ->sum(fn (array $item): float => (float) ($item['subtotal'] ?? 0));

            $documentDiscount = (float) ($get('../../discount_amount') ?? 0);
            $vatAmount = (float) ($get('../../vat_amount') ?? 0);
            $otherCost = (float) ($get('../../other_cost') ?? 0);
            $paidAmount = (float) ($get('../../paid_amount') ?? 0);

            $grandTotal = max(0, $subTotal - $documentDiscount + $vatAmount + $otherCost);
            $remainingAmount = max(0, $grandTotal - $paidAmount);

            $set('../../sub_total', $subTotal);
            $set('../../grand_total', $grandTotal);
            $set('../../remaining_amount', $remainingAmount);
        };

        $calculateItemSubtotal = function (callable $get, callable $set): void {
            $qty = (float) ($get('qty') ?? 0);
            $unitPrice = (float) ($get('unit_price') ?? 0);
            $itemDiscount = (float) ($get('discount_amount') ?? 0);

            $subtotal = max(0, ($qty * $unitPrice) - $itemDiscount);

            $set('subtotal', $subtotal);
        };

        $calculateItemStock = function (callable $get, callable $set): void {
            $productId = $get('product_id');
            $warehouseId = $get('warehouse_id');
            $qty = (float) ($get('qty') ?? 0);

            if (! $productId || ! $warehouseId) {
                $set('stock_before_submit', 0);
                $set('stock_after_submit', 0);

                return;
            }

            $balance = StockBalance::query()
                ->where('product_id', $productId)
                ->where('warehouse_id', $warehouseId)
                ->first();

            $availableStock = $balance
                ? ((float) $balance->qty_on_hand - (float) $balance->qty_reserved)
                : 0;

            $set('stock_before_submit', $availableStock);
            $set('stock_after_submit', max(0, $availableStock - $qty));
        };

        return $schema
            ->components([
                Section::make('Informasi Dokumen Barang Keluar')
                    ->description('Data header barang keluar. Transaksi akan masuk status pending dan perlu approval admin.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('transaction_number')
                                    ->label('No. Transaksi')
                                    ->default(fn (): string => 'BK-' . now()->format('YmdHis'))
                                    ->required()
                                    ->unique(ignoreRecord: true)
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                DatePicker::make('transaction_date')
                                    ->label('Tanggal Barang Keluar')
                                    ->default(now())
                                    ->required()
                                    ->native(false)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('reference_number')
                                    ->label('No. Invoice')
                                    ->default(fn (): string => self::generateReferenceNumber())
                                    ->readOnly()
                                    ->required()
                                    ->dehydrated(true)
                                    ->helperText('Nomor invoice barang keluar dibuat otomatis oleh sistem.')
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                Select::make('outbound_type')
                                    ->label('Jenis Keluar')
                                    ->options([
                                        'penjualan' => 'Penjualan',
                                        'sample' => 'Sample',
                                        'transfer' => 'Transfer',
                                        'rusak' => 'Rusak',
                                        'lainnya' => 'Lainnya',
                                    ])
                                    ->default('penjualan')
                                    ->native(false)
                                    ->required()
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                Select::make('customer_id')
                                    ->label('Customer / Tujuan')
                                    ->relationship('customer', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->placeholder('Pilih customer')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                Select::make('warehouse_id')
                                    ->label('Gudang Asal')
                                    ->relationship('warehouse', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->required()
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('sales_name')
                                    ->label('Sales')
                                    ->placeholder('Nama sales')
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('driver_name')
                                    ->label('Driver')
                                    ->placeholder('Nama driver')
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                DatePicker::make('due_date')
                                    ->label('Tanggal Jatuh Tempo')
                                    ->native(false)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                Select::make('source')
                                    ->label('Sumber Input')
                                    ->options([
                                        'mobile' => 'Mobile App',
                                        'admin' => 'Dashboard Admin',
                                    ])
                                    ->default('admin')
                                    ->native(false)
                                    ->required()
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                Select::make('status')
                                    ->label('Status')
                                    ->options([
                                        'pending' => 'Pending',
                                        'approved' => 'Disetujui',
                                        'rejected' => 'Ditolak',
                                        'cancelled' => 'Dibatalkan',
                                    ])
                                    ->default('pending')
                                    ->native(false)
                                    ->disabled()
                                    ->dehydrated(true)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                Textarea::make('note')
                                    ->label('Catatan')
                                    ->placeholder('Catatan barang keluar...')
                                    ->rows(3)
                                    ->columnSpanFull(),
                            ]),
                    ])
                    ->columnSpanFull(),

                Section::make('Detail Produk Keluar')
                    ->description('Masukkan daftar produk yang keluar. Harga di sini adalah harga jual saat transaksi.')
                    ->schema([
                        Repeater::make('items')
                            ->label('Produk Keluar')
                            ->relationship()
                            ->live()
                            ->afterStateUpdated(function (callable $get, callable $set) use ($calculateRootTotals): void {
                                $calculateRootTotals($get, $set);
                            })
                            ->schema([
                                Grid::make(12)
                                    ->schema([
                                        Select::make('product_id')
                                            ->label('Produk')
                                            ->relationship('product', 'name')
                                            ->searchable()
                                            ->preload()
                                            ->native(false)
                                            ->required()
                                            ->live()
                                            ->afterStateUpdated(function ($state, callable $set, callable $get) use ($calculateItemSubtotal, $calculateItemStock, $calculateRepeaterTotals): void {
                                                $product = Product::query()
                                                    ->with('unit')
                                                    ->find($state);

                                                if (! $product) {
                                                    return;
                                                }

                                                $set('unit_id', $product->unit_id);
                                                $set('product_code_snapshot', $product->code);
                                                $set('product_name_snapshot', $product->full_name ?: $product->name);
                                                $set('unit_name_snapshot', $product->unit?->name);

                                                if ((float) $product->default_selling_price > 0) {
                                                    $set('unit_price', (float) $product->default_selling_price);
                                                }

                                                $calculateItemSubtotal($get, $set);
                                                $calculateItemStock($get, $set);
                                                $calculateRepeaterTotals($get, $set);
                                            })
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 4,
                                            ]),

                                        Select::make('warehouse_id')
                                            ->label('Gudang')
                                            ->relationship('warehouse', 'name')
                                            ->searchable()
                                            ->preload()
                                            ->native(false)
                                            ->required()
                                            ->live()
                                            ->afterStateUpdated(function ($state, callable $set, callable $get) use ($calculateItemStock): void {
                                                $calculateItemStock($get, $set);
                                            })
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 3,
                                            ]),

                                        Select::make('unit_id')
                                            ->label('Satuan')
                                            ->relationship('unit', 'name')
                                            ->searchable()
                                            ->preload()
                                            ->native(false)
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 2,
                                            ]),

                                        TextInput::make('qty')
                                            ->label('Qty Keluar')
                                            ->numeric()
                                            ->minValue(0.01)
                                            ->required()
                                            ->default(1)
                                            ->live(onBlur: true)
                                            ->afterStateUpdated(function ($state, callable $set, callable $get) use ($calculateItemSubtotal, $calculateItemStock, $calculateRepeaterTotals): void {
                                                $calculateItemSubtotal($get, $set);
                                                $calculateItemStock($get, $set);
                                                $calculateRepeaterTotals($get, $set);
                                            })
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 3,
                                            ]),

                                        TextInput::make('unit_price')
                                            ->label('Harga Jual')
                                            ->numeric()
                                            ->prefix('Rp')
                                            ->minValue(0)
                                            ->default(0)
                                            ->required()
                                            ->live(onBlur: true)
                                            ->afterStateUpdated(function ($state, callable $set, callable $get) use ($calculateItemSubtotal, $calculateRepeaterTotals): void {
                                                $calculateItemSubtotal($get, $set);
                                                $calculateRepeaterTotals($get, $set);
                                            })
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 4,
                                            ]),

                                        TextInput::make('discount_amount')
                                            ->label('Diskon Item')
                                            ->numeric()
                                            ->prefix('Rp')
                                            ->minValue(0)
                                            ->default(0)
                                            ->required()
                                            ->live(onBlur: true)
                                            ->afterStateUpdated(function ($state, callable $set, callable $get) use ($calculateItemSubtotal, $calculateRepeaterTotals): void {
                                                $calculateItemSubtotal($get, $set);
                                                $calculateRepeaterTotals($get, $set);
                                            })
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 4,
                                            ]),

                                        TextInput::make('subtotal')
                                            ->label('Subtotal')
                                            ->numeric()
                                            ->prefix('Rp')
                                            ->minValue(0)
                                            ->default(0)
                                            ->required()
                                            ->readOnly()
                                            ->dehydrated(true)
                                            ->helperText('Otomatis dari Qty x Harga Jual - Diskon Item.')
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 4,
                                            ]),

                                        TextInput::make('stock_before_submit')
                                            ->label('Stok Sebelum Submit')
                                            ->numeric()
                                            ->suffix('PCS')
                                            ->default(0)
                                            ->readOnly()
                                            ->dehydrated(true)
                                            ->helperText('Stok tersedia saat transaksi dibuat.')
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 4,
                                            ]),

                                        TextInput::make('stock_after_submit')
                                            ->label('Prediksi Sisa Stok')
                                            ->numeric()
                                            ->suffix('PCS')
                                            ->default(0)
                                            ->readOnly()
                                            ->dehydrated(true)
                                            ->helperText('Prediksi stok tersedia setelah qty keluar.')
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 4,
                                            ]),

                                        TextInput::make('product_code_snapshot')
                                            ->label('Snapshot Kode')
                                            ->maxLength(255)
                                            ->readOnly()
                                            ->dehydrated(true)
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 4,
                                            ]),

                                        TextInput::make('product_name_snapshot')
                                            ->label('Snapshot Nama Produk')
                                            ->maxLength(255)
                                            ->readOnly()
                                            ->dehydrated(true)
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 6,
                                            ]),

                                        TextInput::make('unit_name_snapshot')
                                            ->label('Snapshot Satuan')
                                            ->maxLength(255)
                                            ->readOnly()
                                            ->dehydrated(true)
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 3,
                                            ]),

                                        Textarea::make('note')
                                            ->label('Catatan Detail')
                                            ->rows(2)
                                            ->columnSpanFull(),
                                    ]),
                            ])
                            ->defaultItems(1)
                            ->addActionLabel('Tambah Produk')
                            ->reorderable(false)
                            ->collapsible()
                            ->columnSpanFull(),
                    ])
                    ->columnSpanFull(),

                Section::make('Lampiran Bukti')
                    ->description('Upload bukti barang keluar. Maksimal 3 file, bisa berupa foto atau PDF.')
                    ->schema([
                        Repeater::make('attachments')
                            ->label('Lampiran Barang Keluar')
                            ->relationship()
                            ->schema([
                                FileUpload::make('file_path')
                                    ->label('File Bukti')
                                    ->disk('public')
                                    ->directory('inventory/outbound')
                                    ->acceptedFileTypes([
                                        'image/jpeg',
                                        'image/png',
                                        'image/webp',
                                        'application/pdf',
                                    ])
                                    ->maxSize(4096)
                                    ->downloadable()
                                    ->openable()
                                    ->required(),
                            ])
                            ->mutateRelationshipDataBeforeCreateUsing(function (array $data): array {
                                $data['uploaded_by'] = auth()->id();
                                $data['file_name'] = isset($data['file_path']) ? basename((string) $data['file_path']) : null;

                                return $data;
                            })
                            ->mutateRelationshipDataBeforeSaveUsing(function (array $data): array {
                                $data['uploaded_by'] = $data['uploaded_by'] ?? auth()->id();
                                $data['file_name'] = isset($data['file_path']) ? basename((string) $data['file_path']) : null;

                                return $data;
                            })
                            ->maxItems(3)
                            ->defaultItems(0)
                            ->addActionLabel('Tambah Lampiran')
                            ->reorderable(false)
                            ->grid(3)
                            ->columnSpanFull(),
                    ])
                    ->columnSpanFull(),

                Section::make('Total Dokumen')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('sub_total')
                                    ->label('Sub Total')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->default(0)
                                    ->required()
                                    ->readOnly()
                                    ->dehydrated(true)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 3,
                                    ]),

                                TextInput::make('discount_amount')
                                    ->label('Diskon Dokumen')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->minValue(0)
                                    ->default(0)
                                    ->required()
                                    ->live(onBlur: true)
                                    ->afterStateUpdated(function ($state, callable $get, callable $set) use ($calculateRootTotals): void {
                                        $calculateRootTotals($get, $set);
                                    })
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 3,
                                    ]),

                                TextInput::make('vat_amount')
                                    ->label('VAT Amount')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->minValue(0)
                                    ->default(0)
                                    ->required()
                                    ->live(onBlur: true)
                                    ->afterStateUpdated(function ($state, callable $get, callable $set) use ($calculateRootTotals): void {
                                        $calculateRootTotals($get, $set);
                                    })
                                    ->dehydrated(true)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 3,
                                    ]),

                                TextInput::make('other_cost')
                                    ->label('Biaya Lain')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->minValue(0)
                                    ->default(0)
                                    ->required()
                                    ->live(onBlur: true)
                                    ->afterStateUpdated(function ($state, callable $get, callable $set) use ($calculateRootTotals): void {
                                        $calculateRootTotals($get, $set);
                                    })
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 3,
                                    ]),

                                TextInput::make('grand_total')
                                    ->label('Grand Total')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->default(0)
                                    ->required()
                                    ->readOnly()
                                    ->dehydrated(true)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('paid_amount')
                                    ->label('Bayar')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->minValue(0)
                                    ->default(0)
                                    ->required()
                                    ->live(onBlur: true)
                                    ->afterStateUpdated(function ($state, callable $get, callable $set) use ($calculateRootTotals): void {
                                        $calculateRootTotals($get, $set);
                                    })
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('remaining_amount')
                                    ->label('Sisa Pembayaran')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->default(0)
                                    ->required()
                                    ->readOnly()
                                    ->dehydrated(true)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }

    private static function generateReferenceNumber(): string
    {
        $prefix = 'INV-NAURA';
        $date = now()->format('ymd');

        $lastReferenceNumber = \App\Models\OutboundTransaction::query()
            ->where('reference_number', 'like', "{$prefix}{$date}%")
            ->orderByDesc('reference_number')
            ->value('reference_number');

        $nextSequence = 1;

        if ($lastReferenceNumber) {
            $lastSequence = (int) substr($lastReferenceNumber, -5);
            $nextSequence = $lastSequence + 1;
        }

        return $prefix . $date . str_pad((string) $nextSequence, 5, '0', STR_PAD_LEFT);
    }
}