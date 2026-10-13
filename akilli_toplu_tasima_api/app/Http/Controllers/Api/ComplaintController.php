<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Complaint;
use App\Models\Line;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class ComplaintController extends Controller
{
    // Kullanıcının yalnızca kendi şikayetini silmesini sağlar.
    public function destroy(
        Request $request,
        Complaint $complaint
    ) {
        if (
            (int) $complaint->user_id !==
            (int) $request->user()->id
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

    // Tüm şikayetleri getirir.
    public function index()
    {
        $complaints = Complaint::with([
            'line',
            'stop',
        ])
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $complaints,
        ]);
    }

    // Giriş yapan kullanıcının şikayetlerini getirir.
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

    // Yeni şikayet oluşturur.
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' =>
                'required|string|max:255',
            'category' =>
                'required|string|max:100',
            'description' =>
                'required|string|min:10',
            'line_id' =>
                'required|integer|exists:lines,id',
            'stop_id' =>
                'nullable|integer|exists:stops,id',
            'latitude' =>
                'nullable|numeric|between:-90,90',
            'longitude' =>
                'nullable|numeric|between:-180,180',
        ]);

        // Başlığın ilk harfini büyütür.
        $title = $this->formatTitle(
            $validated['title']
        );

        // Açıklamanın başındaki ve sonundaki gereksiz boşlukları temizler.
        $description = trim(
            $validated['description']
        );

        // Başlık veya açıklamada yasaklı kelime/ifade varsa kaydetmez.
        if (
            $this->containsForbiddenLanguage(
                $title
            ) ||
            $this->containsForbiddenLanguage(
                $description
            )
        ) {
            return response()->json([
                'success' => false,
                'message' =>
                    'Şikayet metninde uygun olmayan ifadeler bulunmaktadır. Lütfen metni düzenleyiniz.',
            ], 422);
        }

        $line = Line::findOrFail(
            $validated['line_id']
        );

        // Durak seçildiyse, seçilen hatta ait olup olmadığını kontrol eder.
        if (!empty($validated['stop_id'])) {
            $stopBelongsToLine =
                $line->stops()
                    ->where(
                        'stops.id',
                        $validated['stop_id']
                    )
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
            'user_id' =>
                $request->user()->id,
            'title' =>
                $title,
            'category' =>
                $validated['category'],
            'description' =>
                $description,
            'line_id' =>
                $validated['line_id'],
            'stop_id' =>
                $validated['stop_id'] ?? null,
            'latitude' =>
                $validated['latitude'] ?? null,
            'longitude' =>
                $validated['longitude'] ?? null,
            'status' =>
                'Beklemede',
        ]);

        $complaint->load([
            'line',
            'stop',
        ]);

        return response()->json([
            'success' => true,
            'message' =>
                'Şikayet başarıyla oluşturuldu.',
            'data' => $complaint,
        ], 201);
    }

    // Tek bir şikayeti getirir.
    public function show(Complaint $complaint)
    {
        $complaint->load([
            'line',
            'stop',
        ]);

        return response()->json([
            'success' => true,
            'data' => $complaint,
        ]);
    }

    // Şikayet durumunu günceller.
    public function updateStatus(
        Request $request,
        Complaint $complaint
    ) {
        $validated = $request->validate([
            'status' =>
                'required|in:Beklemede,İnceleniyor,Çözüldü',
        ]);

        $complaint->update([
            'status' =>
                $validated['status'],
        ]);

        $complaint->load([
            'line',
            'stop',
        ]);

        return response()->json([
            'success' => true,
            'message' =>
                'Şikayet durumu güncellendi.',
            'data' => $complaint,
        ]);
    }

    // Küfür/hakaret kontrolü için metni standartlaştırır.
    // Bu işlem kullanıcının kaydedilecek metnini değiştirmez.
    private function normalizeText(
        string $text
    ): string {
        $text = mb_strtolower(
            $text,
            'UTF-8'
        );

        $text = str_replace(
            ['ç', 'ğ', 'ı', 'ö', 'ş', 'ü'],
            ['c', 'g', 'i', 'o', 's', 'u'],
            $text
        );

        // Noktalama işaretlerini boşluğa çevirir.
        $text = preg_replace(
            '/[^a-z0-9\s]/u',
            ' ',
            $text
        );

        // Birden fazla boşluğu tek boşluğa indirir.
        $text = preg_replace(
            '/\s+/',
            ' ',
            $text
        );

        return trim($text);
    }

    // config/profanity.php içindeki yasaklı kelime ve ifadeleri kontrol eder.
    private function containsForbiddenLanguage(
        string $text
    ): bool {
        $normalizedText =
            $this->normalizeText($text);

        $searchableText =
            ' ' . $normalizedText . ' ';

        foreach (
            config('profanity.words', [])
            as $forbiddenWord
        ) {
            $normalizedForbidden =
                $this->normalizeText(
                    $forbiddenWord
                );

            if ($normalizedForbidden === '') {
                continue;
            }

            $searchableForbidden =
                ' ' .
                $normalizedForbidden .
                ' ';

            if (
                str_contains(
                    $searchableText,
                    $searchableForbidden
                )
            ) {
                return true;
            }
        }

        return false;
    }

    // Başlıktaki ilk harfi Türkçe karakterleri de dikkate alarak büyütür.
    // Başlığın geri kalanına dokunmaz.
    private function formatTitle(
        string $title
    ): string {
        $title = trim($title);

        if ($title === '') {
            return $title;
        }

        return preg_replace_callback(
            '/\p{L}/u',
            function ($matches) {
                $firstLetter =
                    $matches[0];

                $turkishUppercase = [
                    'i' => 'İ',
                    'ı' => 'I',
                    'ş' => 'Ş',
                    'ğ' => 'Ğ',
                    'ü' => 'Ü',
                    'ö' => 'Ö',
                    'ç' => 'Ç',
                ];

                return $turkishUppercase[
                    $firstLetter
                ] ??
                    mb_strtoupper(
                        $firstLetter,
                        'UTF-8'
                    );
            },
            $title,
            1
        );
    }
}
