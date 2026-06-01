<?php

namespace Database\Seeders;

use App\Models\Customer;
use App\Models\Product;
use App\Models\ProductCategory;
use App\Models\ProductDensity;
use App\Models\ProductType;
use App\Models\Supplier;
use App\Models\Unit;
use App\Models\Warehouse;
use Illuminate\Database\Seeder;

class InventoryMasterSeeder extends Seeder
{
    public function run(): void
    {
        $pcs = Unit::updateOrCreate(
            ['code' => 'PCS'],
            ['name' => 'Pieces']
        );

        Unit::updateOrCreate(
            ['code' => 'ROLL'],
            ['name' => 'Roll']
        );

        Unit::updateOrCreate(
            ['code' => 'PACK'],
            ['name' => 'Pack']
        );

        $gudangUtama = Warehouse::updateOrCreate(
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

        $eon = ProductType::updateOrCreate(
            ['name' => 'EON'],
            ['is_active' => true]
        );

        $royal = ProductType::updateOrCreate(
            ['name' => 'ROYAL'],
            ['is_active' => true]
        );

        $supreme = ProductType::updateOrCreate(
            ['name' => 'SUPREME'],
            ['is_active' => true]
        );

        $d22 = ProductDensity::updateOrCreate(
            ['name' => 'D-22'],
            ['is_active' => true]
        );

        $d23 = ProductDensity::updateOrCreate(
            ['name' => 'D-23'],
            ['is_active' => true]
        );

        $d24 = ProductDensity::updateOrCreate(
            ['name' => 'D-24'],
            ['is_active' => true]
        );

        $lgPlus = ProductCategory::updateOrCreate(
            ['name' => 'LG++'],
            ['is_active' => true]
        );

        $vacumCategory = ProductCategory::updateOrCreate(
            ['name' => 'VACUM'],
            ['is_active' => true]
        );

        $karungCategory = ProductCategory::updateOrCreate(
            ['name' => 'KARUNG'],
            ['is_active' => true]
        );

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

        Product::updateOrCreate(
            ['code' => 'BRG-001'],
            [
                'name' => 'EON 200x145x30',
                'product_type_id' => $eon->id,
                'product_density_id' => $d22->id,
                'product_category_id' => $lgPlus->id,
                'unit_id' => $pcs->id,
                'length' => 200,
                'width' => 145,
                'thickness' => 30,
                'size_text' => '200 x 145 x 30 CM',
                'full_name' => 'EON D-22 LG++ 200 x 145 x 30 CM',
                'default_purchase_price' => 500000,
                'default_selling_price' => 650000,
                'last_purchase_price' => 0,
                'last_selling_price' => 0,
                'description' => null,
                'is_active' => true,
            ]
        );

        Product::updateOrCreate(
            ['code' => 'BRG-002'],
            [
                'name' => 'ROYAL 180x200x20',
                'product_type_id' => $royal->id,
                'product_density_id' => $d23->id,
                'product_category_id' => $lgPlus->id,
                'unit_id' => $pcs->id,
                'length' => 180,
                'width' => 200,
                'thickness' => 20,
                'size_text' => '180 x 200 x 20 CM',
                'full_name' => 'ROYAL D-23 LG++ 180 x 200 x 20 CM',
                'default_purchase_price' => 600000,
                'default_selling_price' => 800000,
                'last_purchase_price' => 0,
                'last_selling_price' => 0,
                'description' => null,
                'is_active' => true,
            ]
        );

        Product::updateOrCreate(
            ['code' => 'BRG-003'],
            [
                'name' => 'SUPREME 160x200x25',
                'product_type_id' => $supreme->id,
                'product_density_id' => $d24->id,
                'product_category_id' => $lgPlus->id,
                'unit_id' => $pcs->id,
                'length' => 160,
                'width' => 200,
                'thickness' => 25,
                'size_text' => '160 x 200 x 25 CM',
                'full_name' => 'SUPREME D-24 LG++ 160 x 200 x 25 CM',
                'default_purchase_price' => 700000,
                'default_selling_price' => 950000,
                'last_purchase_price' => 0,
                'last_selling_price' => 0,
                'description' => null,
                'is_active' => true,
            ]
        );

        Product::updateOrCreate(
            ['code' => 'BRG-005'],
            [
                'name' => 'VACUM',
                'product_type_id' => null,
                'product_density_id' => null,
                'product_category_id' => $vacumCategory->id,
                'unit_id' => $pcs->id,
                'length' => null,
                'width' => null,
                'thickness' => null,
                'size_text' => null,
                'full_name' => 'VACUM',
                'default_purchase_price' => 0,
                'default_selling_price' => 0,
                'last_purchase_price' => 0,
                'last_selling_price' => 0,
                'description' => 'Tambahan cepat untuk barang keluar',
                'is_active' => true,
            ]
        );

        Product::updateOrCreate(
            ['code' => 'BRG-006'],
            [
                'name' => 'KARUNG',
                'product_type_id' => null,
                'product_density_id' => null,
                'product_category_id' => $karungCategory->id,
                'unit_id' => $pcs->id,
                'length' => null,
                'width' => null,
                'thickness' => null,
                'size_text' => null,
                'full_name' => 'KARUNG',
                'default_purchase_price' => 0,
                'default_selling_price' => 0,
                'last_purchase_price' => 0,
                'last_selling_price' => 0,
                'description' => 'Tambahan cepat untuk barang keluar',
                'is_active' => true,
            ]
        );
    }
}