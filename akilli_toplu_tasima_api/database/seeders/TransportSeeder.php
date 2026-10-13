<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Line;
use App\Models\Stop;

class TransportSeeder extends Seeder
{
    public function run(): void
    {
        /*
        |--------------------------------------------------------------------------
        | BARTIN DURAKLARI
        |--------------------------------------------------------------------------
        */

        $merkezDurak = Stop::updateOrCreate(
            ['code' => 'BAR001'],
            [
                'name' => 'Merkez Durak',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $bartinLisesi = Stop::updateOrCreate(
            ['code' => 'BAR002'],
            [
                'name' => 'Bartın Lisesi',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $yaliMevkii = Stop::updateOrCreate(
            ['code' => 'BAR003'],
            [
                'name' => 'Yalı Mevkii',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $ulusDuragi = Stop::updateOrCreate(
            ['code' => 'BAR004'],
            [
                'name' => 'Ulus Durağı',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $disHastanesi = Stop::updateOrCreate(
            ['code' => 'BAR005'],
            [
                'name' => 'Diş Hastanesi',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $karakoy = Stop::updateOrCreate(
            ['code' => 'BAR006'],
            [
                'name' => 'Karaköy',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $agdaci = Stop::updateOrCreate(
            ['code' => 'BAR007'],
            [
                'name' => 'Ağdacı',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $agdaciKampus = Stop::updateOrCreate(
            ['code' => 'BAR008'],
            [
                'name' => 'Ağdacı Kampüsü',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $kykYurt = Stop::updateOrCreate(
            ['code' => 'BAR009'],
            [
                'name' => 'KYK Yurt',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $kutlubeyKampus = Stop::updateOrCreate(
            ['code' => 'BAR010'],
            [
                'name' => 'Kutlubey Yazıcılar Kampüsü',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $toki = Stop::updateOrCreate(
            ['code' => 'BAR011'],
            [
                'name' => 'TOKİ - Öğretmenler Sitesi',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $jandarma = Stop::updateOrCreate(
            ['code' => 'BAR012'],
            [
                'name' => 'Jandarma Komutanlığı',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $kaynarca = Stop::updateOrCreate(
            ['code' => 'BAR013'],
            [
                'name' => 'Kaynarca',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $asmaKopru = Stop::updateOrCreate(
            ['code' => 'BAR014'],
            [
                'name' => 'Asma Köprü',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $golbucagi = Stop::updateOrCreate(
            ['code' => 'BAR015'],
            [
                'name' => 'Gölbucağı Işıklı Kavşağı',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $catmaca = Stop::updateOrCreate(
            ['code' => 'BAR016'],
            [
                'name' => 'Çatmaca Kavşağı',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        $yeniDevletHastanesi = Stop::updateOrCreate(
            ['code' => 'BAR017'],
            [
                'name' => 'Yeni Devlet Hastanesi',
                'district' => 'Merkez',
                'latitude' => null,
                'longitude' => null,
                'is_active' => true,
            ]
        );

        /*
        |--------------------------------------------------------------------------
        | BARTIN HATLARI
        |--------------------------------------------------------------------------
        */

        $disHastanesiHatti = Line::updateOrCreate(
            ['code' => 'DH'],
            [
                'name' => 'Diş Hastanesi',
                'transport_type' => 'Özel Halk Otobüsü',
                'start_point' => 'Merkez Durak',
                'end_point' => 'Diş Hastanesi',
                'is_active' => true,
            ]
        );

        $karakoyAgdaci = Line::updateOrCreate(
            ['code' => 'KAU'],
            [
                'name' => 'Karaköy - Ağdacı Üniversite',
                'transport_type' => 'Özel Halk Otobüsü',
                'start_point' => 'Karaköy',
                'end_point' => 'Ağdacı Kampüsü',
                'is_active' => true,
            ]
        );

        $kampusHatti = Line::updateOrCreate(
            ['code' => 'AKK'],
            [
                'name' => 'Ağdacı Üniversite - KYK Yurt - Kutlubey Yazıcılar Kampüs',
                'transport_type' => 'Özel Halk Otobüsü',
                'start_point' => 'Ağdacı Kampüsü',
                'end_point' => 'Kutlubey Yazıcılar Kampüsü',
                'is_active' => true,
            ]
        );

        $hastaneRing = Line::updateOrCreate(
            ['code' => 'YDH-R1'],
            [
                'name' => 'Kaynarca - TOKİ - Yeni Devlet Hastanesi Ring',
                'transport_type' => 'Özel Halk Otobüsü',
                'start_point' => 'TOKİ - Öğretmenler Sitesi',
                'end_point' => 'Yeni Devlet Hastanesi',
                'is_active' => true,
            ]
        );

        /*
        |--------------------------------------------------------------------------
        | HAT - DURAK İLİŞKİLERİ
        |--------------------------------------------------------------------------
        */

        $disHastanesiHatti->stops()->sync([
            $merkezDurak->id => ['stop_order' => 1],
            $bartinLisesi->id => ['stop_order' => 2],
            $yaliMevkii->id => ['stop_order' => 3],
            $ulusDuragi->id => ['stop_order' => 4],
            $disHastanesi->id => ['stop_order' => 5],
        ]);

        $karakoyAgdaci->stops()->sync([
            $karakoy->id => ['stop_order' => 1],
            $agdaci->id => ['stop_order' => 2],
            $agdaciKampus->id => ['stop_order' => 3],
        ]);

        $kampusHatti->stops()->sync([
            $agdaciKampus->id => ['stop_order' => 1],
            $kykYurt->id => ['stop_order' => 2],
            $kutlubeyKampus->id => ['stop_order' => 3],
        ]);

        $hastaneRing->stops()->sync([
            $toki->id => ['stop_order' => 1],
            $jandarma->id => ['stop_order' => 2],
            $kaynarca->id => ['stop_order' => 3],
            $bartinLisesi->id => ['stop_order' => 4],
            $asmaKopru->id => ['stop_order' => 5],
            $golbucagi->id => ['stop_order' => 6],
            $catmaca->id => ['stop_order' => 7],
            $yeniDevletHastanesi->id => ['stop_order' => 8],
        ]);
    }
}