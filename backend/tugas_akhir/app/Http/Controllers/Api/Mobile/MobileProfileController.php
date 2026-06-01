<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

final class MobileProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $user = $request->user()->load(['profile', 'roles']);
        $profile = $user->profile;

        $warehouse = null;

        if ($profile?->warehouse_id) {
            $warehouse = DB::table('warehouses')
                ->where('id', $profile->warehouse_id)
                ->first(['id', 'code', 'name', 'address', 'phone']);
        }

        $inboundCount = DB::table('inbound_transactions')
            ->where('submitted_by', $user->id)
            ->count();

        $outboundCount = DB::table('outbound_transactions')
            ->where('submitted_by', $user->id)
            ->count();

        $stockCount = 0;

        if ($profile?->warehouse_id) {
            $stockCount = DB::table('stock_balances')
                ->where('warehouse_id', $profile->warehouse_id)
                ->where('qty_on_hand', '>', 0)
                ->count();
        }

        return response()->json([
            'success' => true,
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'avatar_url' => $user->avatar_url ? asset('storage/'.$user->avatar_url) : null,
                    'name' => $user->name,
                    'email' => $user->email,
                    'roles' => $user->getRoleNames()->values(),
                ],
                'profile' => [
                    'username' => $profile?->username,
                    'phone' => $profile?->phone,
                    'employee_code' => $profile?->employee_code,
                    'position' => $profile?->position,
                    'address' => $profile?->address,
                    'is_active' => (bool) ($profile?->is_active ?? true),
                    'last_login_at' => $profile?->last_login_at,
                ],
                'warehouse' => $warehouse,
                'stats' => [
                    'inbound_count' => $inboundCount,
                    'outbound_count' => $outboundCount,
                    'stock_count' => $stockCount,
                ],
            ],
        ]);
    }
}