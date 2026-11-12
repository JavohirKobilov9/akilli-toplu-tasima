<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Line;
use App\Models\LineSchedule;
use Illuminate\Http\Request;

class LineController extends Controller
{
    public function adminIndex()
    {
        return response()->json(['success' => true, 'data' => Line::orderBy('code')->get()]);
    }

    public function adminShow(Line $line)
    {
        return response()->json(['success' => true, 'data' => $line]);
    }

    

public function adminUpdate(Request $request, Line $line)
{
    $data = $request->validate([
        'name' => ['sometimes', 'required', 'string', 'max:255'],
        'transport_type' => ['sometimes', 'required', 'string', 'max:255'],
        'start_point' => ['sometimes', 'nullable', 'string', 'max:255'],
        'end_point' => ['sometimes', 'nullable', 'string', 'max:255'],

        // GeoJSON guzergah koordinatlari
        'route_geometry' => ['sometimes', 'required', 'array'],
        'route_geometry.type' => [
            'required_with:route_geometry',
            'in:LineString',
        ],
        'route_geometry.coordinates' => [
            'required_with:route_geometry',
            'array',
            'min:2',
            'max:5000',
        ],
        'route_geometry.coordinates.*' => [
            'array',
            'size:2',
        ],
        'route_geometry.coordinates.*.0' => [
            'required',
            'numeric',
            'between:-180,180',
        ],
        'route_geometry.coordinates.*.1' => [
            'required',
            'numeric',
            'between:-90,90',
        ],

        // Korunan alanlar
        'code' => ['prohibited'],
        'is_active' => ['prohibited'],
        'geometry' => ['prohibited'],
        'stops' => ['prohibited'],
    ]);

    $guzergah = $data['route_geometry'] ?? null;
    unset($data['route_geometry']);

    $line->fill($data);

    if ($guzergah !== null) {
        $line->route_geometry = [
            'type' => 'LineString',
            'coordinates' => array_map(
                fn ($nokta) => [
                    (float) $nokta[0],
                    (float) $nokta[1],
                ],
                $guzergah['coordinates']
            ),
        ];
    }

    $line->save();

    return response()->json([
        'success' => true,
        'data' => $line->fresh(),
    ]);
}


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

    // Konumu olan tüm aktif durakları, geçen hat kodlarıyla getir (yakın durak özelliği için).
    public function allStops()
    {
        $stops = \App\Models\Stop::where('is_active', true)
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->with(['lines' => fn ($q) => $q->select('lines.id', 'lines.code', 'lines.name')])
            ->orderBy('name')
            ->get(['id', 'code', 'name', 'district', 'latitude', 'longitude']);

        return response()->json([
            'success' => true,
            'data' => $stops,
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
