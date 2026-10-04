# Not - Mobil (Android)

Tarus ekosistemine özel el yazısı ve çizim notu uygulaması. [saber-notes/saber](https://github.com/saber-notes/saber) temel alınarak özelleştirilmiştir.

## Yapılandırma
- **Uygulama Adı:** Not
- **Sürüm:** `lib/data/version.dart` (tarus şeması, 1.0.0'dan başlar; Saber 1.36.1 temel alındı).
  Artırmak için: `dart run scripts/bump_version.dart --custom X.Y.Z --quiet`; sonra
  `metadata/en-US/changelogs/<buildNumber>.txt` ve `flatpak/…metainfo.xml`'deki
  yer tutucu notu doldurun (`test/version_test.dart` betiğin eşitlediği dosyaları denetler).
- **Paket Kimliği (Application ID):** `tr.tarus.not`
- **Varsayılan Eşitleme Sunucusu:** `https://not.tarus.tr`
- **Protokol:** WebDAV

## Derleme (Build)
Flutter SDK (`submodules/flutter`, 3.47.4) ve Rust (`rustup`; sürüm ve Android
hedefleri `rust-toolchain.toml`'dan) gerekir — `super_native_extensions` yerel
parçası Rust ile derlenir. Windows'ta: `winget install Rustlang.Rustup`.

```bash
flutter build apk --release
```

### İmza anahtarı (ilk yayından önce, bir kez)
Release APK yalnız tarus'a özel anahtarla imzalanır; `android/key.properties`
yoksa derleme durur. Saber'in depodaki yedek anahtarı kaldırıldı (açık anahtarla
imzalanan uygulamaya herkes sahte güncelleme yapabilirdi).

**Anahtar sonradan değiştirilemez:** kaybolursa kurulu uygulamalar güncellenemez,
kullanıcılar kaldırıp yeniden kurmak zorunda kalır. Dosyayı ve parolayı parola
yöneticisine yedekleyin; depoya koymayın (`.gitignore`: `key.properties`, `*.keystore`).

```bash
keytool -genkeypair -v -keystore android/tarus-not.keystore -alias tarus-not \
  -keyalg RSA -keysize 4096 -validity 36500 -dname "CN=tarus Not, O=tarus, C=TR"
```

`android/key.properties`:
```properties
storePassword=<parola>
keyPassword=<parola>
keyAlias=tarus-not
storeFile=../tarus-not.keystore
```

Debug derlemeleri (`flutter run`) Android'in yerel debug anahtarını kullanır.

### tarus için kapatılanlar
- **Güncelleme denetimi** (`UpdateManager.etkin = false`): Saber'in GitHub sürümüne
  bakıyor, Not kullanıcısına Saber'i öneriyordu. Güncellemeler yazilim.tarus.tr'den.
- **Sentry** (`isSentryAvailable` yalnız testte): DSN Saber geliştiricisinin
  projesi; ilk açılışta çökme raporu için onay isteniyordu. Hatalar sistem.tarus.tr'ye.

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

`nc_upload_download_test` ve `nc_deletion_test` Saber'in Nextcloud test sunucusuna
(`nc.saber.adil.hanney.org`, Saber'in test hesapları) karşı çalışır; varsayılan
sunucu not.tarus.tr olduğu için adres testte açıkça verilir.

Golden ekran görüntüleri (`test/goldens/`, `metadata/en-US/images/*Screenshots/`)
arayüz bilerek değişince güncellenir: `flutter test --update-goldens <test dosyası>`
(önce `dart run golden_screenshot:download_apple_fonts`; CI ile aynı sonuç için
Linux'ta, `submodules/flutter` sürümüyle).

## Sürüm notları
- **1.1.1** (2026-10-04): kayıt yokken varsayılan tema Modern, "Sistem" seçeneği
  kaldırıldı; boş yerde basılı tutunca Hata bildir menüsü; CI: golden'lar tarus
  arayüzüne göre güncellendi, Nextcloud testleri Saber test sunucusuna yönlendi.
- **1.1.0** (2026-10-03): tarus 8 tema, Ayarlar → Hata bildir.

## Lisans (GPL-3.0)
tarus Not, [Saber](https://github.com/saber-notes/saber) (© 2022- Adil Hanney ve
katkıda bulunanlar) üzerine geliştirilmiştir ve Saber gibi **GNU GPL-3.0** ile
lisanslıdır (`LICENSE.md`). APK dağıtılırken kaynak kodu da sunulmalıdır (GPL-3.0 §6):

- Uygulamada: Ayarlar → en alttaki sürüm → Hakkında: Saber referansı, lisans notu,
  kaynak kodu ve Saber bağlantıları (`lib/components/settings/app_info.dart`).
- İndirme sayfasında (yazilim.tarus.tr) şu not bulunmalı:

  > tarus Not, açık kaynak Saber (© Adil Hanney ve katkıda bulunanlar) üzerine
  > geliştirilmiştir ve GNU GPL-3.0 ile lisanslıdır. Kaynak kodu:
  > https://github.com/tarusatolye/not-mobil — Saber: https://github.com/saber-notes/saber

- Kaynak bağlantısı APK'yı alan herkesin erişebileceği bir yerde olmalı: depo
  özelse ya açılmalı ya da kaynak arşivi indirme sayfasına konmalı.

## Tema
Ayarlar → Tema: tarus 8 kanonik tema (`lib/data/tarus_tema.dart`). Kimlik, ad ve
sıra `ozluk/tarus-kabuk/components/TemaSecici.tsx`, renkler `tarus-kabuk/css/tarus.css`
ile birebir; değişiklik önce kabukta yapılır, sonra buraya taşınır
(`test/tarus_tema_test.dart` ozluk yanındaysa sırayı karşılaştırır). Kayıt
yokken (ya da kimlik bilinmiyorsa) **Modern** (kullanıcı kararı 2026-10-04; web
ve `tarus-kabuk/mobil` `VARSAYILAN_TEMA` ile aynı); web'de olmadığı için "Sistem"
seçeneği yok (1.1.1'de kaldırıldı). Saber'in tema modu, vurgu rengi
ve Yaru teması kullanılmaz. Tema yalnız uygulama kabuğunu boyar; not sayfası
Saber'in karanlık mod kuralıyla çizilir.

## Hata bildir
Ayarlar → Hata bildir ya da ekranın boş bir yerinde ~0,7 sn basılı tutunca açılan
menü (pusula-mobil / posta-mobil `BaglamMenusu` ile aynı davranış;
`lib/components/baglam_menusu.dart`): Son notlar, Gözat, Ayarlar, Giriş ve
Kayıtlar ekranlarında. Kendi basılı tutma işlevi olan öğe (not kartı seçimi,
ayarı sıfırlama, metin seçimi) önce kazanır; yazı alanı odaktayken açılmaz.
Düzenleyici ve beyaz tahta çizim yüzeyi olduğu için sarılmaz (kalemi kıpırdatmadan
tutmak orada çizimdir). Bildirim ekranı: başlık, açıklama, isteğe bağlı ekran görüntüsü (en çok 2 MB).
Mobilde Pusula oturumu yoktur; kayıt eşitleme belirteciyle Not sunucusuna
(`POST /mobil/hata-bildir`) gider, Not sunucusu Pusula'ya (`/not/hata-bildir/`)
iletir, kayıt sistem.tarus.tr Hata Panosu'nda `not.tarus.tr` altında görünür.
Sunucu tarafı: not 2.0.4 ve Pusula 1.8.5.
