<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Line;

class LineController extends Controller
{
    // Bütün aktif hatları getirir
    public function index()
    {
        $lines = Line::where('is_active', true)
            ->orderBy('code')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $lines,
        ]);
    }

    // Seçilen hatta ait durakları getirir
    public function stops(Line $line)
    {
        $stops = $line->stops()
            ->where('stops.is_active', true)
            ->get();

        return response()->json([
            'success' => true,
            'line' => $line,
            'data' => $stops,
        ]);
    }
}