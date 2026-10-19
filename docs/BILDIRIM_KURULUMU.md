# Şikayet durum bildirimleri

Süperadmin veya yardımcı admin bir şikayetin durumunu değiştirdiğinde kayıtlı
yolcuya özel bildirim oluşur. Aynı durum tekrar kaydedilirse bildirim oluşmaz.
Yolcu ana sayfasındaki zil, okunmamış sayısını gösterir. Bildirimden şikayetin
güncel detayına ulaşılır. Liste 30 kayıtlık sayfalarla yüklenir.

Misafir şikayetleri kullanıcı hesabına bağlı değildir; bu sürüm misafirlere SMS,
e-posta veya push durum bildirimi göndermez.

## Mevcut veritabanına ekleme

API klasöründen yalnızca yeni migration çalıştırılır; mevcut tablolar silinmez:

```powershell
php artisan migrate --path=database/migrations/2026_10_17_120000_create_complaint_notifications.php
```

## Firebase ile Android telefon bildirimini açma

Firebase yapılandırılmadığında uygulama normal açılır ve uygulama içi bildirimler
çalışır. Gerçek telefon bildirimi için aşağıdaki kurulum gereklidir.

1. [Firebase konsolunda](https://console.firebase.google.com/) bir proje oluştur.
2. Projeye Android uygulaması ekle. Mevcut paket adı:
   `com.example.akilli_toplu_tasima`.
3. Proje ayarlarındaki Android uygulamasının `apiKey`, `appId`,
   `messagingSenderId`, `projectId` bilgilerini al. İndirilen
   `google-services.json` içinde karşılıkları sırasıyla `current_key`,
   `mobilesdk_app_id`, `project_number`, `project_id` alanlarıdır.
4. API'nin kullanması için Firebase proje ayarları → Hizmet hesapları bölümünden
   hizmet hesabı JSON anahtarı oluştur. Dosyayı **yalnızca Laravel sunucusunda**
   `storage/app/firebase-service-account.json` olarak sakla. Bu dosya Git dışında
   tutulur; Flutter içine veya sohbet mesajına özel anahtar koyma.
5. Laravel `.env` dosyasına aşağıdaki ayarları ekle; proje kimliğini kendi
   kimliğinle değiştir:

```dotenv
FIREBASE_PROJECT_ID=proje-kimligin
FIREBASE_CREDENTIALS=C:/Projects/akilli-toplu-tasima/akilli_toplu_tasima_api/storage/app/firebase-service-account.json
```

PHP'de `cURL hata kodu: 60` alınırsa güvenilir CA listesi yapılandırılmalıdır.
Bu yerel kurulumda curl.se resmi kaynağından alınan CA listesi için
`FIREBASE_CA_BUNDLE=C:/Projects/akilli-toplu-tasima/akilli_toplu_tasima_api/storage/app/firebase-ca-bundle.pem`
kullanılır. Sertifika doğrulaması açık kalır. Sunucu taşınırken bu yerel dosya
yolu güncellenmeli veya sistemin güncel CA deposu kullanılıyorsa ayar kaldırılmalıdır.

6. Google Cloud tarafında Firebase Cloud Messaging API (HTTP v1) etkin olmalı.
   Hizmet hesabının ilgili projeye bildirim gönderme yetkisi bulunmalı.
7. Laravel yapılandırmasını yenile: `php artisan config:clear`.
   Ardından `php artisan notifications:check-firebase` ile gerçek bildirim
   göndermeden Google kimlik doğrulamasını ve FCM gönderim yetkisini doğrula.
8. Proje kökünde yerel `firebase-client.json` dosyası oluştur:

```json
{
  "FIREBASE_API_KEY": "Android-uygulamasinin-apiKey-degeri",
  "FIREBASE_APP_ID": "Android-uygulamasinin-appId-degeri",
  "FIREBASE_MESSAGING_SENDER_ID": "projenin-project_number-degeri",
  "FIREBASE_PROJECT_ID": "proje-kimligin"
}
```

9. `flutter run --dart-define-from-file=firebase-client.json` ile uygulamayı
   tamamen yeniden başlat. Bu uygulama açık `FirebaseOptions` kullanır;
   Android için ayrıca Google Services Gradle eklentisi gerekmez.
10. Yolcu hesabıyla giriş yap ve bildirim iznine onay ver. Google Play servisli
    bir cihaz/emülatör kullan. Aynı yolcu hesabına başka cihazda yeniden giriş,
    mevcut girişleri kapatır; yönetici ayrı bir hesap kullanmalı.

## iOS ek kurulumu

iOS için ayrı Firebase iOS uygulaması tanımlanmalı ve derlemede o uygulamanın
`FIREBASE_APP_ID`, `FIREBASE_API_KEY` ve `FIREBASE_IOS_BUNDLE_ID` değerleri
kullanılmalı. Xcode'da Push Notifications ve Background Modes / Remote
notifications yetenekleri açılmalı; APNs anahtarı Firebase'e bağlanmalı.
Apple imzalama/APNs ve gerçek iOS cihaz testi bu Windows ortamında doğrulanmadı.

## Beklenen davranış

- Uygulama ön planda: bildirim metni uygulama içinde gösterilir ve sayaç yenilenir.
- Arka planda/normal şekilde kapalı: Firebase bağlıysa işletim sistemi bildirimi
  gösterir; bildirime dokunulduğunda bildirim listesi açılır.
- Bildirim izni reddedilirse uygulama içi liste çalışmaya devam eder.
- Android ayarlarından zorla durdurma sonrasında uygulama yeniden açılmalıdır.
- Çıkış, hesap dondurma, silme veya yeni girişle eski oturum iptal edilince o
  oturuma bağlı cihaz kaydı silinir. Önceden telefona teslim edilmiş bildirimler
  işletim sistemi tarafından korunabilir.
- Push hatası durum güncellemesini veya uygulama içi bildirimi geri almaz.
  Bu sürüm başarısız FCM gönderimleri için otomatik yeniden gönderim kuyruğu içermez.

## Kontrol senaryosu

1. Yolcu bir şikayet oluşturur.
2. Ayrı yönetici hesabı durumu `İnceleniyor` yapar.
3. Yolcu yalnızca kendi bildirimini görür. Dokununca güncel detay açılır.
4. Aynı durum tekrar kaydedilir; ikinci bildirim oluşmaz.
5. Durum `Çözüldü` yapılır; yeni bildirim oluşur.
6. Firebase bağlı cihazda uygulama arka plana alınıp 2–5 tekrar edilir.

API testleri mevcut proje tabloları yerine her test için geçici PostgreSQL
şeması oluşturur ve yalnızca bu şemayı temizler:

```powershell
php artisan test --filter=ComplaintNotificationTest
```

Kaynaklar: [Flutter FCM kurulumu](https://firebase.google.com/docs/cloud-messaging/flutter/get-started),
[mesaj alma](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages),
[HTTP v1 gönderimi](https://firebase.google.com/docs/cloud-messaging/send/v1-api).
