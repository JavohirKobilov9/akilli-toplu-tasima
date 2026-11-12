# Akıllı Taşıt — Bartın

Next.js App Router, React ve TypeScript ile hazırlanmış duyarlı tanıtım sayfası.

## Çalıştırma

```sh
npm install
npm run dev
```

Tarayıcı: http://localhost:3000

Site tek tasarımdan oluşur ve `/` adresinde açılır. İlk tasarım projeden kaldırıldı.

Harita bölümü yalnızca "yakında" yer tutucusudur. Harita SDK'sı, konum isteği veya canlı durak/güzergâh verisi içermez. Şikayet, öneri ve teşekkür sekmeleri yerel örnekler arasında geçiş yapar. Temsili görseller `public/images/` içinde; Hakkımızda fotoğrafı `src/app/components/local-sections.tsx` içindeki `aboutImage` yolundan değiştirilir.

## Kontrol

```sh
npm run typecheck
npm run build
```

Yalnızca landing page kapsamındadır. Giriş, kayıt ve paylaşım butonları bilerek devre dışıdır. Paylaşımlar, destek sayıları, isimler ve durumlar temsilidir. Kurumsal bağlantı iddiası yoktur.

Renkler: mavi #2465c7, lacivert #142c4d, LED amberi #ffb23f, çay yeşili #2c8a6e, kâğıt #f7f6f1. Tabela yazıları Doto (nokta vuruşlu) fontuyla yazılır. Bunlar tasarıma ait renk tercihleridir; resmî renk kodu iddiası taşımaz. Bartın Belediyesi (https://bartin.bel.tr/) ve Valilik kurumsal kimlik sayfası (https://www.bartin.gov.tr/kurumsal-kimlik) araştırma referanslarıdır. Özgün SVG illüstrasyon kod içinde bulunur. Google Fonts yüklenemediğinde Arial ve sans-serif yedekleri kullanılır.

## Yönetim paneli (`/yonetim`)

Belediye/yönetici paneli Laravel REST API'ye bağlıdır (mobil uygulamayla aynı API).

1. API'yi başlat: `cd ../akilli_toplu_tasima_api && php artisan serve --host=127.0.0.1 --port=8000`
2. `.env.local.example` dosyasını `.env.local` olarak kopyala; gerekirse `NEXT_PUBLIC_API_BASE_URL` değerini değiştir.
3. `npm install` ardından `npm run dev`, sonra http://localhost:3000/yonetim adresini aç.
4. Yalnızca `admin` veya `super_admin` rolündeki hesaplar giriş yapabilir.

Özellikler: giriş, özet kartları, kategori/hat dağılımı, filtre ve arama, şikayet detayı (konum bağlantısı, fotoğraf/video) ve durum güncelleme (Beklemede, İnceleniyor, Çözüldü). Durum değişince şikayet sahibine bildirim gider.
