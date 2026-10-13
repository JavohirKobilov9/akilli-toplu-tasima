<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Line;

class BartinLineSeeder extends Seeder
{
    public function run(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Eski test hatlarını pasif yap
        |--------------------------------------------------------------------------
        */

        Line::whereIn('code', [
            '34AS',
            'M5',
            'DT1',
            'DH',
            'KAU',
            'AKK',
            'YDH-R1',
        ])->update([
            'is_active' => false,
        ]);

        /*
        |--------------------------------------------------------------------------
        | Bartın güzergahları
        |--------------------------------------------------------------------------
        |
        | BRT kodları uygulama içi kodlardır.
        | Resmi hat numarası değildir.
        |
        */

        $lines = [
            [
                'code' => 'BRT01',
                'name' => 'Orduyeri - Cezaevi',
            ],
            [
                'code' => 'BRT02',
                'name' => 'Asma Köprü - Aladağ Mahallesi',
            ],
            [
                'code' => 'BRT03',
                'name' => 'Karaköy - Ağdacı Üniversite',
            ],
            [
                'code' => 'BRT04',
                'name' => 'Kaynarca - Jandarma Kom. - TOKİ',
            ],
            [
                'code' => 'BRT05',
                'name' => 'Orduyeri - Erkam Sitesi - Çağlayan',
            ],
            [
                'code' => 'BRT06',
                'name' => 'Hendekyanı - Yeni Mahalle - Çayırlar',
            ],
            [
                'code' => 'BRT07',
                'name' => 'Fuat Sezgin Lisesi',
            ],
            [
                'code' => 'BRT08',
                'name' => 'İnkumu',
            ],
            [
                'code' => 'BRT09',
                'name' => 'Gürgenpınarı',
            ],
            [
                'code' => 'BRT10',
                'name' => 'Karasu Boğaz',
            ],
            [
                'code' => 'BRT11',
                'name' => 'Ağdacı Üniversite - KYK Yurt - Kutlubey Yazıcılar Kampüs',
            ],
            [
                'code' => 'BRT12',
                'name' => 'Mehmet Rıfat Efendi Erkek Öğrenci Yurdu - Ağdacı Kampüs',
            ],
            [
                'code' => 'BRT13',
                'name' => 'Şiremir Çavuş - İğciler Mahallesi - Fen Lisesi',
            ],
            [
                'code' => 'BRT14',
                'name' => 'Çatmaca - Kavallar',
            ],
            [
                'code' => 'BRT15',
                'name' => 'Gülkent - Karaçay',
            ],
            [
                'code' => 'BRT16',
                'name' => 'Tabaklar Köyü',
            ],
            [
                'code' => 'BRT17',
                'name' => 'Kasapoğlu Mahallesi',
            ],
            [
                'code' => 'BRT18',
                'name' => 'Esenyurt',
            ],
            [
                'code' => 'BRT19',
                'name' => 'Saraylı Köyü',
            ],
            [
                'code' => 'BRT20',
                'name' => 'AKTIP - İmamhatip - Ağdacı Üniversite',
            ],

            // Kalan 6 güzergah
            [
                'code' => 'BRT21',
                'name' => 'Dallıca - TOKİ Hattı',
            ],
            [
                'code' => 'BRT22',
                'name' => 'Çatmaca - Yıldız Kent',
            ],
            [
                'code' => 'BRT23',
                'name' => 'Yeni Devlet Hastanesi',
            ],
            [
                'code' => 'BRT24',
                'name' => 'Yeni Devlet Hastanesi Ring Servisleri',
            ],
            [
                'code' => 'BRT25',
                'name' => 'Diş Hastanesi',
            ],
            [
                'code' => 'BRT26',
                'name' => 'Çatmaca - Yeni Terminal - Kutlubey Yazıcılar Kampüs',
            ],
        ];

        foreach ($lines as $lineData) {
            Line::updateOrCreate(
                [
                    'code' => $lineData['code'],
                ],
                [
                    'name' => $lineData['name'],
                    'transport_type' => 'Özel Halk Otobüsü',
                    'start_point' => null,
                    'end_point' => null,
                    'is_active' => true,
                ]
            );
        }
    }
}