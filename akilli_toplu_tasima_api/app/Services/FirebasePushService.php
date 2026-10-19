<?php

namespace App\Services;

use App\Models\ComplaintNotification;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FirebasePushService
{
    private function httpClient()
    {
        $client = Http::timeout(8);
        $bundle = config('services.firebase.ca_bundle');
        return $bundle ? $client->withOptions(['verify' => $bundle]) : $client;
    }

    public function validateConnection(): array
    {
        $path = config('services.firebase.credentials');
        $project = config('services.firebase.project_id');
        if (!$project || !$path || !is_readable($path)) {
            return ['success' => false, 'status' => 'CONFIGURATION_MISSING'];
        }
        $token = $this->accessToken($path, $project);
        // Yalnızca doğrulama: hiçbir telefona veya konu abonesine mesaj gönderilmez.
        $response = $this->httpClient()->withToken($token)->timeout(15)->post(
            'https://fcm.googleapis.com/v1/projects/' . rawurlencode($project) . '/messages:send',
            [
                'validate_only' => true,
                'message' => [
                    'topic' => 'connection-check',
                    'notification' => ['title' => 'Bağlantı kontrolü', 'body' => 'Yalnızca doğrulama'],
                ],
            ]
        );

        return [
            'success' => $response->successful(),
            'status' => $response->successful() ? 'OK' : $response->json('error.status'),
            'reason' => collect($response->json('error.details') ?? [])->pluck('reason')->filter()->first(),
            'http_status' => $response->status(),
        ];
    }

    public function send(ComplaintNotification $notification): void
    {
        $path = config('services.firebase.credentials');
        $project = config('services.firebase.project_id');
        if (!$path || !$project) {
            return; // Firebase bağlanana kadar uygulama içi bildirimler çalışır.
        }

        try {
            $devices = DB::table('push_devices')->where('user_id', $notification->user_id)->get();
            if ($devices->isEmpty()) {
                return;
            }
            $accessToken = $this->accessToken($path, $project);
            foreach ($devices as $device) {
                $response = $this->httpClient()->withToken($accessToken)->post(
                    'https://fcm.googleapis.com/v1/projects/' . rawurlencode($project) . '/messages:send',
                    ['message' => [
                        'token' => $device->token,
                        'notification' => [
                            'title' => $notification->title,
                            'body' => $notification->message,
                        ],
                        'data' => [
                            'notification_id' => (string) $notification->id,
                            'complaint_id' => (string) $notification->complaint_id,
                        ],
                        'android' => ['priority' => 'high'],
                        'apns' => ['payload' => ['aps' => ['sound' => 'default']]],
                    ]]
                );
                $details = $response->json('error.details') ?? [];
                $unregistered = collect($details)->contains(fn ($item) =>
                    ($item['errorCode'] ?? null) === 'UNREGISTERED'
                );
                if ($unregistered) {
                    DB::table('push_devices')->where('id', $device->id)->delete();
                } elseif (!$response->successful()) {
                    if ($response->status() === 401) {
                        Cache::forget('fcm-oauth:' . hash('sha256', $project . ':' . $path));
                    }
                    Log::warning('FCM bildirimi gönderilemedi.', [
                        'notification_id' => $notification->id,
                        'http_status' => $response->status(),
                    ]);
                }
            }
        } catch (\Throwable $e) {
            // Anahtar, cihaz tokenı veya kişisel içerik loglara yazılmaz.
            Log::warning('FCM bağlantısı kurulamadı.', ['notification_id' => $notification->id]);
        }
    }

    private function accessToken(string $path, string $project): string
    {
        return Cache::remember('fcm-oauth:' . hash('sha256', $project . ':' . $path), 3000, function () use ($path) {
            $credentials = json_decode(file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);
            $encode = fn ($value) => rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
            $time = time();
            $header = $encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $claims = $encode(json_encode([
                'iss' => $credentials['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $time,
                'exp' => $time + 3600,
            ]));
            $unsigned = $header . '.' . $claims;
            if (!openssl_sign($unsigned, $signature, $credentials['private_key'], OPENSSL_ALGO_SHA256)) {
                throw new \RuntimeException('Firebase OAuth imzası oluşturulamadı.');
            }
            $response = $this->httpClient()->asForm()->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $unsigned . '.' . $encode($signature),
            ])->throw();
            $token = $response->json('access_token');
            if (!is_string($token) || $token === '') {
                throw new \RuntimeException('Firebase OAuth yanıtı geçersiz.');
            }
            return $token;
        });
    }
}
