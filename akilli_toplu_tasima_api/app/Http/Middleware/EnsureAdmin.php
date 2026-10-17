<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureAdmin
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        if (
            !$user ||
            !in_array(
                $user->role,
                ['admin', 'super_admin'],
                true
            )
        ) {
            return response()->json([
                'success' => false,
                'message' =>
                    'Bu işlem için yönetici yetkisi gereklidir.',
            ], 403);
        }

        return $next($request);
    }
}