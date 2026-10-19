<?php

namespace App\Console\Commands;

use App\Services\FirebasePushService;
use Illuminate\Console\Command;

class CheckFirebaseConnection extends Command
{
    protected $signature = 'notifications:check-firebase';
    protected $description = 'Gerçek bildirim göndermeden Firebase kimlik doğrulamasını ve FCM yetkisini kontrol eder.';

    public function handle(FirebasePushService $firebase): int
    {
        try {
            $result = $firebase->validateConnection();
        } catch (\Throwable $e) {
            // HTTP hata içeriği, OAuth tokenı ve özel anahtar çıktıya yazılmaz.
            $this->error('Firebase kimlik doğrulaması veya ağ bağlantısı başarısız.');
            if ($e instanceof \Illuminate\Http\Client\RequestException) {
                $this->line('HTTP: ' . $e->response->status());
                $error = $e->response->json('error');
                if (is_string($error) && preg_match('/^[a-z_]+$/', $error)) {
                    $this->line('OAuth: ' . $error);
                }
            } elseif (preg_match('/cURL error (\d+)/', $e->getMessage(), $matches)) {
                $this->line('cURL hata kodu: ' . $matches[1]);
            } else {
                $this->line('Hata türü: ' . get_class($e));
            }
            return self::FAILURE;
        }
        if (!$result['success']) {
            $this->error('Firebase kontrolü başarısız: ' . ($result['status'] ?? 'UNKNOWN'));
            if (!empty($result['reason'])) {
                $this->line('Neden: ' . $result['reason']);
            }
            return self::FAILURE;
        }
        $this->info('Firebase kimlik doğrulaması ve FCM gönderim yetkisi doğrulandı.');
        $this->line('Gerçek bildirim gönderilmedi. Cihaz teslim testi ayrıca yapılmalıdır.');
        return self::SUCCESS;
    }
}
