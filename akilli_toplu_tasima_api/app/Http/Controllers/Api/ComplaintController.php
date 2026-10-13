<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Complaint;
use App\Models\Line;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class ComplaintController extends Controller
{
     
public function destroy(
    Request $request,
    Complaint $complaint
) {
    if (
        $complaint->user_id !==
        $request->user()->id
    ) {
        return response()->json([
            'success' => false,
            'message' =>
                'Bu şikayeti silme yetkiniz yok.',
        ], 403);
    }

    $complaint->delete();

    return response()->json([
        'success' => true,
        'message' =>
            'Şikayet başarıyla silindi.',
    ]);
}
    // Tüm şikayetleri getirir
    public function index()
    {
        $complaints = Complaint::with(['line', 'stop'])
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $complaints,
        ]);
    }

    public function myComplaints(Request $request)
{
    $complaints = Complaint::with([
        'line',
        'stop',
    ])
        ->where(
            'user_id',
            $request->user()->id
        )
        ->latest()
        ->get();

    return response()->json([
        'success' => true,
        'data' => $complaints,
    ]);
}   

    // Yeni şikayet oluşturur
   public function store(Request $request)
{
    $validated = $request->validate([
        'title' => 'required|string|max:255',
        'category' => 'required|string|max:100',
        'description' => 'required|string|min:10',
        'line_id' => 'required|integer|exists:lines,id',

        // Durak artık zorunlu değil
        'stop_id' => 'nullable|integer|exists:stops,id',

        'latitude' => 'nullable|numeric|between:-90,90',
        'longitude' => 'nullable|numeric|between:-180,180',
    ]);

    $line = Line::findOrFail($validated['line_id']);

    // Sadece stop_id gönderilmişse kontrol et
    if (!empty($validated['stop_id'])) {
        $stopBelongsToLine = $line->stops()
            ->where('stops.id', $validated['stop_id'])
            ->exists();

        if (!$stopBelongsToLine) {
            throw ValidationException::withMessages([
                'stop_id' => [
                    'Seçilen durak, seçilen hatta ait değildir.',
                ],
            ]);
        }
    }

    $complaint = Complaint::create([
        'user_id' => $request->user()->id,
        'title' => $validated['title'],
        'category' => $validated['category'],
        'description' => $validated['description'],
        'line_id' => $validated['line_id'],
        'stop_id' => $validated['stop_id'] ?? null,
        'latitude' => $validated['latitude'] ?? null,
        'longitude' => $validated['longitude'] ?? null,
        'status' => 'Beklemede',
    ]);

    $complaint->load(['line', 'stop']);

    return response()->json([
        'success' => true,
        'message' => 'Şikayet başarıyla oluşturuldu.',
        'data' => $complaint,
    ], 201);
}

    // Tek bir şikayeti getirir
    public function show(Complaint $complaint)
    {
        $complaint->load(['line', 'stop']);

        return response()->json([
            'success' => true,
            'data' => $complaint,
        ]);
    }

    // Şikayet durumunu günceller
    public function updateStatus(
        Request $request,
        Complaint $complaint
    ) {
        $validated = $request->validate([
            'status' => 'required|in:Beklemede,İnceleniyor,Çözüldü',
        ]);

        $complaint->update([
            'status' => $validated['status'],
        ]);

        $complaint->load(['line', 'stop']);

        return response()->json([
            'success' => true,
            'message' => 'Şikayet durumu güncellendi.',
            'data' => $complaint,
        ]);
    }
}