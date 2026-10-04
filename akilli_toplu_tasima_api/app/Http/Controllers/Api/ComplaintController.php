<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Complaint;
use App\Models\Line;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class ComplaintController extends Controller
{
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

    // Yeni şikayet oluşturur
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'category' => 'required|string|max:100',
            'description' => 'required|string|min:10',
            'line_id' => 'required|integer|exists:lines,id',
            'stop_id' => 'required|integer|exists:stops,id',
        ]);

        $line = Line::findOrFail($validated['line_id']);

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

        $complaint = Complaint::create([
            'user_id' => null,
            'title' => $validated['title'],
            'category' => $validated['category'],
            'description' => $validated['description'],
            'line_id' => $validated['line_id'],
            'stop_id' => $validated['stop_id'],
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
}