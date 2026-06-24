<?php

namespace App\Filament\Admin\Pages;

use App\Jobs\ProcessInventoryImportJob;
use App\Models\InventoryImportLog;
use App\Models\Warehouse;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Illuminate\Support\Facades\Storage;
use Livewire\Features\SupportFileUploads\TemporaryUploadedFile;
use Throwable;

class ImportInventoryData extends Page implements HasForms
{
    use InteractsWithForms;

    protected static \BackedEnum|string|null $navigationIcon = 'heroicon-o-arrow-up-tray';

    protected static \UnitEnum|string|null $navigationGroup = 'Transaksi Inventory';

    protected static ?int $navigationSort = 3;

    protected static ?string $navigationLabel = 'Import Data Inventory';

    protected static ?string $title = 'Import Data Inventory';

    protected string $view = 'filament.admin.pages.import-inventory-data';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'source_type' => 'excel',
            'transaction_type' => 'outbound',
            'import_mode' => 'historical',
            'status_after_import' => 'approved',
            'update_stock' => false,
            'db_port' => '3306',
        ]);
    }

    public function form(Schema $schema): Schema
    {
        return $schema
            ->schema([
                Section::make('Konfigurasi Import Inventory')
                    ->description('Import data inventory dari Excel, database lain, atau API eksternal.')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                Select::make('source_type')
                                    ->label('Sumber Data')
                                    ->options([
                                        'excel' => 'Excel',
                                        'database' => 'Database Lain',
                                        'api' => 'API Eksternal',
                                    ])
                                    ->live()
                                    ->required(),

                                Select::make('transaction_type')
                                    ->label('Jenis Transaksi')
                                    ->options([
                                        'inbound' => 'Barang Masuk',
                                        'outbound' => 'Barang Keluar',
                                    ])
                                    ->required(),

                                Select::make('import_mode')
                                    ->label('Mode Import')
                                    ->options([
                                        'historical' => 'Histori Lama',
                                        'operational' => 'Operasional Baru',
                                    ])
                                    ->live()
                                    ->required(),

                                Select::make('status_after_import')
                                    ->label('Status Setelah Import')
                                    ->options([
                                        'pending' => 'Pending',
                                        'approved' => 'Approved',
                                    ])
                                    ->default('approved')
                                    ->required(),

                                Select::make('warehouse_id')
                                    ->label('Gudang')
                                    ->options(fn () => Warehouse::query()
                                        ->orderBy('name')
                                        ->pluck('name', 'id')
                                        ->toArray())
                                    ->searchable()
                                    ->preload()
                                    ->required(),

                                Toggle::make('update_stock')
                                    ->label('Update Stok Operasional')
                                    ->helperText('Untuk data histori lama sebaiknya OFF agar stok sekarang tidak berubah.')
                                    ->default(false),
                            ]),
                    ]),

                Section::make('Import dari Excel')
                    ->description('Digunakan untuk upload file Excel transaksi barang masuk atau barang keluar.')
                    ->visible(fn (callable $get): bool => $get('source_type') === 'excel')
                    ->schema([
                        FileUpload::make('excel_file')
                            ->label('File Excel')
                            ->disk('local')
                            ->directory('imports/inventory')
                            ->preserveFilenames()
                            ->multiple(false)
                            ->dehydrated(true)
                            ->acceptedFileTypes([
                                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                'application/vnd.ms-excel',
                            ])
                            ->maxSize(51200)
                            ->required(fn (callable $get): bool => $get('source_type') === 'excel'),
                    ]),

                Section::make('Import dari Database Lain')
                    ->description('Digunakan jika sumber data berasal dari database lain, misalnya MySQL eksternal.')
                    ->visible(fn (callable $get): bool => $get('source_type') === 'database')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                TextInput::make('db_host')
                                    ->label('Host')
                                    ->placeholder('mysql / mariadb / host.docker.internal / 192.168.1.10')
                                    ->required(fn (callable $get): bool => $get('source_type') === 'database'),

                                TextInput::make('db_port')
                                    ->label('Port')
                                    ->default('3306')
                                    ->required(fn (callable $get): bool => $get('source_type') === 'database'),

                                TextInput::make('db_name')
                                    ->label('Database Name')
                                    ->placeholder('db_invoice_lama')
                                    ->required(fn (callable $get): bool => $get('source_type') === 'database'),

                                TextInput::make('db_username')
                                    ->label('Username')
                                    ->required(fn (callable $get): bool => $get('source_type') === 'database'),

                                TextInput::make('db_password')
                                    ->label('Password')
                                    ->password()
                                    ->revealable(),

                                TextInput::make('db_table')
                                    ->label('Nama Tabel / View')
                                    ->placeholder('invoice_masuk_external'),
                            ]),

                        Textarea::make('db_query')
                            ->label('Query SQL Opsional')
                            ->placeholder('SELECT * FROM invoice_masuk_external WHERE tanggal BETWEEN "2025-12-01" AND "2025-12-31"')
                            ->rows(4),
                    ]),

                Section::make('Import dari API')
                    ->description('Digunakan jika sumber data berasal dari endpoint API eksternal.')
                    ->visible(fn (callable $get): bool => $get('source_type') === 'api')
                    ->schema([
                        TextInput::make('api_url')
                            ->label('URL API')
                            ->placeholder('https://example.com/api/invoices'),

                        TextInput::make('api_token')
                            ->label('Token API')
                            ->password()
                            ->revealable(),

                        Textarea::make('api_payload')
                            ->label('Payload / Parameter Opsional')
                            ->rows(4)
                            ->placeholder('{"start_date": "2025-12-01", "end_date": "2025-12-31"}'),
                    ]),
            ])
            ->statePath('data');
    }

    public function import(): void
    {
        try {
            $state = $this->form->getState();
        } catch (Throwable) {
            $state = $this->data ?? [];
        }

        $state = array_replace($this->data ?? [], $state ?? []);

        $state['source_type'] = $state['source_type'] ?? 'excel';
        $state['transaction_type'] = $state['transaction_type'] ?? 'outbound';
        $state['import_mode'] = $state['import_mode'] ?? 'historical';
        $state['status_after_import'] = $state['status_after_import'] ?? 'approved';
        $state['update_stock'] = $state['update_stock'] ?? false;
        $state['user_id'] = auth()->id() ?: 1;

        if (($state['import_mode'] ?? 'historical') === 'historical' && ! empty($state['update_stock'])) {
            Notification::make()
                ->title('Mode histori tidak boleh update stok')
                ->body('Untuk data lama/histori, update stok operasional harus dimatikan agar stok saat ini tidak berubah.')
                ->danger()
                ->send();

            return;
        }

        if (($state['source_type'] ?? 'excel') === 'api') {
            Notification::make()
                ->title('Import API belum tersedia')
                ->body('Saat ini import API eksternal belum dibuat. Gunakan Excel atau Database Lain terlebih dahulu.')
                ->warning()
                ->send();

            return;
        }

        $excelFile = '';

        if (($state['source_type'] ?? 'excel') === 'excel') {
            $excelFile = $this->resolveExcelFile($state['excel_file'] ?? null);

            if (! $excelFile) {
                $excelFile = $this->findLatestUploadedExcelPath();
            }

            if (! $excelFile) {
                Notification::make()
                    ->title('File Excel belum dipilih')
                    ->body('Silakan upload ulang file Excel sampai status upload selesai.')
                    ->danger()
                    ->send();

                return;
            }

            $state['excel_file'] = $excelFile;
        }

        if (($state['source_type'] ?? 'excel') === 'database') {
            $state = $this->normalizeDatabaseState($state);

            $dbTable = trim((string) ($state['db_table'] ?? ''));
            $dbQuery = trim((string) ($state['db_query'] ?? ''));

            if ($dbTable === '' && $dbQuery === '') {
                Notification::make()
                    ->title('Tabel atau query belum diisi')
                    ->body('Isi Nama Tabel / View atau Query SQL Opsional untuk import dari database lain.')
                    ->danger()
                    ->send();

                return;
            }
        }

        $log = InventoryImportLog::create([
            'file_name' => $this->makeImportFileName($state, $excelFile),
            'transaction_type' => $state['transaction_type'],
            'import_mode' => $state['import_mode'],
            'warehouse_id' => $state['warehouse_id'] ?? null,
            'status' => 'processing',
            'message' => 'Import masuk antrean queue dan sedang menunggu diproses.',
            'imported_by' => $state['user_id'],
            'started_at' => now(),
        ]);

        ProcessInventoryImportJob::dispatch(
            $log->id,
            (string) $excelFile,
            $state
        );

        Notification::make()
            ->title('Import sedang diproses')
            ->body('Data sudah masuk antrean queue. Silakan cek Log Import Inventory beberapa saat lagi.')
            ->success()
            ->send();

        $this->form->fill([
            'source_type' => 'excel',
            'transaction_type' => 'outbound',
            'import_mode' => 'historical',
            'status_after_import' => 'approved',
            'update_stock' => false,
            'db_port' => '3306',
        ]);
    }

    private function normalizeDatabaseState(array $state): array
    {
        $state['host'] = $state['db_host'] ?? $state['host'] ?? null;
        $state['port'] = $state['db_port'] ?? $state['port'] ?? 3306;
        $state['database_name'] = $state['db_name'] ?? $state['database_name'] ?? null;
        $state['username'] = $state['db_username'] ?? $state['username'] ?? null;
        $state['password'] = $state['db_password'] ?? $state['password'] ?? null;
        $state['table_name'] = $state['db_table'] ?? $state['table_name'] ?? null;

        if (! empty($state['db_query'])) {
            $state['query'] = $state['db_query'];
        }

        return $state;
    }

    private function makeImportFileName(array $state, ?string $excelFile = null): string
    {
        if (($state['source_type'] ?? 'excel') === 'database') {
            $table = $state['db_table'] ?? $state['table_name'] ?? 'query';
            $database = $state['db_name'] ?? $state['database_name'] ?? 'database';

            return $database . '.' . $table;
        }

        return $excelFile ? basename($excelFile) : 'import_excel';
    }

    private function resolveExcelFile(mixed $excelFile): ?string
    {
        if ($excelFile instanceof TemporaryUploadedFile) {
            return $excelFile->store('imports/inventory', 'local');
        }

        if (is_string($excelFile) && trim($excelFile) !== '') {
            return $excelFile;
        }

        if (is_array($excelFile)) {
            $first = reset($excelFile);

            if ($first instanceof TemporaryUploadedFile) {
                return $first->store('imports/inventory', 'local');
            }

            if (is_string($first) && trim($first) !== '') {
                return $first;
            }

            if (is_array($first)) {
                foreach (['path', 'file', 'storedFileName', 'name'] as $key) {
                    if (! empty($first[$key]) && is_string($first[$key])) {
                        return $first[$key];
                    }
                }
            }
        }

        return null;
    }

    private function findLatestUploadedExcelPath(): ?string
    {
        $files = collect(Storage::disk('local')->files('imports/inventory'))
            ->filter(function (string $file): bool {
                return str_ends_with(strtolower($file), '.xlsx')
                    || str_ends_with(strtolower($file), '.xls');
            })
            ->sortByDesc(function (string $file): int {
                return Storage::disk('local')->lastModified($file);
            })
            ->values();

        return $files->first();
    }
}