<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use RuntimeException;

class ProductNauraSeeder extends Seeder
{
    public function run(): void
    {
        if (! Schema::hasTable('products')) {
            throw new RuntimeException('Tabel products tidak ditemukan.');
        }

        $nameColumn = $this->firstColumn('products', ['name', 'product_name', 'nama_produk']);
        if (! $nameColumn) {
            throw new RuntimeException('Kolom nama produk tidak ditemukan. Cek tabel products.');
        }

        $codeColumn = $this->firstColumn('products', ['code', 'product_code', 'sku', 'kode_produk']);
        $fullNameColumn = $this->firstColumn('products', ['full_name', 'display_name']);
        $typeIdColumn = $this->firstColumn('products', ['product_type_id', 'type_id']);
        $densityIdColumn = $this->firstColumn('products', ['product_density_id', 'density_id']);
        $categoryIdColumn = $this->firstColumn('products', ['product_category_id', 'category_id']);
        $categoryTextColumn = $this->firstColumn('products', ['category', 'category_name', 'kategori', 'type']);
        $unitIdColumn = $this->firstColumn('products', ['unit_id']);
        $unitTextColumn = $this->firstColumn('products', ['unit', 'unit_name', 'satuan']);
        $purchaseColumn = $this->firstColumn('products', ['default_purchase_price', 'purchase_price', 'buy_price', 'cost_price', 'harga_beli']);
        $sellingColumn = $this->firstColumn('products', ['default_selling_price', 'selling_price', 'sale_price', 'price', 'harga_jual']);
        $lastPurchaseColumn = $this->firstColumn('products', ['last_purchase_price']);
        $lastSellingColumn = $this->firstColumn('products', ['last_selling_price']);
        $minimumStockColumn = $this->firstColumn('products', ['minimum_stock', 'min_stock', 'stock_min', 'minimum_qty']);
        $activeColumn = $this->firstColumn('products', ['is_active']);
        $statusColumn = $this->firstColumn('products', ['status']);
        $lengthColumn = $this->firstColumn('products', ['length']);
        $widthColumn = $this->firstColumn('products', ['width']);
        $thicknessColumn = $this->firstColumn('products', ['thickness']);
        $sizeTextColumn = $this->firstColumn('products', ['size_text']);
        $descriptionColumn = $this->firstColumn('products', ['description']);

        $unitId = $this->findOrCreateUnit('PCS');
        $userId = $this->defaultUserId();
        $products = $this->products();
        $processed = 0;

        DB::transaction(function () use (
            $products,
            $nameColumn,
            $codeColumn,
            $fullNameColumn,
            $typeIdColumn,
            $densityIdColumn,
            $categoryIdColumn,
            $categoryTextColumn,
            $unitIdColumn,
            $unitTextColumn,
            $purchaseColumn,
            $sellingColumn,
            $lastPurchaseColumn,
            $lastSellingColumn,
            $minimumStockColumn,
            $activeColumn,
            $statusColumn,
            $lengthColumn,
            $widthColumn,
            $thicknessColumn,
            $sizeTextColumn,
            $descriptionColumn,
            $unitId,
            $userId,
            &$processed
        ): void {
            foreach ($products as $item) {
                $dimensions = $this->extractDimensions($item['name']);
                $categoryId = $categoryIdColumn ? $this->findOrCreateByName('product_categories', $item['category']) : null;
                $typeId = $typeIdColumn ? $this->findOrCreateByName('product_types', $item['catalog'] ?: 'UMUM') : null;
                $densityId = $densityIdColumn ? $this->findOrCreateByName('product_densities', $this->extractDensity($item['name']) ?: 'UMUM') : null;

                $data = [
                    $nameColumn => $item['name'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ];

                if ($codeColumn) {
                    $data[$codeColumn] = $this->makeProductCode($item['name']);
                }

                if ($fullNameColumn) {
                    $data[$fullNameColumn] = $item['name'];
                }

                if ($typeIdColumn && $typeId) {
                    $data[$typeIdColumn] = $typeId;
                }

                if ($densityIdColumn && $densityId) {
                    $data[$densityIdColumn] = $densityId;
                }

                if ($categoryIdColumn && $categoryId) {
                    $data[$categoryIdColumn] = $categoryId;
                }

                if ($categoryTextColumn) {
                    $data[$categoryTextColumn] = $item['category'];
                }

                if ($unitIdColumn && $unitId) {
                    $data[$unitIdColumn] = $unitId;
                }

                if ($unitTextColumn) {
                    $data[$unitTextColumn] = $item['unit'];
                }

                if ($purchaseColumn) {
                    $data[$purchaseColumn] = $item['purchase_price'];
                }

                if ($sellingColumn) {
                    $data[$sellingColumn] = $item['selling_price'];
                }

                if ($lastPurchaseColumn) {
                    $data[$lastPurchaseColumn] = 0;
                }

                if ($lastSellingColumn) {
                    $data[$lastSellingColumn] = 0;
                }

                if ($minimumStockColumn) {
                    $data[$minimumStockColumn] = $item['minimum_stock'];
                }

                if ($activeColumn) {
                    $data[$activeColumn] = true;
                }

                if ($statusColumn) {
                    $data[$statusColumn] = 'active';
                }

                if ($lengthColumn && $dimensions) {
                    $data[$lengthColumn] = $dimensions['length'];
                }

                if ($widthColumn && $dimensions) {
                    $data[$widthColumn] = $dimensions['width'];
                }

                if ($thicknessColumn && $dimensions) {
                    $data[$thicknessColumn] = $dimensions['thickness'];
                }

                if ($sizeTextColumn && $dimensions) {
                    $data[$sizeTextColumn] = $dimensions['size_text'];
                }

                if ($descriptionColumn) {
                    $data[$descriptionColumn] = 'Data master produk PT Naura Sukses Abadi';
                }

                if (Schema::hasColumn('products', 'created_by') && $userId) {
                    $data['created_by'] = $userId;
                }

                if (Schema::hasColumn('products', 'updated_by') && $userId) {
                    $data['updated_by'] = $userId;
                }

                DB::table('products')->updateOrInsert(
                    [$nameColumn => $item['name']],
                    $this->filterColumns('products', $data)
                );

                $processed++;
            }
        });

        $this->command?->info("Seeder produk Naura selesai. Total produk diproses: {$processed}.");
    }

    private function products(): array
    {
        $encoded = <<<'B64'
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
B64;

        $json = gzdecode(base64_decode($encoded));
        $products = json_decode($json, true);

        if (! is_array($products)) {
            throw new RuntimeException('Data produk gagal dibaca.');
        }

        return $products;
    }

    private function makeProductCode(string $productName): string
    {
        $base = strtoupper((string) preg_replace('/[^A-Za-z0-9]+/', '-', $productName));
        $base = trim($base, '-');
        $base = substr($base, 0, 40);
        $hash = strtoupper(substr(md5($productName), 0, 8));

        return 'NSA-' . $base . '-' . $hash;
    }

    private function extractDensity(string $productName): ?string
    {
        if (preg_match('/\bD-?\s*(\d{1,2}[A-Z]?)\b/i', $productName, $match)) {
            return 'D-' . strtoupper($match[1]);
        }

        return null;
    }

    private function extractDimensions(string $productName): ?array
    {
        if (! preg_match('/(\d{2,3})\s*[xX]\s*(\d{2,3})\s*[xX]\s*(\d{1,3})/', $productName, $match)) {
            return null;
        }

        return [
            'length' => (int) $match[1],
            'width' => (int) $match[2],
            'thickness' => (int) $match[3],
            'size_text' => $match[1] . ' x ' . $match[2] . ' x ' . $match[3] . ' CM',
        ];
    }

    private function findOrCreateUnit(string $unitName): ?int
    {
        if (! Schema::hasTable('units')) {
            return null;
        }

        $nameColumn = $this->firstColumn('units', ['name', 'unit_name', 'nama_satuan']);
        $codeColumn = $this->firstColumn('units', ['code', 'unit_code', 'kode']);

        if (! $nameColumn && ! $codeColumn) {
            return null;
        }

        $query = DB::table('units');

        if ($nameColumn && $codeColumn) {
            $query->where($nameColumn, $unitName)->orWhere($codeColumn, $unitName);
        } elseif ($nameColumn) {
            $query->where($nameColumn, $unitName);
        } else {
            $query->where($codeColumn, $unitName);
        }

        $existing = $query->first();

        if ($existing) {
            return (int) $existing->id;
        }

        $data = [
            'created_at' => now(),
            'updated_at' => now(),
        ];

        if ($nameColumn) {
            $data[$nameColumn] = $unitName;
        }

        if ($codeColumn) {
            $data[$codeColumn] = $unitName;
        }

        if (Schema::hasColumn('units', 'is_active')) {
            $data['is_active'] = true;
        }

        if (Schema::hasColumn('units', 'status')) {
            $data['status'] = 'active';
        }

        return (int) DB::table('units')->insertGetId($this->filterColumns('units', $data));
    }

    private function findOrCreateByName(string $table, string $name): ?int
    {
        if (! Schema::hasTable($table)) {
            return null;
        }

        $nameColumn = $this->firstColumn($table, ['name', 'category_name', 'type_name', 'density_name', 'nama']);
        $codeColumn = $this->firstColumn($table, ['code', 'category_code', 'type_code', 'density_code', 'kode']);

        if (! $nameColumn) {
            return null;
        }

        $existing = DB::table($table)->where($nameColumn, $name)->first();

        if ($existing) {
            return (int) $existing->id;
        }

        $data = [
            $nameColumn => $name,
            'created_at' => now(),
            'updated_at' => now(),
        ];

        if ($codeColumn) {
            $data[$codeColumn] = strtoupper(substr(preg_replace('/[^A-Za-z0-9]+/', '-', $name), 0, 30));
        }

        if (Schema::hasColumn($table, 'is_active')) {
            $data['is_active'] = true;
        }

        if (Schema::hasColumn($table, 'status')) {
            $data['status'] = 'active';
        }

        return (int) DB::table($table)->insertGetId($this->filterColumns($table, $data));
    }

    private function defaultUserId(): ?int
    {
        if (! Schema::hasTable('users')) {
            return null;
        }

        $id = DB::table('users')->value('id');

        return $id ? (int) $id : null;
    }

    private function firstColumn(string $table, array $columns): ?string
    {
        foreach ($columns as $column) {
            if (Schema::hasColumn($table, $column)) {
                return $column;
            }
        }

        return null;
    }

    private function filterColumns(string $table, array $data): array
    {
        return collect($data)
            ->filter(fn ($value, string $column): bool => Schema::hasColumn($table, $column))
            ->all();
    }
}