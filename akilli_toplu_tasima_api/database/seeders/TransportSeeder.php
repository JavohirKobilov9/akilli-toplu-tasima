<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Line;
use App\Models\Stop;

class TransportSeeder extends Seeder
{
    public function run(): void
    {
     
        // -------------------------
        // DURAKLAR
        // -------------------------
 

        $kadikoy = Stop::updateOrCreate(
            ['code' => 'STP001'],
            [
                'name' => 'Kadıköy',
                'district' => 'Kadıköy',
                'latitude' => 40.9909,
                'longitude' => 29.0233,
                'is_active' => true,
            ]
        );

        $uskudar = Stop::updateOrCreate(
            ['code' => 'STP002'],
            [
                'name' => 'Üsküdar',
                'district' => 'Üsküdar',
                'latitude' => 41.0267,
                'longitude' => 29.0150,
                'is_active' => true,
            ]
        );

        $altunizade = Stop::updateOrCreate(
            ['code' => 'STP003'],
            [
                'name' => 'Altunizade',
                'district' => 'Üsküdar',
                'latitude' => 41.0217,
                'longitude' => 29.0431,
                'is_active' => true,
            ]
        );

        $zincirlikuyu = Stop::updateOrCreate(
            ['code' => 'STP004'],
            [
                'name' => 'Zincirlikuyu',
                'district' => 'Şişli',
                'latitude' => 41.0664,
                'longitude' => 29.0187,
                'is_active' => true,
            ]
        );

        $mecidiyekoy = Stop::updateOrCreate(
            ['code' => 'STP005'],
            [
                'name' => 'Mecidiyeköy',
                'district' => 'Şişli',
                'latitude' => 41.0670,
                'longitude' => 28.9920,
                'is_active' => true,
            ]
        );

        $taksim = Stop::updateOrCreate(
            ['code' => 'STP006'],
            [
                'name' => 'Taksim',
                'district' => 'Beyoğlu',
                'latitude' => 41.0369,
                'longitude' => 28.9850,
                'is_active' => true,
            ]
        );

        // -------------------------
        // HATLAR
        // -------------------------

        $line1 = Line::updateOrCreate(
            ['code' => '34AS'],
            [
                'name' => 'Kadıköy - Zincirlikuyu',
                'transport_type' => 'Otobüs',
                'start_point' => 'Kadıköy',
                'end_point' => 'Zincirlikuyu',
                'is_active' => true,
            ]
        );

        $line2 = Line::updateOrCreate(
            ['code' => 'M5'],
            [
                'name' => 'Üsküdar - Çekmeköy',
                'transport_type' => 'Metro',
                'start_point' => 'Üsküdar',
                'end_point' => 'Çekmeköy',
                'is_active' => true,
            ]
        );

        $line3 = Line::updateOrCreate(
            ['code' => 'DT1'],
            [
                'name' => 'Taksim - Kadıköy',
                'transport_type' => 'Otobüs',
                'start_point' => 'Taksim',
                'end_point' => 'Kadıköy',
                'is_active' => true,
            ]
        );

        // -------------------------
        // HAT - DURAK BAĞLANTILARI
        // -------------------------

        $line1->stops()->sync([
            $kadikoy->id => ['stop_order' => 1],
            $uskudar->id => ['stop_order' => 2],
            $altunizade->id => ['stop_order' => 3],
            $zincirlikuyu->id => ['stop_order' => 4],
        ]);

        $line2->stops()->sync([
            $uskudar->id => ['stop_order' => 1],
            $altunizade->id => ['stop_order' => 2],
        ]);

        $line3->stops()->sync([
            $taksim->id => ['stop_order' => 1],
            $mecidiyekoy->id => ['stop_order' => 2],
            $zincirlikuyu->id => ['stop_order' => 3],
            $kadikoy->id => ['stop_order' => 4],
        ]);
    }
}