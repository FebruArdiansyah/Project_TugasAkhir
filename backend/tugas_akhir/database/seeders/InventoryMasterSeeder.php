<?php

namespace Database\Seeders;

use App\Models\Customer;
use App\Models\ProductCategory;
use App\Models\ProductDensity;
use App\Models\ProductType;
use App\Models\Supplier;
use App\Models\Unit;
use App\Models\Warehouse;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;

class InventoryMasterSeeder extends Seeder
{
    public function run(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Logo Produk
        |--------------------------------------------------------------------------
        | Logo akan dicopy otomatis dari:
        | database/seeders/assets/product-logos
        |
        | Ke:
        | storage/app/public/products/logos
        */
        $this->prepareProductLogos();

        /*
        |--------------------------------------------------------------------------
        | Unit / Satuan
        |--------------------------------------------------------------------------
        */
        Unit::updateOrCreate(
            ['code' => 'PCS'],
            [
                'name' => 'Pieces',
            ]
        );

        Unit::updateOrCreate(
            ['code' => 'ROLL'],
            [
                'name' => 'Roll',
            ]
        );

        Unit::updateOrCreate(
            ['code' => 'PACK'],
            [
                'name' => 'Pack',
            ]
        );

        /*
        |--------------------------------------------------------------------------
        | Gudang
        |--------------------------------------------------------------------------
        */
        Warehouse::updateOrCreate(
            ['code' => 'GDG-001'],
            [
                'name' => 'Gudang Utama',
                'address' => 'Gudang utama PT Naura Sukses Abadi',
                'phone' => null,
                'is_active' => true,
            ]
        );

        Warehouse::updateOrCreate(
            ['code' => 'GDG-002'],
            [
                'name' => 'Gudang Jatake',
                'address' => 'Gudang Jatake',
                'phone' => null,
                'is_active' => true,
            ]
        );

        Warehouse::updateOrCreate(
            ['code' => 'GDG-003'],
            [
                'name' => 'Gudang Bandung',
                'address' => 'Gudang Bandung',
                'phone' => null,
                'is_active' => true,
            ]
        );

        /*
        |--------------------------------------------------------------------------
        | Jenis Produk
        |--------------------------------------------------------------------------
        */
        $productTypes = [
            'EON',
            'ROYAL',
            'SUPREME',
            'INOAC',
            'QUANTUM',
            'YELLOW',
            'BIGLAND',
            'BLP4',
            'COVER',
            'BANTAL',
            'AKSESORIS',
            'UMUM',
        ];

        foreach ($productTypes as $type) {
            ProductType::updateOrCreate(
                ['name' => $type],
                [
                    'is_active' => true,
                ]
            );
        }

        /*
        |--------------------------------------------------------------------------
        | Density Produk
        |--------------------------------------------------------------------------
        */
        $densities = [
            'D-16',
            'D-16H',
            'D-18',
            'D-20',
            'D-22',
            'D-23',
            'D-24',
            'D-26',
            'D-28',
            'D-30',
            'UMUM',
        ];

        foreach ($densities as $density) {
            ProductDensity::updateOrCreate(
                ['name' => $density],
                [
                    'is_active' => true,
                ]
            );
        }

        /*
        |--------------------------------------------------------------------------
        | Kategori Produk
        |--------------------------------------------------------------------------
        */
        $categories = [
            'LG++',
            'KASUR STANDAR',
            'KASUR LIPAT',
            'KASUR LIPAT 4',
            'SOFA BED',
            'COVER KASUR',
            'BANTAL',
            'ALAS GOSOK',
            'VACUM',
            'KARUNG',
            'AKSESORIS',
            'UMUM',
        ];

        foreach ($categories as $category) {
            ProductCategory::updateOrCreate(
                ['name' => $category],
                [
                    'is_active' => true,
                ]
            );
        }

        /*
        |--------------------------------------------------------------------------
        | Supplier
        |--------------------------------------------------------------------------
        */
        Supplier::updateOrCreate(
            ['code' => 'SUP-001'],
            [
                'name' => 'PT Sumber Foam',
                'phone' => null,
                'address' => 'Tangerang',
                'is_active' => true,
            ]
        );

        Supplier::updateOrCreate(
            ['code' => 'SUP-002'],
            [
                'name' => 'CV Makmur Jaya',
                'phone' => null,
                'address' => 'Jakarta',
                'is_active' => true,
            ]
        );

        Supplier::updateOrCreate(
            ['code' => 'SUP-003'],
            [
                'name' => 'PT Naura Sukses Abadi',
                'phone' => null,
                'address' => 'Tangerang',
                'is_active' => true,
            ]
        );

        Supplier::updateOrCreate(
            ['code' => 'SUP-004'],
            [
                'name' => 'Supplier Umum',
                'phone' => null,
                'address' => null,
                'is_active' => true,
            ]
        );

        /*
        |--------------------------------------------------------------------------
        | Customer
        |--------------------------------------------------------------------------
        */
        Customer::updateOrCreate(
            ['code' => 'CUS-001'],
            [
                'name' => 'CV Sumber Jaya',
                'phone' => null,
                'address' => 'Tangerang',
                'customer_type' => 'customer',
                'is_active' => true,
            ]
        );

        Customer::updateOrCreate(
            ['code' => 'CUS-002'],
            [
                'name' => 'PT Maju Bersama',
                'phone' => null,
                'address' => 'Jakarta',
                'customer_type' => 'customer',
                'is_active' => true,
            ]
        );

        Customer::updateOrCreate(
            ['code' => 'CUS-003'],
            [
                'name' => 'CENTRAL FOAM',
                'phone' => null,
                'address' => null,
                'customer_type' => 'customer',
                'is_active' => true,
            ]
        );

        Customer::updateOrCreate(
            ['code' => 'CUS-004'],
            [
                'name' => 'AHM / YELI',
                'phone' => null,
                'address' => null,
                'customer_type' => 'customer',
                'is_active' => true,
            ]
        );

        Customer::updateOrCreate(
            ['code' => 'CUS-005'],
            [
                'name' => 'Customer Umum',
                'phone' => null,
                'address' => null,
                'customer_type' => 'customer',
                'is_active' => true,
            ]
        );

        /*
        |--------------------------------------------------------------------------
        | Master Produk Naura
        |--------------------------------------------------------------------------
        */
        $this->call(ProductNauraSeeder::class);
    }

    private function prepareProductLogos(): void
    {
        Storage::disk('public')->makeDirectory('products/logos');

        $sourcePath = database_path('seeders/assets/product-logos');

        if (! File::exists($sourcePath)) {
            return;
        }

        foreach (File::files($sourcePath) as $file) {
            Storage::disk('public')->put(
                'products/logos/' . $file->getFilename(),
                File::get($file->getPathname())
            );
        }
    }
}