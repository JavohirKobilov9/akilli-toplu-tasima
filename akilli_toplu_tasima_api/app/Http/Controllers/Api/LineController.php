<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Line;
use App\Models\LineSchedule;

class LineController extends Controller
{
    // Aktif hatları getir
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

    // Seçilen hatta ait durakları getir
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

    // Seçilen hatta ait sefer saatlerini getir
    public function schedules(Line $line)
    {
        $schedules = LineSchedule::where(
            'line_id',
            $line->id
        )
            ->orderBy('service_period')
            ->orderBy('direction')
            ->orderBy('departure_time')
            ->get();

        return response()->json([
            'success' => true,
            'line' => $line,
            'data' => $schedules,
        ]);
    }
}