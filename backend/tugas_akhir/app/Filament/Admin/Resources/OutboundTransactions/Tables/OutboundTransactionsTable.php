<?php

namespace App\Filament\Admin\Resources\OutboundTransactions\Tables;

use App\Models\OutboundTransaction;
use App\Services\InventoryApprovalService;
use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Throwable;

class OutboundTransactionsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('transaction_number')
                    ->label('No. Transaksi')
                    ->badge()
                    ->searchable()
                    ->sortable(),

                TextColumn::make('transaction_date')
                    ->label('Tanggal')
                    ->date('d M Y')
                    ->sortable(),

                TextColumn::make('reference_number')
                    ->label('No. Invoice / Keluar')
                    ->searchable()
                    ->placeholder('-'),

                TextColumn::make('outbound_type')
                    ->label('Jenis')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'penjualan' => 'Penjualan',
                        'sample' => 'Sample',
                        'transfer' => 'Transfer',
                        'rusak' => 'Rusak',
                        'lainnya' => 'Lainnya',
                        default => ucfirst($state),
                    }),

                TextColumn::make('customer.name')
                    ->label('Customer / Tujuan')
                    ->searchable()
                    ->placeholder('-'),

                TextColumn::make('warehouse.name')
                    ->label('Gudang')
                    ->badge()
                    ->searchable()
                    ->sortable(),

                TextColumn::make('status')
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
                    })
                    ->sortable(),

                TextColumn::make('grand_total')
                    ->label('Total')
                    ->money('IDR')
                    ->sortable()
                    ->toggleable(),

                TextColumn::make('paid_amount')
                    ->label('Bayar')
                    ->money('IDR')
                    ->toggleable(isToggledHiddenByDefault: true),

                TextColumn::make('remaining_amount')
                    ->label('Sisa')
                    ->money('IDR')
                    ->toggleable(isToggledHiddenByDefault: true),

                TextColumn::make('submittedBy.name')
                    ->label('Dibuat Oleh')
                    ->placeholder('-')
                    ->toggleable(isToggledHiddenByDefault: true),

                TextColumn::make('approvedBy.name')
                    ->label('Approved By')
                    ->placeholder('-')
                    ->toggleable(isToggledHiddenByDefault: true),

                TextColumn::make('approved_at')
                    ->label('Waktu Approve')
                    ->dateTime('d M Y H:i')
                    ->placeholder('-')
                    ->toggleable(isToggledHiddenByDefault: true),

                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->dateTime('d M Y H:i')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Filter::make('transaction_date')
                    ->label('Periode Transaksi')
                    ->form([
                        DatePicker::make('date_from')
                            ->label('Dari Tanggal')
                            ->native(false)
                            ->displayFormat('d M Y'),

                        DatePicker::make('date_until')
                            ->label('Sampai Tanggal')
                            ->native(false)
                            ->displayFormat('d M Y'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                $data['date_from'] ?? null,
                                fn (Builder $query, $date): Builder => $query->whereDate('transaction_date', '>=', $date),
                            )
                            ->when(
                                $data['date_until'] ?? null,
                                fn (Builder $query, $date): Builder => $query->whereDate('transaction_date', '<=', $date),
                            );
                    }),

                SelectFilter::make('status')
                    ->label('Status')
                    ->options([
                        'pending' => 'Pending',
                        'approved' => 'Disetujui',
                        'rejected' => 'Ditolak',
                        'cancelled' => 'Dibatalkan',
                    ]),

                SelectFilter::make('outbound_type')
                    ->label('Jenis Keluar')
                    ->options([
                        'penjualan' => 'Penjualan',
                        'sample' => 'Sample',
                        'transfer' => 'Transfer',
                        'rusak' => 'Rusak',
                        'lainnya' => 'Lainnya',
                    ]),

                SelectFilter::make('warehouse_id')
                    ->label('Gudang')
                    ->relationship('warehouse', 'name')
                    ->searchable()
                    ->preload(),

                SelectFilter::make('customer_id')
                    ->label('Customer')
                    ->relationship('customer', 'name')
                    ->searchable()
                    ->preload(),
            ])
            ->recordActions([
                ViewAction::make()
                    ->label('Lihat'),

                EditAction::make()
                    ->label('Edit')
                    ->visible(fn (OutboundTransaction $record): bool => $record->status === 'pending'),

                Action::make('approve')
                    ->label('Approve')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->modalHeading('Approve Barang Keluar')
                    ->modalDescription('Stok akan berkurang dan mutasi stok OUT akan dibuat setelah transaksi disetujui.')
                    ->visible(fn (OutboundTransaction $record): bool => $record->status === 'pending')
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
                    ->visible(fn (OutboundTransaction $record): bool => $record->status === 'pending')
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
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make()
                        ->label('Hapus Terpilih'),
                ]),
            ])
            ->defaultSort('created_at', 'desc');
    }
}