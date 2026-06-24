<?php

namespace App\Filament\Admin\Resources\InboundTransactions\Schemas;

use App\Models\Product;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class InboundTransactionForm
{
    public static function configure(Schema $schema): Schema
    {
        $calculateRootTotals = function (callable $get, callable $set): void {
            $items = $get('items') ?? [];

            $subTotal = collect($items)
                ->sum(fn (array $item): float => (float) ($item['subtotal'] ?? 0));

            $discount = (float) ($get('discount_amount') ?? 0);
            $otherCost = (float) ($get('other_cost') ?? 0);

            $grandTotal = max(0, $subTotal - $discount + $otherCost);

            $set('sub_total', $subTotal);
            $set('grand_total', $grandTotal);
        };

        $calculateRepeaterTotals = function (callable $get, callable $set): void {
            $items = $get('../../items') ?? [];

            $subTotal = collect($items)
                ->sum(fn (array $item): float => (float) ($item['subtotal'] ?? 0));

            $discount = (float) ($get('../../discount_amount') ?? 0);
            $otherCost = (float) ($get('../../other_cost') ?? 0);

            $grandTotal = max(0, $subTotal - $discount + $otherCost);

            $set('../../sub_total', $subTotal);
            $set('../../grand_total', $grandTotal);
        };

        return $schema
            ->components([
                Section::make('Informasi Dokumen Barang Masuk')
                    ->description('Data header barang masuk. Transaksi yang dibuat akan masuk status pending dan perlu approval admin.')
                    ->schema([
                        Grid::make(12)
                            ->schema([
                                TextInput::make('transaction_number')
                                    ->label('No. Transaksi')
                                    ->default(fn (): string => 'BM-' . now()->format('YmdHis'))
                                    ->required()
                                    ->unique(ignoreRecord: true)
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                DatePicker::make('transaction_date')
                                    ->label('Tanggal Barang Masuk')
                                    ->default(now())
                                    ->required()
                                    ->native(false)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                TextInput::make('invoice_number')
                                    ->label('No. Invoice')
                                    ->default(fn (): string => self::generateInvoiceNumber())
                                    ->readOnly()
                                    ->required()
                                    ->dehydrated(true)
                                    ->helperText('Nomor invoice dibuat otomatis oleh sistem.')
                                    ->maxLength(255)
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 4,
                                    ]),

                                Select::make('supplier_id')
                                    ->label('Supplier')
                                    ->relationship('supplier', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->placeholder('Pilih supplier')
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
                                    ]),

                                Select::make('warehouse_id')
                                    ->label('Gudang Tujuan')
                                    ->relationship('warehouse', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->native(false)
                                    ->required()
                                    ->columnSpan([
                                        'default' => 12,
                                        'md' => 6,
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
                                    ->placeholder('Catatan barang masuk...')
                                    ->rows(3)
                                    ->columnSpanFull(),
                            ]),
                    ])
                    ->columnSpanFull(),

                Section::make('Detail Produk Masuk')
                    ->description('Masukkan daftar produk yang diterima. Harga di sini adalah harga beli saat transaksi.')
                    ->schema([
                        Repeater::make('items')
                            ->label('Produk Masuk')
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
                                            ->afterStateUpdated(function ($state, callable $set, callable $get) use ($calculateRepeaterTotals): void {
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

                                                if ((float) $product->default_purchase_price > 0) {
                                                    $qty = (float) ($get('qty') ?? 1);
                                                    $unitCost = (float) $product->default_purchase_price;

                                                    $set('unit_cost', $unitCost);
                                                    $set('subtotal', $qty * $unitCost);
                                                }

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
                                            ->label('Qty')
                                            ->numeric()
                                            ->minValue(0.01)
                                            ->required()
                                            ->default(1)
                                            ->live(onBlur: true)
                                            ->afterStateUpdated(function ($state, callable $set, callable $get) use ($calculateRepeaterTotals): void {
                                                $qty = (float) ($get('qty') ?? 0);
                                                $unitCost = (float) ($get('unit_cost') ?? 0);

                                                $set('subtotal', $qty * $unitCost);

                                                $calculateRepeaterTotals($get, $set);
                                            })
                                            ->columnSpan([
                                                'default' => 12,
                                                'md' => 3,
                                            ]),

                                        TextInput::make('unit_cost')
                                            ->label('Harga Beli')
                                            ->numeric()
                                            ->prefix('Rp')
                                            ->minValue(0)
                                            ->default(0)
                                            ->required()
                                            ->live(onBlur: true)
                                            ->afterStateUpdated(function ($state, callable $set, callable $get) use ($calculateRepeaterTotals): void {
                                                $qty = (float) ($get('qty') ?? 0);
                                                $unitCost = (float) ($get('unit_cost') ?? 0);

                                                $set('subtotal', $qty * $unitCost);

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
                                            ->helperText('Otomatis dari Qty x Harga Beli.')
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
                    ->description('Upload bukti barang masuk. Maksimal 3 file, bisa berupa foto atau PDF.')
                    ->schema([
                        Repeater::make('attachments')
                            ->label('Lampiran Barang Masuk')
                            ->relationship()
                            ->schema([
                                FileUpload::make('file_path')
                                    ->label('File Bukti')
                                    ->disk('public')
                                    ->directory('inventory/inbound')
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
                                    ->label('Diskon')
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
                                        'md' => 3,
                                    ]),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }

    private static function generateInvoiceNumber(): string
{
    $date = now()->format('Ymd');

    $lastInvoiceNumber = \App\Models\InboundTransaction::query()
        ->where('invoice_number', 'like', "INV-IN-{$date}-%")
        ->orderByDesc('invoice_number')
        ->value('invoice_number');

    $nextSequence = 1;

    if ($lastInvoiceNumber) {
        $lastSequence = (int) substr($lastInvoiceNumber, -4);
        $nextSequence = $lastSequence + 1;
    }

    return 'INV-IN-' . $date . '-' . str_pad((string) $nextSequence, 4, '0', STR_PAD_LEFT);
}
}