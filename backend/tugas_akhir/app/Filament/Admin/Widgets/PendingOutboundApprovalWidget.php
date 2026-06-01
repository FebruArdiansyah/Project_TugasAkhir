<?php

namespace App\Filament\Admin\Widgets;

use App\Models\OutboundTransaction;
use App\Services\InventoryApprovalService;
use Filament\Actions\Action;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;
use Throwable;

class PendingOutboundApprovalWidget extends TableWidget
{
    protected static ?string $heading = 'Barang Keluar Menunggu Approval';

    protected static ?int $sort = 5;

    protected int|string|array $columnSpan = 'full';

    public static function canView(): bool
    {
        return true;
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(
                OutboundTransaction::query()
                    ->with(['customer', 'warehouse', 'submittedBy'])
                    ->where('status', 'pending')
                    ->latest()
            )
            ->columns([
                TextColumn::make('transaction_number')
                    ->label('No. Transaksi')
                    ->badge()
                    ->searchable(),

                TextColumn::make('transaction_date')
                    ->label('Tanggal')
                    ->date('d M Y')
                    ->sortable(),

                TextColumn::make('reference_number')
                    ->label('No. Invoice / Keluar')
                    ->placeholder('-')
                    ->searchable(),

                TextColumn::make('outbound_type')
                    ->label('Jenis')
                    ->badge()
                    ->formatStateUsing(fn (?string $state): string => match ($state) {
                        'penjualan' => 'Penjualan',
                        'sample' => 'Sample',
                        'transfer' => 'Transfer',
                        'rusak' => 'Rusak',
                        'lainnya' => 'Lainnya',
                        default => $state ? ucfirst($state) : '-',
                    })
                    ->color(fn (?string $state): string => match ($state) {
                        'penjualan' => 'success',
                        'sample' => 'info',
                        'transfer' => 'warning',
                        'rusak' => 'danger',
                        'lainnya' => 'gray',
                        default => 'gray',
                    }),

                TextColumn::make('customer.name')
                    ->label('Customer / Tujuan')
                    ->placeholder('-')
                    ->searchable(),

                TextColumn::make('warehouse.name')
                    ->label('Gudang')
                    ->badge()
                    ->placeholder('-')
                    ->searchable(),

                TextColumn::make('grand_total')
                    ->label('Total')
                    ->money('IDR')
                    ->sortable(),

                TextColumn::make('submittedBy.name')
                    ->label('Dibuat Oleh')
                    ->placeholder('-'),

                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->dateTime('d M Y H:i')
                    ->sortable(),
            ])
            ->recordActions([
                Action::make('approve')
                    ->label('Approve')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalHeading('Approve Barang Keluar')
                    ->modalDescription('Stok akan berkurang dan mutasi stok OUT akan dibuat.')
                    ->action(function (OutboundTransaction $record): void {
                        try {
                            app(InventoryApprovalService::class)->approveOutbound($record);

                            Notification::make()
                                ->title('Barang keluar berhasil di-approve')
                                ->success()
                                ->send();
                        } catch (Throwable $e) {
                            Notification::make()
                                ->title('Gagal approve barang keluar')
                                ->body($e->getMessage())
                                ->danger()
                                ->send();
                        }
                    }),

                Action::make('reject')
                    ->label('Reject')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->form([
                        Textarea::make('reason')
                            ->label('Alasan Reject')
                            ->required()
                            ->rows(4),
                    ])
                    ->action(function (OutboundTransaction $record, array $data): void {
                        try {
                            app(InventoryApprovalService::class)->rejectOutbound($record, $data['reason']);

                            Notification::make()
                                ->title('Barang keluar berhasil ditolak')
                                ->danger()
                                ->send();
                        } catch (Throwable $e) {
                            Notification::make()
                                ->title('Gagal reject barang keluar')
                                ->body($e->getMessage())
                                ->danger()
                                ->send();
                        }
                    }),
            ])
            ->paginated([5, 10, 25])
            ->defaultPaginationPageOption(5);
    }
}