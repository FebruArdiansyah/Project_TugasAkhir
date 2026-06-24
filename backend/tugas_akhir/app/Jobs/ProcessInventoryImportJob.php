<?php

namespace App\Jobs;

use App\Models\Customer;
use App\Models\InboundTransaction;
use App\Models\InboundTransactionItem;
use App\Models\InventoryImportLog;
use App\Models\OutboundTransaction;
use App\Models\OutboundTransactionItem;
use App\Models\Product;
use App\Models\Supplier;
use Carbon\Carbon;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Database\Query\Builder;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema as DBSchema;
use Illuminate\Support\Facades\Storage;
use PhpOffice\PhpSpreadsheet\Cell\Coordinate;
use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Reader\IReadFilter;
use PhpOffice\PhpSpreadsheet\Shared\Date as ExcelDate;
use Throwable;

class ProcessInventoryImportJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public int $tries = 1;

    public int $timeout = 3600;

    public function __construct(
        public int $logId,
        public string $excelFile,
        public array $state
    ) {
    }

    public function handle(): void
    {
        $log = InventoryImportLog::query()->find($this->logId);

        if (! $log) {
            return;
        }

        try {
            $sourceType = $this->sourceType();
            $transactionType = $this->transactionType();

            $log->update([
                'status' => 'processing',
                'message' => $sourceType === 'database'
                    ? 'Database eksternal sedang diproses oleh queue worker.'
                    : 'File Excel sedang diproses oleh queue worker.',
            ]);

            if ($sourceType === 'database') {
                $result = $this->importFromExternalDatabase($transactionType, $log);
            } else {
                $filePath = Storage::disk('local')->path($this->excelFile);

                if (! file_exists($filePath)) {
                    throw new \Exception('File Excel tidak ditemukan di storage: ' . $this->excelFile);
                }

                $result = $transactionType === 'inbound'
                    ? $this->importInboundGenericExcel($filePath, $log)
                    : $this->importOutboundHistoricalExcel($filePath, $this->state, $log);
            }

            $log->update([
                'total_rows' => $result['total_rows'],
                'imported_rows' => $result['imported_rows'],
                'skipped_rows' => $result['skipped_rows'],
                'status' => 'success',
                'message' => $result['message'],
                'error_message' => $result['error_message'],
                'finished_at' => now(),
            ]);
        } catch (Throwable $e) {
            report($e);

            $log->update([
                'status' => 'failed',
                'message' => 'Import gagal.',
                'error_message' => $e->getMessage(),
                'finished_at' => now(),
            ]);
        }
    }

    private function sourceType(): string
    {
        $value = strtolower((string) ($this->state['source_type']
            ?? $this->state['source']
            ?? $this->state['data_source']
            ?? $this->state['import_source']
            ?? 'excel'));

        if (
            str_contains($value, 'database') ||
            str_contains($value, 'mysql') ||
            in_array($value, ['db', 'database_lain', 'external_database'], true)
        ) {
            return 'database';
        }

        return 'excel';
    }

    private function transactionType(): string
    {
        $value = strtolower((string) ($this->state['transaction_type']
            ?? $this->state['jenis_transaksi']
            ?? $this->state['type']
            ?? 'outbound'));

        if (str_contains($value, 'inbound') || str_contains($value, 'masuk')) {
            return 'inbound';
        }

        return 'outbound';
    }

    private function sourceName(): string
    {
        return $this->sourceType() === 'database' ? 'import_database' : 'import_excel';
    }

    private function statusAfterImport(): string
    {
        return (string) ($this->state['status_after_import'] ?? 'approved');
    }

    private function userId(): int
    {
        return (int) ($this->state['user_id'] ?? 1);
    }

    private function selectedWarehouseId(): int
    {
        $warehouseId = (int) ($this->state['warehouse_id'] ?? 0);

        if ($warehouseId <= 0) {
            throw new \Exception('Gudang wajib dipilih.');
        }

        return $warehouseId;
    }

    private function importFromExternalDatabase(string $transactionType, ?InventoryImportLog $log = null): array
    {
        $warehouseId = $this->selectedWarehouseId();
        $connectionName = $this->configureExternalDatabaseConnection();
        $query = $this->externalDatabaseQuery($connectionName);

        $context = $this->newImportContext();
        $chunkSize = (int) env('INVENTORY_IMPORT_CHUNK_SIZE', 500);
        $chunkSize = max(100, min($chunkSize, 1000));

        if ($query instanceof Builder) {
            $orderColumn = $this->externalOrderColumn($connectionName, $query);

            if ($orderColumn) {
                $query->orderBy($orderColumn);
            }

            $query->chunk($chunkSize, function ($rows) use ($transactionType, $warehouseId, $log, &$context): void {
                foreach ($rows as $row) {
                    $this->processGenericRow($transactionType, $this->normalizeRecord((array) $row), $warehouseId, $context);
                }

                $this->updateProgressLog($log, $context);
            });
        } else {
            foreach ($query as $row) {
                $this->processGenericRow($transactionType, $this->normalizeRecord((array) $row), $warehouseId, $context);
            }

            $this->updateProgressLog($log, $context);
        }

        return $this->finishContext(
            $context,
            $transactionType === 'inbound'
                ? 'Import barang masuk dari database eksternal selesai.'
                : 'Import barang keluar dari database eksternal selesai.'
        );
    }

    private function configureExternalDatabaseConnection(): string
    {
        $host = (string) ($this->state['host']
            ?? $this->state['db_host']
            ?? $this->state['database_host']
            ?? '127.0.0.1');

        $port = (int) ($this->state['port']
            ?? $this->state['db_port']
            ?? $this->state['database_port']
            ?? 3306);

        $database = (string) ($this->state['database_name']
            ?? $this->state['db_name']
            ?? $this->state['database']
            ?? '');

        $username = (string) ($this->state['username']
            ?? $this->state['db_username']
            ?? $this->state['database_username']
            ?? '');

        $password = (string) ($this->state['password']
            ?? $this->state['db_password']
            ?? $this->state['database_password']
            ?? '');

        if ($database === '' || $username === '') {
            throw new \Exception('Database Name dan Username database eksternal wajib diisi.');
        }

        $connectionName = 'inventory_import_external';

        config([
            "database.connections.{$connectionName}" => [
                'driver' => 'mysql',
                'host' => $host,
                'port' => $port,
                'database' => $database,
                'username' => $username,
                'password' => $password,
                'unix_socket' => '',
                'charset' => 'utf8mb4',
                'collation' => 'utf8mb4_unicode_ci',
                'prefix' => '',
                'prefix_indexes' => true,
                'strict' => false,
                'engine' => null,
                'options' => extension_loaded('pdo_mysql') ? array_filter([
                    \PDO::ATTR_TIMEOUT => 30,
                ]) : [],
            ],
        ]);

        DB::purge($connectionName);
        DB::connection($connectionName)->getPdo();

        return $connectionName;
    }

    private function externalDatabaseQuery(string $connectionName): Builder|array
    {
        $sql = trim((string) ($this->state['sql_query']
            ?? $this->state['query_sql']
            ?? $this->state['query']
            ?? $this->state['custom_query']
            ?? ''));

        if ($sql !== '') {
            $this->validateSelectOnlySql($sql);

            return DB::connection($connectionName)->select($sql);
        }

        $table = trim((string) ($this->state['table_name']
            ?? $this->state['table_or_view']
            ?? $this->state['db_table']
            ?? $this->state['database_table']
            ?? $this->state['nama_tabel']
            ?? ''));

        if ($table === '') {
            throw new \Exception('Nama Tabel / View wajib diisi jika Query SQL Opsional kosong.');
        }

        if (! preg_match('/^[A-Za-z0-9_\.]+$/', $table)) {
            throw new \Exception('Nama tabel/view database eksternal tidak valid.');
        }

        return DB::connection($connectionName)->table($table);
    }

    private function validateSelectOnlySql(string $sql): void
    {
        $normalized = strtolower(trim(preg_replace('/\s+/', ' ', $sql)));

        if (! str_starts_with($normalized, 'select ')) {
            throw new \Exception('Query SQL Opsional hanya boleh menggunakan SELECT.');
        }

        $blockedKeywords = [
            ' insert ', ' update ', ' delete ', ' drop ', ' alter ', ' truncate ',
            ' create ', ' replace ', ' grant ', ' revoke ', ' rename ', ' call ',
            ';insert ', ';update ', ';delete ', ';drop ', ';alter ', ';truncate ', ';create ',
        ];

        foreach ($blockedKeywords as $keyword) {
            if (str_contains(' ' . $normalized . ' ', $keyword)) {
                throw new \Exception('Query SQL Opsional mengandung perintah yang tidak diizinkan.');
            }
        }
    }

    private function externalOrderColumn(string $connectionName, Builder $query): ?string
    {
        $from = $query->from;

        if (! is_string($from) || str_contains($from, ' ')) {
            return null;
        }

        try {
            $columns = collect(DB::connection($connectionName)->getSchemaBuilder()->getColumnListing($from));

            return $columns->contains('id') ? 'id' : ($columns->contains('tanggal') ? 'tanggal' : null);
        } catch (Throwable) {
            return null;
        }
    }

    private function importInboundGenericExcel(string $filePath, ?InventoryImportLog $log = null): array
    {
        $warehouseId = $this->selectedWarehouseId();
        $context = $this->newImportContext();
        $chunkSize = (int) env('INVENTORY_IMPORT_CHUNK_SIZE', 500);
        $chunkSize = max(100, min($chunkSize, 1000));

        $worksheetInfo = IOFactory::createReaderForFile($filePath)->listWorksheetInfo($filePath);

        if (empty($worksheetInfo)) {
            throw new \Exception('File Excel kosong.');
        }

        foreach ($worksheetInfo as $sheetInfo) {
            $sheetName = $sheetInfo['worksheetName'] ?? null;
            $highestRow = (int) ($sheetInfo['totalRows'] ?? 0);
            $totalColumns = max((int) ($sheetInfo['totalColumns'] ?? 10), 10);
            $highestColumn = Coordinate::stringFromColumnIndex($totalColumns);
            $headers = null;

            for ($startRow = 1; $startRow <= $highestRow; $startRow += $chunkSize) {
                $endRow = min($startRow + $chunkSize - 1, $highestRow);
                $reader = IOFactory::createReaderForFile($filePath);
                $reader->setReadDataOnly(true);

                if ($sheetName) {
                    $reader->setLoadSheetsOnly([$sheetName]);
                }

                $reader->setReadFilter(new ExcelChunkReadFilter($startRow, $endRow));

                $spreadsheet = $reader->load($filePath);
                $sheet = $sheetName ? $spreadsheet->getSheetByName($sheetName) : $spreadsheet->getActiveSheet();

                if (! $sheet) {
                    $spreadsheet->disconnectWorksheets();
                    unset($spreadsheet, $reader);
                    continue;
                }

                $rows = $sheet->rangeToArray("A{$startRow}:{$highestColumn}{$endRow}", null, true, false);

                foreach ($rows as $row) {
                    $values = collect($row)->map(fn ($value) => is_string($value) ? trim($value) : $value)->values();

                    if ($this->isEmptyExcelRow($values)) {
                        continue;
                    }

                    if ($headers === null) {
                        $headers = $values
                            ->map(fn ($value) => $this->normalizeKey((string) $value))
                            ->values()
                            ->all();

                        continue;
                    }

                    $record = [];

                    foreach ($headers as $index => $header) {
                        if ($header !== '') {
                            $record[$header] = $values->get($index);
                        }
                    }

                    $this->processGenericRow('inbound', $this->normalizeRecord($record), $warehouseId, $context);
                }

                $this->updateProgressLog($log, $context);

                $spreadsheet->disconnectWorksheets();
                unset($rows, $sheet, $spreadsheet, $reader);
                gc_collect_cycles();
            }
        }

        return $this->finishContext($context, 'Import barang masuk dari Excel selesai.');
    }

    private function importOutboundHistoricalExcel(string $filePath, array $state, ?InventoryImportLog $log = null): array
    {
        $worksheetInfo = IOFactory::createReaderForFile($filePath)->listWorksheetInfo($filePath);

        if (empty($worksheetInfo)) {
            throw new \Exception('File Excel kosong.');
        }

        $warehouseId = $this->selectedWarehouseId();
        $context = $this->newImportContext();

        $currentDate = null;
        $currentInvoice = null;
        $currentCustomerName = null;

        $chunkSize = (int) env('INVENTORY_IMPORT_CHUNK_SIZE', 500);
        $chunkSize = max(100, min($chunkSize, 1000));

        foreach ($worksheetInfo as $sheetInfo) {
            $sheetName = $sheetInfo['worksheetName'] ?? null;
            $highestRow = (int) ($sheetInfo['totalRows'] ?? 0);
            $totalColumns = max((int) ($sheetInfo['totalColumns'] ?? 42), 42);
            $highestColumn = Coordinate::stringFromColumnIndex($totalColumns);

            if ($highestRow <= 0) {
                continue;
            }

            for ($startRow = 1; $startRow <= $highestRow; $startRow += $chunkSize) {
                $endRow = min($startRow + $chunkSize - 1, $highestRow);

                $reader = IOFactory::createReaderForFile($filePath);
                $reader->setReadDataOnly(true);

                if ($sheetName) {
                    $reader->setLoadSheetsOnly([$sheetName]);
                }

                $reader->setReadFilter(new ExcelChunkReadFilter($startRow, $endRow));

                $spreadsheet = $reader->load($filePath);
                $sheet = $sheetName ? $spreadsheet->getSheetByName($sheetName) : $spreadsheet->getActiveSheet();

                if (! $sheet) {
                    $spreadsheet->disconnectWorksheets();
                    unset($spreadsheet, $reader);
                    continue;
                }

                $rows = $sheet->rangeToArray("A{$startRow}:{$highestColumn}{$endRow}", null, true, false);

                foreach ($rows as $offset => $row) {
                    $rowNumber = $startRow + $offset;
                    $values = collect($row)->map(fn ($value) => is_string($value) ? trim($value) : $value)->values();

                    if ($this->isEmptyExcelRow($values)) {
                        continue;
                    }

                    $context['total_rows']++;

                    if (
                        $this->isOutboundHeaderRow($values) ||
                        $this->isOutboundTotalRow($values) ||
                        $this->isOutboundGrandTotalRow($values)
                    ) {
                        continue;
                    }

                    $dateCell = $values->get(1);
                    $invoiceCell = $this->cell($values, 2);
                    $customerCell = $this->cell($values, 3);

                    if ($invoiceCell) {
                        $currentInvoice = $invoiceCell;
                        $currentDate = $this->toDate($dateCell);

                        if ($customerCell) {
                            $currentCustomerName = $customerCell;
                        }
                    }

                    if (! $currentInvoice) {
                        $this->skipRow($context, "Baris {$rowNumber} dilewati: nomor invoice tidak ditemukan.");
                        continue;
                    }

                    if (! $currentDate) {
                        $this->skipRow($context, "Baris {$rowNumber} dilewati: tanggal transaksi tidak valid.");
                        continue;
                    }

                    $productName = $this->cell($values, 4);

                    if (! $productName || strtoupper($productName) === 'TOTAL') {
                        continue;
                    }

                    $record = [
                        'tanggal' => $currentDate->toDateString(),
                        'no_invoice' => $currentInvoice,
                        'nama_customer' => $currentCustomerName,
                        'nama_barang' => $productName,
                        'qty' => $values->get(37),
                        'harga' => $values->get(38),
                        'subtotal' => $values->get(39),
                        'sales_name' => 'Admin',
                        'status' => $this->statusAfterImport(),
                        'keterangan' => $this->cell($values, 41),
                    ];

                    $this->processGenericRow('outbound', $this->normalizeRecord($record), $warehouseId, $context, false);
                }

                $this->updateProgressLog($log, $context);

                $spreadsheet->disconnectWorksheets();
                unset($rows, $sheet, $spreadsheet, $reader);
                gc_collect_cycles();
            }
        }

        return $this->finishContext($context, 'Import barang keluar dari Excel selesai.');
    }

    private function processGenericRow(string $transactionType, array $record, int $warehouseId, array &$context, bool $countRow = true): void
    {
        if ($countRow) {
            $context['total_rows']++;
        }

        $date = $this->toDate($this->recordValue($record, ['tanggal', 'transaction_date', 'date', 'tgl', 'tgl_transaksi']));
        $invoice = $this->stringValue($this->recordValue($record, ['no_invoice', 'invoice_number', 'reference_number', 'invoice', 'nomor_invoice']));
        $productName = $this->stringValue($this->recordValue($record, ['nama_barang', 'product_name', 'name_barang', 'barang', 'produk', 'item_name', 'product']));
        $qty = $this->toNumber($this->recordValue($record, ['qty', 'quantity', 'jumlah', 'jumlah_barang']));
        $unitPrice = $this->toNumber($this->recordValue($record, ['harga', 'unit_price', 'price', 'harga_satuan']));
        $subtotal = $this->toNumber($this->recordValue($record, ['subtotal', 'sub_total', 'total', 'amount']));
        $note = $this->stringValue($this->recordValue($record, ['keterangan', 'note', 'notes', 'remark', 'remarks']));

        if (! $date) {
            $this->skipRow($context, 'Baris dilewati: tanggal transaksi tidak valid.');
            return;
        }

        if (! $invoice) {
            $this->skipRow($context, 'Baris dilewati: nomor invoice tidak ditemukan.');
            return;
        }

        if (! $productName) {
            $this->skipRow($context, "Baris invoice {$invoice} dilewati: nama barang kosong.");
            return;
        }

        if ($qty <= 0) {
            $this->skipRow($context, "Baris invoice {$invoice} dilewati: qty kosong/tidak valid.");
            return;
        }

        if ($subtotal <= 0 && $unitPrice > 0) {
            $subtotal = $qty * $unitPrice;
        }

        $product = $this->findProductByExcelName($productName);

        if (! $product) {
            $this->skipRow($context, "Invoice {$invoice} dilewati: produk '{$productName}' tidak ditemukan di master produk.");
            return;
        }

        if ($transactionType === 'inbound') {
            $supplierName = $this->stringValue($this->recordValue($record, ['nama_supplier', 'supplier_name', 'supplier', 'vendor', 'vendor_name']));
            $this->storeInboundRow($date, $invoice, $supplierName, $product, $qty, $unitPrice, $subtotal, $warehouseId, $note, $context);
        } else {
            $customerName = $this->stringValue($this->recordValue($record, ['nama_customer', 'customer_name', 'customer', 'pelanggan', 'tujuan']));
            $salesName = $this->stringValue($this->recordValue($record, ['sales_name', 'sales', 'admin'])) ?: 'Admin';
            $this->storeOutboundRow($date, $invoice, $customerName, $salesName, $product, $qty, $unitPrice, $subtotal, $warehouseId, $note, $context);
        }
    }

    private function storeInboundRow(Carbon $date, string $invoice, ?string $supplierName, Product $product, float $qty, float $unitPrice, float $subtotal, int $warehouseId, ?string $note, array &$context): void
    {
        $source = $this->sourceName();
        $duplicateKey = 'inbound:' . $source . ':' . $invoice;

        if (! array_key_exists($duplicateKey, $context['duplicate_invoice_cache'])) {
            $context['duplicate_invoice_cache'][$duplicateKey] = InboundTransaction::query()
                ->where('invoice_number', $invoice)
                ->where('source', $source)
                ->exists();
        }

        if ($context['duplicate_invoice_cache'][$duplicateKey]) {
            $this->skipRow($context, "Invoice {$invoice} dilewati: sudah pernah diimport.");
            return;
        }

        $supplier = $this->findOrCreateSupplier($supplierName);
        $transactionCacheKey = 'inbound:' . $invoice;

        if (! isset($context['transaction_id_cache'][$transactionCacheKey])) {
            $transaction = InboundTransaction::create($this->filterColumns('inbound_transactions', [
                'transaction_number' => $this->nextInboundImportTransactionNumber($date),
                'transaction_date' => $date->toDateString(),
                'inbound_type' => 'pembelian',
                'invoice_number' => $invoice,
                'reference_number' => $invoice,
                'supplier_id' => $supplier?->id,
                'warehouse_id' => $warehouseId,
                'note' => 'Import barang masuk. Invoice: ' . $invoice,
                'status' => $this->statusAfterImport(),
                'sub_total' => 0,
                'discount_amount' => 0,
                'vat_percent' => 0,
                'vat_amount' => 0,
                'other_cost' => 0,
                'grand_total' => 0,
                'paid_amount' => 0,
                'remaining_amount' => 0,
                'submitted_by' => $this->userId(),
                'submitted_at' => now(),
                'approved_by' => $this->statusAfterImport() === 'approved' ? $this->userId() : null,
                'approved_at' => $this->statusAfterImport() === 'approved' ? now() : null,
                'approval_note' => $this->statusAfterImport() === 'approved'
                    ? 'Auto approved dari proses import.'
                    : null,
                'source' => $source,
            ]));

            $context['transaction_id_cache'][$transactionCacheKey] = $transaction->id;
            $context['created_transactions']++;
        }

        $transactionId = $context['transaction_id_cache'][$transactionCacheKey];

        InboundTransactionItem::create($this->filterColumns('inbound_transaction_items', [
            'inbound_transaction_id' => $transactionId,
            'product_id' => $product->id,
            'warehouse_id' => $warehouseId,
            'unit_id' => $this->getProductValue($product, ['unit_id']),
            'qty' => $qty,
            'quantity' => $qty,
            'unit_cost' => $unitPrice,
            'unit_price' => $unitPrice,
            'price' => $unitPrice,
            'discount_amount' => 0,
            'subtotal' => $subtotal,
            'sub_total' => $subtotal,
            'stock_before_submit' => 0,
            'stock_after_submit' => 0,
            'product_code_snapshot' => $this->getProductValue($product, ['product_code', 'code', 'sku']),
            'product_name_snapshot' => $this->getProductValue($product, ['name', 'product_name']) ?: $product->getAttribute('name'),
            'unit_name_snapshot' => $this->getProductUnitName($product),
            'note' => $note,
        ]));

        $this->incrementTransactionTotals('inbound_transactions', $transactionId, $subtotal);

        if ($this->shouldUpdateOperationalStock()) {
            $this->applyStockMovement(
                productId: (int) $product->id,
                warehouseId: $warehouseId,
                qty: $qty,
                movementType: 'in',
                referenceType: 'inbound_transaction',
                referenceId: $transactionId,
                description: 'Import barang masuk. Invoice: ' . $invoice,
                movementDate: $date,
            );
        }

        $context['imported_rows']++;
    }

    private function storeOutboundRow(Carbon $date, string $invoice, ?string $customerName, string $salesName, Product $product, float $qty, float $unitPrice, float $subtotal, int $warehouseId, ?string $note, array &$context): void
    {
        $source = $this->sourceName();
        $duplicateKey = 'outbound:' . $source . ':' . $invoice;

        if (! array_key_exists($duplicateKey, $context['duplicate_invoice_cache'])) {
            $context['duplicate_invoice_cache'][$duplicateKey] = OutboundTransaction::query()
                ->where('reference_number', $invoice)
                ->where('source', $source)
                ->exists();
        }

        if ($context['duplicate_invoice_cache'][$duplicateKey]) {
            $this->skipRow($context, "Invoice {$invoice} dilewati: sudah pernah diimport.");
            return;
        }

        $customer = $this->findOrCreateCustomer($customerName);
        $transactionCacheKey = 'outbound:' . $invoice;

        if (! isset($context['transaction_id_cache'][$transactionCacheKey])) {
            $transaction = OutboundTransaction::create($this->filterColumns('outbound_transactions', [
                'transaction_number' => $this->nextOutboundImportTransactionNumber($date),
                'transaction_date' => $date->toDateString(),
                'outbound_type' => 'penjualan',
                'reference_number' => $invoice,
                'invoice_number' => $invoice,
                'customer_id' => $customer?->id,
                'warehouse_id' => $warehouseId,
                'sales_name' => $salesName ?: 'Admin',
                'driver_name' => null,
                'due_date' => null,
                'note' => 'Import barang keluar. Invoice: ' . $invoice,
                'status' => $this->statusAfterImport(),
                'sub_total' => 0,
                'discount_amount' => 0,
                'vat_percent' => 0,
                'vat_amount' => 0,
                'other_cost' => 0,
                'grand_total' => 0,
                'paid_amount' => 0,
                'remaining_amount' => 0,
                'submitted_by' => $this->userId(),
                'submitted_at' => now(),
                'approved_by' => $this->statusAfterImport() === 'approved' ? $this->userId() : null,
                'approved_at' => $this->statusAfterImport() === 'approved' ? now() : null,
                'approval_note' => $this->statusAfterImport() === 'approved'
                    ? 'Auto approved dari proses import.'
                    : null,
                'source' => $source,
            ]));

            $context['transaction_id_cache'][$transactionCacheKey] = $transaction->id;
            $context['created_transactions']++;
        }

        $transactionId = $context['transaction_id_cache'][$transactionCacheKey];

        $item = OutboundTransactionItem::create($this->filterColumns('outbound_transaction_items', [
            'outbound_transaction_id' => $transactionId,
            'product_id' => $product->id,
            'warehouse_id' => $warehouseId,
            'unit_id' => $this->getProductValue($product, ['unit_id']),
            'qty' => $qty,
            'quantity' => $qty,
            'unit_price' => $unitPrice,
            'price' => $unitPrice,
            'discount_amount' => 0,
            'subtotal' => $subtotal,
            'sub_total' => $subtotal,
            'stock_before_submit' => 0,
            'stock_after_submit' => 0,
            'product_code_snapshot' => $this->getProductValue($product, ['product_code', 'code', 'sku']),
            'product_name_snapshot' => $this->getProductValue($product, ['name', 'product_name']) ?: $product->getAttribute('name'),
            'unit_name_snapshot' => $this->getProductUnitName($product),
            'note' => $note,
        ]));

        $this->incrementTransactionTotals('outbound_transactions', $transactionId, $subtotal);

        if ($this->shouldUpdateOperationalStock()) {
            $stockResult = $this->applyStockMovement(
                productId: (int) $product->id,
                warehouseId: $warehouseId,
                qty: $qty,
                movementType: 'out',
                referenceType: 'outbound_transaction',
                referenceId: $transactionId,
                description: 'Import barang keluar. Invoice: ' . $invoice,
                movementDate: $date,
            );

            DB::table('outbound_transaction_items')
                ->where('id', $item->id)
                ->update($this->filterColumns('outbound_transaction_items', [
                    'stock_before_submit' => $stockResult['stock_before'],
                    'stock_after_submit' => $stockResult['stock_after'],
                    'updated_at' => now(),
                ]));
        }

        $context['imported_rows']++;
    }

    private function incrementTransactionTotals(string $table, int $transactionId, float $subtotal): void
    {
        foreach (['sub_total', 'grand_total', 'remaining_amount'] as $column) {
            if (DBSchema::hasColumn($table, $column)) {
                DB::table($table)->where('id', $transactionId)->increment($column, $subtotal);
            }
        }
    }

    private function shouldUpdateOperationalStock(): bool
    {
        $updateStock = $this->state['update_stock_operational']
            ?? $this->state['update_operational_stock']
            ?? $this->state['update_stock']
            ?? $this->state['is_update_stock']
            ?? $this->state['sync_stock']
            ?? true;

        $status = strtolower($this->statusAfterImport());

        $isApproved = in_array($status, [
            'approved',
            'approve',
            'disetujui',
            'selesai',
            'completed',
        ], true);

        return $isApproved && filter_var($updateStock, FILTER_VALIDATE_BOOL);
    }

    private function applyStockMovement(
        int $productId,
        int $warehouseId,
        float $qty,
        string $movementType,
        string $referenceType,
        int $referenceId,
        string $description,
        Carbon $movementDate,
    ): array {
        if (! DBSchema::hasTable('stock_balances') || ! DBSchema::hasTable('stock_movements')) {
            return [
                'stock_before' => 0,
                'stock_after' => 0,
            ];
        }

        $stockBalance = DB::table('stock_balances')
            ->where('product_id', $productId)
            ->where('warehouse_id', $warehouseId)
            ->lockForUpdate()
            ->first();

        $stockBefore = (float) ($stockBalance->qty_on_hand ?? 0);

        $stockAfter = $movementType === 'in'
            ? $stockBefore + $qty
            : $stockBefore - $qty;

        if ($stockBalance) {
            DB::table('stock_balances')
                ->where('id', $stockBalance->id)
                ->update([
                    'qty_on_hand' => $stockAfter,
                    'qty_reserved' => $stockBalance->qty_reserved ?? 0,
                    'minimum_stock' => $stockBalance->minimum_stock ?? $this->productMinimumStock($productId),
                    'updated_at' => now(),
                ]);
        } else {
            DB::table('stock_balances')->insert($this->filterColumns('stock_balances', [
                'product_id' => $productId,
                'warehouse_id' => $warehouseId,
                'qty_on_hand' => $stockAfter,
                'qty_reserved' => 0,
                'minimum_stock' => $this->productMinimumStock($productId),
                'created_at' => now(),
                'updated_at' => now(),
            ]));
        }

        DB::table('stock_movements')->insert($this->filterColumns('stock_movements', [
            'movement_number' => $this->nextStockMovementNumber($movementType, $movementDate),
            'product_id' => $productId,
            'warehouse_id' => $warehouseId,
            'movement_type' => $movementType,
            'reference_type' => $referenceType,
            'reference_id' => $referenceId,
            'qty_in' => $movementType === 'in' ? $qty : 0,
            'qty_out' => $movementType === 'out' ? $qty : 0,
            'stock_before' => $stockBefore,
            'stock_after' => $stockAfter,
            'description' => $description,
            'created_by' => $this->userId(),
            'created_at' => $movementDate->copy()->setTimeFrom(now()),
            'updated_at' => now(),
        ]));

        return [
            'stock_before' => $stockBefore,
            'stock_after' => $stockAfter,
        ];
    }

    private function productMinimumStock(int $productId): float
    {
        if (! DBSchema::hasTable('products')) {
            return 0;
        }

        if (DBSchema::hasColumn('products', 'minimum_stock')) {
            return (float) (DB::table('products')->where('id', $productId)->value('minimum_stock') ?? 0);
        }

        if (DBSchema::hasColumn('products', 'min_stock')) {
            return (float) (DB::table('products')->where('id', $productId)->value('min_stock') ?? 0);
        }

        return 0;
    }

    private function nextStockMovementNumber(string $movementType, Carbon $date): string
    {
        $prefix = $movementType === 'in' ? 'MOV-IN' : 'MOV-OUT';
        $dateText = $date->format('Ymd');

        $lastNumber = DB::table('stock_movements')
            ->where('movement_number', 'like', "{$prefix}-{$dateText}-%")
            ->orderByDesc('movement_number')
            ->value('movement_number');

        $nextSequence = 1;

        if ($lastNumber) {
            $nextSequence = ((int) substr((string) $lastNumber, -6)) + 1;
        }

        return "{$prefix}-{$dateText}-" . str_pad((string) $nextSequence, 6, '0', STR_PAD_LEFT);
    }

    private function filterColumns(string $table, array $data): array
    {
        return collect($data)
            ->filter(fn ($value, string $column): bool => DBSchema::hasColumn($table, $column))
            ->all();
    }

    private function newImportContext(): array
    {
        return [
            'total_rows' => 0,
            'imported_rows' => 0,
            'skipped_rows' => 0,
            'created_transactions' => 0,
            'skipped_messages' => [],
            'transaction_id_cache' => [],
            'duplicate_invoice_cache' => [],
        ];
    }

    private function skipRow(array &$context, string $message): void
    {
        $context['skipped_rows']++;

        if (count($context['skipped_messages']) < 50) {
            $context['skipped_messages'][] = $message;
        }
    }

    private function updateProgressLog(?InventoryImportLog $log, array $context): void
    {
        $log?->update([
            'total_rows' => $context['total_rows'],
            'imported_rows' => $context['imported_rows'],
            'skipped_rows' => $context['skipped_rows'],
            'message' => "Import sedang berjalan. Baris terbaca: {$context['total_rows']}. Berhasil: {$context['imported_rows']}. Dilewati: {$context['skipped_rows']}.",
        ]);
    }

    private function finishContext(array $context, string $messagePrefix): array
    {
        return [
            'total_rows' => $context['total_rows'],
            'imported_rows' => $context['imported_rows'],
            'skipped_rows' => $context['skipped_rows'],
            'message' => $messagePrefix . " Transaksi dibuat: {$context['created_transactions']}. Item berhasil: {$context['imported_rows']}. Dilewati: {$context['skipped_rows']}.",
            'error_message' => empty($context['skipped_messages'])
                ? null
                : implode("\n", $context['skipped_messages']),
        ];
    }

    private function normalizeRecord(array $record): array
    {
        $normalized = [];

        foreach ($record as $key => $value) {
            $normalized[$this->normalizeKey((string) $key)] = is_string($value) ? trim($value) : $value;
        }

        return $normalized;
    }

    private function normalizeKey(string $key): string
    {
        $key = strtolower(trim($key));
        $key = str_replace(['.', '/', '-', ' '], '_', $key);
        $key = preg_replace('/[^a-z0-9_]/', '', $key);
        $key = preg_replace('/_+/', '_', $key);

        return trim((string) $key, '_');
    }

    private function recordValue(array $record, array $keys): mixed
    {
        foreach ($keys as $key) {
            $normalizedKey = $this->normalizeKey($key);

            if (array_key_exists($normalizedKey, $record) && $record[$normalizedKey] !== null && $record[$normalizedKey] !== '') {
                return $record[$normalizedKey];
            }
        }

        return null;
    }

    private function stringValue(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $value = trim((string) $value);

        return $value === '' || $value === '-' ? null : $value;
    }

    private function cell(Collection $values, int $index): ?string
    {
        $value = $values->get($index);

        if ($value === null) {
            return null;
        }

        $text = trim((string) $value);

        return $text === '' ? null : $text;
    }

    private function isEmptyExcelRow(Collection $values): bool
    {
        return $values
            ->filter(fn ($value) => $value !== null && trim((string) $value) !== '')
            ->isEmpty();
    }

    private function isOutboundHeaderRow(Collection $values): bool
    {
        $joined = strtoupper($values->implode(' '));

        return str_contains($joined, 'NO. INVOICE')
            || str_contains($joined, 'NAMA CUSTOMER')
            || str_contains($joined, 'NAMA BARANG')
            || str_contains($joined, 'LAPORAN PENJUALAN')
            || str_contains($joined, 'MONITORING PO')
            || str_contains($joined, 'PERIODE');
    }

    private function isOutboundTotalRow(Collection $values): bool
    {
        $productName = strtoupper((string) ($this->cell($values, 4) ?? ''));

        return $productName === 'TOTAL';
    }

    private function isOutboundGrandTotalRow(Collection $values): bool
    {
        $firstColumn = strtoupper((string) ($this->cell($values, 0) ?? ''));

        return str_contains($firstColumn, 'GRAND TOTAL');
    }

    private function toDate(mixed $value): ?Carbon
    {
        try {
            if ($value instanceof \DateTimeInterface) {
                return Carbon::instance($value);
            }

            if (is_numeric($value)) {
                return Carbon::instance(ExcelDate::excelToDateTimeObject((float) $value));
            }

            if (is_string($value) && trim($value) !== '') {
                return Carbon::parse($value);
            }
        } catch (Throwable) {
            return null;
        }

        return null;
    }

    private function toNumber(mixed $value): float
    {
        if ($value === null || $value === '') {
            return 0;
        }

        if (is_numeric($value)) {
            return (float) $value;
        }

        $clean = preg_replace('/[^0-9,.-]/', '', (string) $value);
        $clean = str_replace('.', '', $clean);
        $clean = str_replace(',', '.', $clean);

        return is_numeric($clean) ? (float) $clean : 0;
    }

    private function findProductByExcelName(string $productName): ?Product
    {
        $productName = trim(preg_replace('/\s+/', ' ', $productName));

        $columns = collect(['name', 'product_name', 'full_name', 'product_code', 'code', 'sku'])
            ->filter(fn (string $column): bool => DBSchema::hasColumn('products', $column))
            ->values();

        if ($columns->isEmpty()) {
            return null;
        }

        $exact = Product::query()
            ->where(function ($query) use ($columns, $productName): void {
                foreach ($columns as $index => $column) {
                    $method = $index === 0 ? 'where' : 'orWhere';
                    $query->{$method}($column, $productName);
                }
            })
            ->first();

        if ($exact) {
            return $exact;
        }

        return Product::query()
            ->where(function ($query) use ($columns, $productName): void {
                foreach ($columns as $index => $column) {
                    $method = $index === 0 ? 'where' : 'orWhere';
                    $query->{$method}($column, 'like', '%' . $productName . '%');
                }
            })
            ->first();
    }

    private function findOrCreateCustomer(?string $customerName): ?Customer
    {
        if (! $customerName) {
            return null;
        }

        $customerName = trim(preg_replace('/\s+/', ' ', $customerName));

        $nameColumn = collect(['customer_name', 'name', 'nama_customer', 'nama', 'company_name'])
            ->first(fn (string $column): bool => DBSchema::hasColumn('customers', $column));

        if (! $nameColumn) {
            return null;
        }

        $customer = Customer::query()->where($nameColumn, $customerName)->first();

        if ($customer) {
            return $customer;
        }

        $customerCode = 'CUST-IMP-' . strtoupper(substr(md5($customerName), 0, 8));

        return Customer::create($this->filterColumns('customers', [
            $nameColumn => $customerName,
            'customer_code' => $customerCode,
            'code' => $customerCode,
            'kode_customer' => $customerCode,
            'phone' => '-',
            'telephone' => '-',
            'telp' => '-',
            'address' => '-',
            'alamat' => '-',
            'email' => 'import-' . strtolower(substr(md5($customerName), 0, 12)) . '@example.local',
            'status' => 'active',
            'is_active' => true,
            'created_by' => $this->userId(),
            'updated_by' => $this->userId(),
        ]));
    }

    private function findOrCreateSupplier(?string $supplierName): ?Supplier
    {
        if (! $supplierName) {
            return null;
        }

        $supplierName = trim(preg_replace('/\s+/', ' ', $supplierName));

        if (! DBSchema::hasTable('suppliers')) {
            return null;
        }

        $nameColumn = collect(['supplier_name', 'name', 'nama_supplier', 'nama', 'company_name'])
            ->first(fn (string $column): bool => DBSchema::hasColumn('suppliers', $column));

        if (! $nameColumn) {
            return null;
        }

        $supplier = Supplier::query()->where($nameColumn, $supplierName)->first();

        if ($supplier) {
            return $supplier;
        }

        $supplierCode = 'SUP-IMP-' . strtoupper(substr(md5($supplierName), 0, 8));

        return Supplier::create($this->filterColumns('suppliers', [
            $nameColumn => $supplierName,
            'supplier_code' => $supplierCode,
            'code' => $supplierCode,
            'kode_supplier' => $supplierCode,
            'phone' => '-',
            'telephone' => '-',
            'telp' => '-',
            'address' => '-',
            'alamat' => '-',
            'email' => 'supplier-' . strtolower(substr(md5($supplierName), 0, 12)) . '@example.local',
            'status' => 'active',
            'is_active' => true,
            'created_by' => $this->userId(),
            'updated_by' => $this->userId(),
        ]));
    }

    private function getProductValue(Product $product, array $columns): mixed
    {
        foreach ($columns as $column) {
            if (DBSchema::hasColumn('products', $column) && $product->{$column} !== null) {
                return $product->{$column};
            }
        }

        return null;
    }

    private function getProductUnitName(Product $product): ?string
    {
        if (method_exists($product, 'unit') && $product->unit) {
            foreach (['name', 'unit_name', 'code'] as $column) {
                if (isset($product->unit->{$column})) {
                    return $product->unit->{$column};
                }
            }
        }

        return null;
    }

    private function nextInboundImportTransactionNumber(Carbon $date): string
    {
        $prefix = 'IN-IMP-' . $date->format('Ymd');

        $lastNumber = InboundTransaction::query()
            ->where('transaction_number', 'like', $prefix . '-%')
            ->pluck('transaction_number')
            ->map(function ($number) use ($prefix) {
                if (preg_match('/^' . preg_quote($prefix, '/') . '-(\d+)$/', (string) $number, $matches)) {
                    return (int) $matches[1];
                }

                return 0;
            })
            ->max() ?? 0;

        return $prefix . '-' . str_pad((string) ($lastNumber + 1), 4, '0', STR_PAD_LEFT);
    }

    private function nextOutboundImportTransactionNumber(Carbon $date): string
    {
        $prefix = 'OUT-IMP-' . $date->format('Ymd');

        $lastNumber = OutboundTransaction::query()
            ->where('transaction_number', 'like', $prefix . '-%')
            ->pluck('transaction_number')
            ->map(function ($number) use ($prefix) {
                if (preg_match('/^' . preg_quote($prefix, '/') . '-(\d+)$/', (string) $number, $matches)) {
                    return (int) $matches[1];
                }

                return 0;
            })
            ->max() ?? 0;

        return $prefix . '-' . str_pad((string) ($lastNumber + 1), 4, '0', STR_PAD_LEFT);
    }
}

class ExcelChunkReadFilter implements IReadFilter
{
    public function __construct(
        private int $startRow,
        private int $endRow
    ) {
    }

    public function readCell($columnAddress, $row, $worksheetName = ''): bool
    {
        return $row >= $this->startRow && $row <= $this->endRow;
    }
}