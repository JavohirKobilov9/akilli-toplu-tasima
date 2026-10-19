# Şikayet fotoğraf ve videolarını görüntüleme

Yolcu ve yönetici şikayet detayında eklenen fotoğraf/video gösterilir. Fotoğrafa
dokununca tam ekran görünüm açılır ve yakınlaştırılabilir. Android/iOS'ta videolar
otomatik başlamaz; oynat/duraklat ve zaman çizgisinden ileri/geri sarma bulunur.
Yönetici ayrıca kayıtlı şikayet koordinatını haritada açabilir.

## Erişim

`GET /api/complaints/{complaint}/media` Sanctum oturumu gerektirir. Yalnızca
şikayet sahibi, yardımcı admin ve süperadmin erişebilir. Diğer kullanıcılar 403,
oturum açmayanlar 401, eksik dosyalar 404 alır. Misafir şikayetlerinin eklerini
yalnızca yöneticiler görüntüleyebilir. Topluluk listesi bu yetkiyi genişletmez.

Fotoğraf/video erişimi için public/storage bağlantısı oluşturulmaz. Dosyalar
mevcut `storage/app/public/complaints` konumunda kalır; API kontrollü sunar.
HTTP yanıtı `private, no-store` kullanır. Fotoğraflar her yeni görüntülemede
oturum başlığıyla indirilir; ortak URL tabanlı resim önbelleği kullanılmaz.
Erişim tokenı dosya adresine yazılmaz.

Videolar parça istekleriyle (HTTP Range / 206) sunulur. Dosyanın oynatılabilirliği
cihazın codec desteğine bağlıdır; örneğin bazı HEIC/MOV dosyaları bazı cihazlarda
desteklenmeyebilir. Windows/web için korumalı video oynatımı bu sürümde yoktur.

## Kontrol

1. Yolcu fotoğraf ekleyerek şikayet oluşturur.
2. Şikayetlerim → Detay ekranında fotoğrafı açıp yakınlaştırır.
3. Admin veya süperadmin aynı şikayette eki ve varsa konumunu görüntüler.
4. Video eklenen bir şikayette oynat/duraklat ve ileri sarma denenir.
5. Başka bir yolcu aynı ek dosyaya erişemez; mevcut şikayet ve yorum akışı devam eder.

Yeni video eklentisinin yüklenmesi için uygulama yeniden başlatılmalıdır;
yalnızca hot reload yeterli değildir. Firebase ayarlarını koruyarak çalıştırma:

```powershell
flutter run -d emulator-5554 --dart-define-from-file=firebase-client.json
```

API testleri geçici PostgreSQL şemalarında, dosya testleri sahte depoda yapılır.
Gerçek kullanıcı kayıtları ve yüklenen dosyalar değiştirilmez.
