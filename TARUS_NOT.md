# Not - Mobil (Android)

Tarus ekosistemine özel el yazısı ve çizim notu uygulaması. [saber-notes/saber](https://github.com/saber-notes/saber) temel alınarak özelleştirilmiştir.

## Yapılandırma
- **Uygulama Adı:** Not
- **Paket Kimliği (Application ID):** `tr.tarus.not`
- **Varsayılan Eşitleme Sunucusu:** `https://not.tarus.tr`
- **Protokol:** WebDAV

## Derleme (Build)
Uygulamayı derlemek için Flutter SDK gereklidir:
```bash
flutter build apk --release
```
Derlenen APK dosyasını doğrudan Android tablet veya telefonunuza kurabilirsiniz.

## Senkronizasyon
Uygulama ilk açıldığında veya Ayarlar > Senkronizasyon bölümünden `https://not.tarus.tr` sunucusuna kullanıcı adı ve şifrenizle bağlandığınızda tüm notlar otomatik olarak senkronize edilir.
