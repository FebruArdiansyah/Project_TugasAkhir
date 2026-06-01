<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

final class MobileAuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'login' => ['required', 'string', 'max:255'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $login = $validated['login'];

        $user = User::query()
            ->with(['profile', 'roles'])
            ->where(function ($query) use ($login): void {
                $query
                    ->where('email', $login)
                    ->orWhereHas('profile', function ($profileQuery) use ($login): void {
                        $profileQuery->where('username', $login);
                    });
            })
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'login' => ['Username/email atau password salah.'],
            ]);
        }

        if ($user->profile && ! (bool) $user->profile->is_active) {
            throw ValidationException::withMessages([
                'login' => ['Akun tidak aktif. Hubungi admin.'],
            ]);
        }

        DB::table('profiles')
            ->where('user_id', $user->id)
            ->update([
                'last_login_at' => now(),
            ]);

        $token = $user
            ->createToken($validated['device_name'] ?? 'mobile-app')
            ->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil.',
            'token_type' => 'Bearer',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'avatar_url' => $user->avatar_url ? asset('storage/'.$user->avatar_url) : null,
                'name' => $user->name,
                'email' => $user->email,
                'username' => $user->profile?->username,
                'employee_code' => $user->profile?->employee_code,
                'position' => $user->profile?->position,
                'warehouse_id' => $user->profile?->warehouse_id,
                'roles' => $user->getRoleNames()->values(),
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil.',
        ]);
    }
}