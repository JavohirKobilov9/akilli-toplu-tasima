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
