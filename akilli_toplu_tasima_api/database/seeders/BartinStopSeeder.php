<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Line;
use App\Models\Stop;

class BartinStopSeeder extends Seeder
{
    public function run(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Bartın durak / güzergah noktaları
        |--------------------------------------------------------------------------
        |
        | Koordinatlar doğrulanmadığı için null bırakılıyor.
        | Aynı durak farklı hatlarda tekrar oluşturulmaz.
        |
        */

        $stops = [
            // BRT25
            [
                'code' => 'BTN-MERKEZ',
                'name' => 'Merkez Durak',
            ],
            [
                'code' => 'BTN-BARTIN-LISESI',
                'name' => 'Bartın Lisesi',
            ],
            [
                'code' => 'BTN-YALI',
                'name' => 'Yalı Mevkii',
            ],
            [
                'code' => 'BTN-ULUS-DURAGI',
                'name' => 'Ulus Durağı',
            ],
            [
                'code' => 'BTN-DIS-HASTANESI',
                'name' => 'Diş Hastanesi',
            ],

            // BRT24 Ring Servisleri
            [
                'code' => 'BTN-CAYIRLAR',
                'name' => 'Çayırlar Mahallesi',
            ],
            [
                'code' => 'BTN-DEVLET-HAST-KAVSAK',
                'name' => 'Devlet Hastanesi Kavşağı',
            ],
            [
                'code' => 'BTN-EROGLU-KAVSAK',
                'name' => 'Eroğlu Kavşağı',
            ],
            [
                'code' => 'BTN-IMAMHATIP-USTGECIT',
                'name' => 'İmamhatip Üst Geçit Altı',
            ],
            [
                'code' => 'BTN-OZEL-IDARE-KAVSAK',
                'name' => 'Özel İdare Kavşağı',
            ],
            [
                'code' => 'BTN-CATMACA-KAVSAK',
                'name' => 'Çatmaca Kavşağı',
            ],
            [
                'code' => 'BTN-EMNIYET-ALTI',
                'name' => 'Emniyet Müdürlüğü Altı',
            ],
            [
                'code' => 'BTN-YENI-DEVLET-HAST',
                'name' => 'Yeni Devlet Hastanesi',
            ],
            [
                'code' => 'BTN-TOKI',
                'name' => 'TOKİ',
            ],
            [
                'code' => 'BTN-OGRETMENLER-SITESI',
                'name' => 'Öğretmenler Sitesi',
            ],
            [
                'code' => 'BTN-JANDARMA',
                'name' => 'Jandarma Komutanlığı',
            ],
            [
                'code' => 'BTN-KAYNARCA',
                'name' => 'Kaynarca',
            ],
            [
                'code' => 'BTN-ESKI-ITFAIYE',
                'name' => 'Eski İtfaiye Müdürlüğü Önü',
            ],
            [
                'code' => 'BTN-YASAM-MERKEZI',
                'name' => 'Yaşam Merkezi',
            ],
            [
                'code' => 'BTN-ASMA-KOPRU',
                'name' => 'Asma Köprü',
            ],
            [
                'code' => 'BTN-VALI-KONAGI-KAVSAK',
                'name' => 'Vali Konağı Kavşağı',
            ],
            [
                'code' => 'BTN-GOLBUCAGI-KAVSAK',
                'name' => 'Gölbucağı Işıklı Kavşağı',
            ],
            [
                'code' => 'BTN-BORSA-OKULU',
                'name' => 'Borsa Okulu',
            ],
            [
                'code' => 'BTN-ALADAG',
                'name' => 'Aladağ Mahallesi',
            ],
            [
                'code' => 'BTN-DSI',
                'name' => 'DSİ Müdürlüğü',
            ],
            [
                'code' => 'BTN-CATMACA-MIGROS',
                'name' => 'Çatmaca Migros Karşısı',
            ],
        ];

        foreach ($stops as $stopData) {
            Stop::updateOrCreate(
                [
                    'code' => $stopData['code'],
                ],
                [
                    'name' => $stopData['name'],
                    'district' => 'Merkez',
                    'latitude' => null,
                    'longitude' => null,
                    'is_active' => true,
                ]
            );
        }

        /*
        |--------------------------------------------------------------------------
        | BRT25 - Diş Hastanesi
        |--------------------------------------------------------------------------
        */

        $brt25 = Line::where(
            'code',
            'BRT25'
        )->firstOrFail();

        $brt25Codes = [
            'BTN-MERKEZ',
            'BTN-BARTIN-LISESI',
            'BTN-YALI',
            'BTN-ULUS-DURAGI',
            'BTN-DIS-HASTANESI',
        ];

        $brt25Sync = [];

        foreach ($brt25Codes as $index => $code) {
            $stop = Stop::where(
                'code',
                $code
            )->firstOrFail();

            $brt25Sync[$stop->id] = [
                'stop_order' => $index + 1,
            ];
        }

        $brt25->stops()->sync(
            $brt25Sync
        );

        /*
        |--------------------------------------------------------------------------
        | BRT24 - Yeni Devlet Hastanesi Ring Servisleri
        |--------------------------------------------------------------------------
        |
        | Bu hat birden fazla ring güzergahına sahiptir.
        |
        | Aşağıdaki sıralama tek bir otobüs rotasını ifade ETMEZ.
        | Şikayet oluştururken seçilebilecek doğrulanmış güzergah
        | noktalarının düzenli gösterilmesi amacıyla tutulmaktadır.
        |
        */

        $brt24 = Line::where(
            'code',
            'BRT24'
        )->firstOrFail();

        $brt24Codes = [
            // Yenimahalle - Çayırlar güzergahı
            'BTN-CAYIRLAR',
            'BTN-DEVLET-HAST-KAVSAK',
            'BTN-EROGLU-KAVSAK',
            'BTN-IMAMHATIP-USTGECIT',
            'BTN-OZEL-IDARE-KAVSAK',
            'BTN-CATMACA-KAVSAK',
            'BTN-EMNIYET-ALTI',
            'BTN-YENI-DEVLET-HAST',

            // Kaynarca - TOKİ güzergahındaki ek noktalar
            'BTN-TOKI',
            'BTN-OGRETMENLER-SITESI',
            'BTN-JANDARMA',
            'BTN-KAYNARCA',
            'BTN-ESKI-ITFAIYE',
            'BTN-YASAM-MERKEZI',
            'BTN-BARTIN-LISESI',
            'BTN-ASMA-KOPRU',
            'BTN-VALI-KONAGI-KAVSAK',
            'BTN-GOLBUCAGI-KAVSAK',
            'BTN-BORSA-OKULU',
            'BTN-DIS-HASTANESI',

            // Aladağ güzergahındaki ek noktalar
            'BTN-ALADAG',
            'BTN-DSI',
            'BTN-CATMACA-MIGROS',
        ];

        $brt24Sync = [];

        foreach ($brt24Codes as $index => $code) {
            $stop = Stop::where(
                'code',
                $code
            )->firstOrFail();

            $brt24Sync[$stop->id] = [
                'stop_order' => $index + 1,
            ];
        }

        $brt24->stops()->sync(
            $brt24Sync
        );
    }
}