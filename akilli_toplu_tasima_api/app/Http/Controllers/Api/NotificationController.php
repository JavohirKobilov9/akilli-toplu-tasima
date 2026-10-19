<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ComplaintNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $query = ComplaintNotification::where('user_id', $request->user()->id);

        return response()->json([
            'success' => true,
            'unread_count' => (clone $query)->whereNull('read_at')->count(),
            'data' => $query->orderByDesc('id')->paginate(30),
        ]);
    }

    public function read(Request $request, int $notification)
    {
        $item = ComplaintNotification::where('user_id', $request->user()->id)
            ->findOrFail($notification);
        if ($item->read_at === null) {
            $item->update(['read_at' => now()]);
        }

        return response()->json(['success' => true, 'data' => $item]);
    }

    public function registerDevice(Request $request)
    {
        $data = $request->validate(['token' => 'required|string|max:4096']);
        DB::table('push_devices')->updateOrInsert(
            ['token_hash' => hash('sha256', $data['token'])],
            [
                'user_id' => $request->user()->id,
                'personal_access_token_id' => $request->user()->currentAccessToken()?->id,
                'token' => $data['token'],
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );

        return response()->json(['success' => true]);
    }

    public function removeDevice(Request $request)
    {
        $data = $request->validate(['token' => 'required|string|max:4096']);
        DB::table('push_devices')->where('user_id', $request->user()->id)
            ->where('token_hash', hash('sha256', $data['token']))->delete();

        return response()->json(['success' => true]);
    }
}
