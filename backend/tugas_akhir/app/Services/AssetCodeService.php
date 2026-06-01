<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class AssetCodeService
{
    public function nextAssetCategoryCode(): string
    {
        return $this->nextCode('asset_categories', 'code', 'AST-CAT');
    }

    public function nextAssetLocationCode(): string
    {
        return $this->nextCode('asset_locations', 'code', 'AST-LOC');
    }

    public function nextAssetCode(): string
    {
        return $this->nextCode('assets', 'asset_code', 'AST');
    }

    private function nextCode(string $table, string $column, string $prefix, int $padding = 3): string
    {
        $codes = DB::table($table)
            ->whereNotNull($column)
            ->where($column, 'like', $prefix . '-%')
            ->pluck($column);

        $lastNumber = 0;

        foreach ($codes as $code) {
            if (preg_match('/^' . preg_quote($prefix, '/') . '-(\d+)$/', (string) $code, $matches)) {
                $number = (int) $matches[1];

                if ($number > $lastNumber) {
                    $lastNumber = $number;
                }
            }
        }

        return $prefix . '-' . str_pad((string) ($lastNumber + 1), $padding, '0', STR_PAD_LEFT);
    }
}