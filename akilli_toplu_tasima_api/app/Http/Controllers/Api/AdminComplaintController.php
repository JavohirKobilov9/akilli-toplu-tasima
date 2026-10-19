<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Complaint;
use Illuminate\Http\Request;

class AdminComplaintController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        if (!$user || !in_array($user->role, ['admin', 'super_admin'], true)) {
            return response()->json([
                'success' => false,
                'message' => 'Bu işlem için yönetici yetkisi gerekiyor.',
            ], 403);
        }

        $complaints = Complaint::with([
            'line:id,code,name',
            'stop:id,name',
            'user:id,name,email,phone',
        ])->latest()->get();

        $data = $complaints->map(function (Complaint $complaint) {

            $isGuest = $complaint->user_id === null
                && (
                    $complaint->guest_email_verified_at !== null
                    || $complaint->guest_phone_verified_at !== null
                );

            $userName = $complaint->user?->name
                ?? ($isGuest ? 'Misafir Kullanıcı' : 'Silinmiş kullanıcı');

            return [
                'id' => $complaint->id,
                'title' => $complaint->title,
                'category' => $complaint->category,
                'description' => $complaint->description,
                'media_path' => $complaint->media_path,
                'media_type' => $complaint->media_type,
                'latitude' => $complaint->latitude,
                'longitude' => $complaint->longitude,

                'line' => $complaint->line
                    ? [
                        'id' => $complaint->line->id,
                        'code' => $complaint->line->code,
                        'name' => $complaint->line->name,
                    ]
                    : null,

                'stop' => $complaint->stop
                    ? [
                        'id' => $complaint->stop->id,
                        'name' => $complaint->stop->name,
                    ]
                    : null,

                'status' => $complaint->status,
                'created_at' => $complaint->created_at,

                'user_id' => $complaint->user_id,
                'user_name' => $userName,
                'user_display_name' => $userName,

                'user_email' => $complaint->user?->email
                    ?? $complaint->guest_email,

                'user_phone' => $complaint->user?->phone
                    ?? $complaint->guest_phone,

                'is_guest' => $isGuest,
            ];
        })->values();

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }
}
