<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class SyntheticComplaintSeeder extends Seeder
{
    public function run(): void
    {
        // Tekrar çalıştırılırsa ikinci kez veri üretme.
        
$hedefSayi = 100;

$mevcutSayi = DB::table('complaints')
    ->where('is_synthetic', true)
    ->count();

$eklenecekSayi = max(0, $hedefSayi - $mevcutSayi);

if ($eklenecekSayi === 0) {
    $this->command->info(
        'Yeterli sayıda sentetik şikayet mevcut. Yeni kayıt eklenmedi.'
    );
    return;
}

$this->command->info(
    "Mevcut: {$mevcutSayi}, eklenecek: {$eklenecekSayi}"
);


        $lines = DB::table('lines')
            ->where('code', 'like', 'BRT%')
            ->get();

        if ($lines->isEmpty()) {
            throw new \RuntimeException(
                'Bartın hatları bulunamadı.'
            );
        }

        // Her kategori için farklı örnek başlık ve açıklama.
        $templates = [
            'Sefer Gecikmesi' => [
                'Otobüs seferinde gecikme yaşandı',
                'Belirtilen saatte beklenen araç gecikmeli geldi ve yolcular uzun süre beklemek zorunda kaldı.',
            ],
            'Yoğunluk' => [
                'Araçta aşırı yolcu yoğunluğu vardı',
                'Sefer sırasında araç çok kalabalıktı ve yolcuların rahat şekilde seyahat etmesi mümkün olmadı.',
            ],
            'Şoför Davranışı' => [
                'Şoförün yolcularla iletişimi yetersizdi',
                'Araç sürücüsünün yolcuların sorularına karşı daha dikkatli ve anlayışlı davranması gerekiyor.',
            ],
            'Araç Temizliği' => [
                'Otobüsün temizliği yetersizdi',
                'Araç içindeki koltukların ve zeminin temizliğine daha fazla dikkat edilmesi gerekiyor.',
            ],
            'Durak Sorunu' => [
                'Durakta yolcu bilgilendirmesi yetersizdi',
                'Durakta sefer saatleriyle ilgili yeterli bilgilendirme bulunmadığı için yolcular zorluk yaşadı.',
            ],
            'Güzergah Sorunu' => [
                'Güzergah hakkında bilgilendirme eksikti',
                'Sefer güzergahı hakkında daha açık ve güncel bilgilendirme yapılması gerekiyor.',
            ],
            'Diğer' => [
                'Toplu taşıma hizmetiyle ilgili öneri',
                'Toplu taşıma hizmetinin daha verimli olması için sefer düzeninin değerlendirilmesini öneriyorum.',
            ],
        ];

        $distribution = [
            'Sefer Gecikmesi' => 15,
            'Yoğunluk' => 10,
            'Şoför Davranışı' => 8,
            'Araç Temizliği' => 7,
            'Durak Sorunu' => 5,
            'Güzergah Sorunu' => 3,
            'Diğer' => 2,
        ];

       
$statuses = [];

for ($i = 0; $i < $eklenecekSayi; $i++) {
    $statuses[] = match ($i % 5) {
        0, 1 => 'Beklemede',
        2, 3 => 'İnceleniyor',
        default => 'Çözüldü',
    };
}


        
$categories = [];

foreach ($distribution as $category => $count) {
    for ($i = 0; $i < $count; $i++) {
        $categories[] = $category;
    }
}

// Yalnızca eksik sayı kadar yeni şikayet oluştur.
while (count($categories) < $eklenecekSayi) {
    $categories = array_merge(
        $categories,
        array_slice(
            $categories,
            0,
            $eklenecekSayi - count($categories)
        )
    );
}

$categories = array_slice($categories, 0, $eklenecekSayi);


        // Tekrarlanabilir test verileri.
        mt_srand(20261020);

        shuffle($categories);
        shuffle($statuses);

        $records = [];
        $now = Carbon::now();

        foreach ($categories as $index => $category) {
            $line = $lines[$index % $lines->count()];
            [$title, $description] = $templates[$category];

            // Bartın merkezi çevresinde temsili test noktaları.
            // Gerçek durak konumu değildir.
            $latitude = 41.6344 + mt_rand(-350, 350) / 10000;
            $longitude = 32.3375 + mt_rand(-450, 450) / 10000;

            $createdAt = $now->copy()
                ->subDays(mt_rand(0, 179))
                ->setTime(
                    mt_rand(6, 22),
                    mt_rand(0, 59)
                );

            $records[] = [
                'user_id' => null,
                'title' => $title,
                'category' => $category,
                'description' => $description
                    . ' Bu kayıt analiz ve harita testi için üretilmiştir.',
                'line_id' => $line->id,
                'line' => $line->name,
                'stop_id' => null,
                'stop' => null,
                'latitude' => $latitude,
                'longitude' => $longitude,
                'status' => $statuses[$index],
                'is_synthetic' => true,
                'created_at' => $createdAt,
                'updated_at' => $createdAt,
            ];
        }

        DB::table('complaints')->insert($records);

        
$this->command->info(
    "{$eklenecekSayi} yeni sentetik şikayet başarıyla oluşturuldu."
);

    }
}
