<?php

namespace App\Filament\Admin\Widgets;

use App\Models\InboundTransaction;
use App\Services\InventoryApprovalService;
use Filament\Actions\Action;
use Filament\Forms\Components\Textarea;
use Filament\Notifications\Notification;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;
use Throwable;

class PendingInboundApprovalWidget extends TableWidget
{
    protected static ?string $heading = 'Barang Masuk Menunggu Approval';

    protected static ?int $sort = 4;

    protected int|string|array $columnSpan = 'full';

    public static function canView(): bool
    {
        return true;
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(
                InboundTransaction::query()
                    ->with(['supplier', 'warehouse', 'submittedBy'])
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

                TextColumn::make('invoice_number')
                    ->label('No. Invoice')
                    ->placeholder('-')
                    ->searchable(),

                TextColumn::make('supplier.name')
                    ->label('Supplier')
                    ->placeholder('-')
                    ->searchable(),

                TextColumn::make('warehouse.name')
                    ->label('Gudang')
                    ->badge()
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
                    ->modalHeading('Approve Barang Masuk')
                    ->modalDescription('Stok akan bertambah dan mutasi stok IN akan dibuat.')
                    ->action(function (InboundTransaction $record): void {
                        try {
                            app(InventoryApprovalService::class)->approveInbound($record);

                            Notification::make()
                                ->title('Barang masuk berhasil di-approve')
                                ->success()
                                ->send();
                        } catch (Throwable $e) {
                            Notification::make()
                                ->title('Gagal approve barang masuk')
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
                    ->action(function (InboundTransaction $record, array $data): void {
                        try {
                            app(InventoryApprovalService::class)->rejectInbound($record, $data['reason']);

                            Notification::make()
                                ->title('Barang masuk berhasil ditolak')
                                ->danger()
                                ->send();
                        } catch (Throwable $e) {
                            Notification::make()
                                ->title('Gagal reject barang masuk')
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
