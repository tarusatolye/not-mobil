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

## Senkronizasyon (Pusula eşitleme belirteci)
Not'un ayrı kullanıcı hesabı yoktur; kimlik Pusula'dır.

1. Pusula → Ayarlar → **Not eşitleme** → "Yeni belirteç" (ör. "Tablet"). Belirteç (`nes_…`) yalnız bir kez gösterilir.
2. Uygulamada giriş ekranında **tarus Not** bölümüne belirteci yapıştırıp "Pusula ile bağlan".
3. Cihaz kaybolursa belirteci Pusula'dan iptal edin; cihaz en geç 30 sn içinde eşitleyemez.

Belirteç Nextcloud istemcisinin uygulama parolası olarak (`Authorization: Bearer`)
gider; Not sunucusu (`tarusatolye/not`) onu Pusula'ya doğrulatır. Notlar sunucuda
`.sbn2` (Saber BSON) olarak durur; aynı not iki yerde birbirinden habersiz
değişirse sunucu eski sürümü "(çakışma - cihaz - tarih)" adıyla saklar.

## Testler
```bash
flutter test test/pusula_belirteci_test.dart
# Gerçek Not sunucusuna karşı uçtan uca (not deposunda: NOT_YEREL_GELISTIRME=1 PORT=3999 node server/server.js)
NOT_SUNUCU_URL=http://127.0.0.1:3999 flutter test test/not_sunucu_esitleme_test.dart
```
Linux'ta testler için `libgtk-3-dev` gerekir (super_native_extensions).
