# Not - Mobil (Android)

Tarus ekosistemine özel el yazısı ve çizim notu uygulaması. [saber-notes/saber](https://github.com/saber-notes/saber) temel alınarak özelleştirilmiştir.

## Yapılandırma
- **Uygulama Adı:** Not
- **Sürüm:** `lib/data/version.dart` (tarus şeması, 1.0.0'dan başlar; Saber 1.36.1 temel alındı).
  Artırmak için: `dart run scripts/bump_version.dart --custom X.Y.Z --quiet`; sonra
  `metadata/en-US/changelogs/<buildNumber>.txt` ve `flatpak/…metainfo.xml`'deki
  yer tutucu notu doldurun (`test/version_test.dart` betiğin eşitlediği dosyaları denetler).
  Betik `dart run` ile değil `dart scripts/bump_version.dart …` ile çalıştırılır
  (`dart run` yerel derleme kancalarını, dolayısıyla Rust'ı çalıştırır).
- **Play versionCode:** `buildNumber + 2_000_000` (`android/app/build.gradle.kts`,
  `playSurumKaydirma`). Paket `tr.tarus.not` Saber şemasıyla 1.36.1'e (136010; bölünmüş
  APK'da 1360103) kadar kod taşıdı, tarus şeması 1.0.0'da 100000'e indi; kaydırma Play'e
  giden her kodu eskilerin hepsinden büyük ve monoton tutar (1.1.3 → AAB 2101030).
  Uygulama içi sürüm (Hakkında) `buildNumber`'ı gösterir. Kaydırma bir daha küçültülmez.
- **Paket Kimliği (Application ID):** `tr.tarus.not`
- **Varsayılan Eşitleme Sunucusu:** `https://not.tarus.tr`
- **Protokol:** WebDAV

## Derleme (Build)
Flutter SDK (`submodules/flutter`, 3.47.4) ve Rust (`rustup`; sürüm ve Android
hedefleri `rust-toolchain.toml`'dan) gerekir — `super_native_extensions` yerel
parçası Rust ile derlenir. Windows'ta: `winget install Rustlang.Rustup`.

```bash
flutter build apk --release          # yerel deneme
./scripts/build_appbundle.sh         # Google Play (aşağıda)
```

### Google Play
- `scripts/build_appbundle.sh`: temiz ağaçta FOSS yaması (Onyx SDK, boox HTTP deposu ve
  Sentry çıkar; bitince ağaç HEAD'e döner), `flutter build appbundle --release`, çıktı
  `output/tarus-not-<sürüm>.aab` + GPL kaynak arşivi `output/not-mobil-<sürüm>-kaynak.tar.gz`.
- **Hedef API:** Play, 31 Ağustos 2026'dan beri yeni uygulama ve güncellemelerde API 36
  (Android 16) istiyor; `targetSdk = maxOf(36, flutter.targetSdkVersion)`.
- **İmza:** Play App Signing açılır; `android/key.properties`'teki anahtar **yükleme
  anahtarı** olur (uygulama imza anahtarını Google tutar; yükleme anahtarı kaybolursa
  Play Console'dan sıfırlanır).
- Mağaza metinleri `store/play/tr-TR/` (başlık ≤30, kısa ≤80, uzun ≤4000, yenilikler ≤500
  karakter), İngilizce `metadata/en-US/`. Veri güvenliği formu: `store/play/veri-guvenligi.md`.
- Gizlilik, hesap silme, kaynak kodu ve Pusula adresleri `lib/data/tarus_baglantilar.dart`
  (`--dart-define=TARUS_GIZLILIK_URL=…` ile derlemede değişir). Varsayılan gizlilik ve
  silme sayfası `https://tarus.tr/gizlilik` ve `https://tarus.tr/hesap-silme` (2026-10-06; yazilim.tarus.tr kapatılıyor).
- CI (`android.yml`) yüklemesi `tr.tarus.not` dahili teste taslak; yalnız depo değişkeni
  `PLAY_YUKLEME=true` ve `PLAY_STORE_JSON` gizi varken çalışır.

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

### Düz eşitleme (1.1.6'dan beri; kullanıcı kararı 2026-10-08)
Uçtan uca şifreleme kalktı: notlar telefonla web aynı listeyi görsün diye **düz** eşitlenir,
Not sunucusu (0.2.19+) diskte ve yedekte şifreli saklar (saklama şifrelemesi, `TNOTENC1`,
not deposu README «Saklama şifrelemesi»). Şifreleme parolası adımı yok; oturum = belirteç.
- Yol: yerel `/<klasör>/<ad>.sbn2` ↔ sunucu `Saber/<klasör>/<ad>.sbn2` (`SaberSyncInterface.uzakYol`
  / `yerelGoreliYol`); görseller `<ad>.sbn2.<n>`, önizleme `<ad>.sbn2.p`. Baytlar olduğu gibi gider.
- Liste: tek `PROPFIND Depth: infinity` (`Saber/`); sunucu sınırı 64 düzey, 20 000 kayıt.
  Klasörler ve `yoksayilirMi` dosyaları (`.sbe`, `.sbe.cakisma`, `config.sbc`, noktalı ad, Readme)
  eşitlenmez. Silme = 0 baytlık PUT; `X-OC-Mtime` korunur.
- Sunucu `X-Not-Cakisma` döndürürse liste yenilenir, çakışma kopyası telefona da iner.
- **403** (eski şifreli dosya; gövde «… tarus Not'u güncelleyin.») ve **503** (anahtar servisi geçici
  yok) Ayarlar › Eşitleme kartında gösterilir (`EsitlemeUyarisi`); 503'te liste boş döner, yerel
  notlar silinmez, abstract_sync artan aralıkla yeniden dener.
- Güncellemeden sonraki ilk açılışta eski `encPassword`/`key`/`iv` bir kez silinir
  (`stows.eskiSifrelemeKayitlariniSil`, `main.dart`). Cihazdaki notlar zaten düzdü; sunucuda düz
  kopyaları olmadığından ilk eşitleme hepsini yükler. Sunucudaki eski `.sbe` dosyalarına dokunulmaz.

## Testler
```bash
flutter test test/pusula_belirteci_test.dart
# Gerçek Not sunucusuna karşı uçtan uca (not deposunda: NOT_YEREL_GELISTIRME=1 PORT=3999 node server/server.js)
NOT_SUNUCU_URL=http://127.0.0.1:3999 flutter test test/not_sunucu_esitleme_test.dart
```
Linux'ta testler için `libgtk-3-dev` gerekir (super_native_extensions).

`test/esitleme_duz_test.dart` yol eşlemesini, yok sayılan dosyaları, 403/503 davranışını (taklit
sunucu) ve eski şifreleme kayıtlarının silinmesini sınar. `not_sunucu_esitleme_test` gerçek Not
sunucusuna karşı çalışır (yerelde: not deposunda `NOT_YEREL_GELISTIRME=1 KMS_SAGLAYICI=yerel
KMS_YEREL_ANAHTAR=<32 baytın base64'ü> NOT_VERI_DIZINI=<geçici klasör> PORT=3999 node server/server.js`).
Saber'in şifreli Nextcloud testleri (`nc_upload_download_test`, `nc_deletion_test`) 1.1.6'da kalktı.

Emülatörde yerel Not sunucusuyla deneme: `flutter build apk --debug --target-platform android-x64
--dart-define=TARUS_NOT_SUNUCU=http://10.0.2.2:<port>` (varsayılan sunucu adresi; «Pusula ile bağlan»
bu adrese gider). Belirteç alanı `nes_…` biçimi ister, yerel sunucu ise yalnız `yerel-esitleme`'yi
tanır: araya `Authorization` başlığını `yerel-esitleme`'ye çeviren küçük bir vekil konur (2026-10-08
turunda böyle denendi; telefon→web ve web→telefon, 403/503 uyarıları).

Golden ekran görüntüleri (`test/goldens/`, `metadata/en-US/images/*Screenshots/`) Linux'ta
(CI ile aynı yazı tipleri) üretilir; Windows'ta üretilenler tutmaz. **GitHub Actions bu ekosistemde
kapalı**, `golden-guncelle.yml` çalışmaz. Linux (WSL Ubuntu ya da `ubuntu` Docker) makinede:
```bash
sudo apt-get install -y libgtk-3-dev libx11-dev pkg-config cmake ninja-build curl \
  libcurl4-openssl-dev libblkid-dev libsecret-1-dev libjsoncpp-dev ghostscript libunwind-dev
git submodule update --init submodules/flutter && export PATH="$PWD/submodules/flutter/bin:$PATH"
flutter pub get && dart run golden_screenshot:download_apple_fonts
flutter test --update-goldens   # sonra yalnız *.png değişikliklerini commit edin
```
Rust (`rustup`) da gerekir (super_native_extensions).

Windows'ta `flutter test`: `super_native_extensions` yerel parçası Windows'ta MSVC hedefiyle
derlenir (Visual Studio Build Tools gerekir). Build Tools yoksa yerel deneme için git dışı
`pubspec_overrides.yaml` ile `native_toolchain_rust`'ın Windows hedefini `x86_64-pc-windows-gnu`'ya
çeviren yerel bir kopya kullanılabilir (2026-10-07 turunda böyle çalıştırıldı; commit edilmez).

## Sürüm notları
- **1.1.7** (2026-10-08): arayüzün 3. aşaması. Düzenleyici alt sayfası (kağıt deseni önizlemeleri
  seçili = vurgu kenarlığı, satır aralığı/çizgi kalınlığı kaydırıcı kartları, «Tüm sayfaları
  temizle» tehlike renginde), sayfa yöneticisi (sayfa başına `TarusKart`, geçerli sayfa seçili,
  `TarusIkonDugmesi`), renk seçici (İptal + Kaydet, onaltılı kod alanı), seçim çubuğu (araç
  çubuğuna dik, sil tehlike renginde), tuval HUD'u (`tarusHudZemini`: yüzen çubuk zemini, kilitliyken
  `selectionStyle`), kaydet göstergesi (bekleyen kayıt vurgu renginde), salt okunur şeridi (uyarı
  rengi), «daha yeni sürüm» penceresi (izin düğmesi tehlike renginde), Hata bildir sayfası, güncelleme
  ve Sentry onay pencereleri (`TarusDialog`), hesap silme penceresi. Kayıtlar sayfasında sabit
  siyah/beyaz yerine token'lar. Ayarlar › Düzen boyutu: telefon `panelBottom`, tablet `panelLeft`
  (Lucide `smartphone`/`tablet` küçükte ayırt edilmiyordu). Mürekkep ve not içeriği renkleri değişmedi.
  Arayüz metinlerinde Saber/Nextcloud yalnız GPL telif satırında ve Hakkında'daki kaynak notunda kalır.
- **1.1.6** (2026-10-08): düz eşitleme (yukarıda). Şifreleme parolası adımı (`enc_login_step`),
  `config.sbc`/anahtar üretimi ve yol şifrelemesi kalktı; liste tek `Depth: infinity` PROPFIND;
  403/503 Ayarlar › Eşitleme'de; eski şifreleme kayıtları ilk açılışta silinir. Mağaza metinleri ve
  veri güvenliği formu «uçtan uca» yerine saklama şifrelemesini anlatıyor (gizlilik politikası §10
  da güncellenmeli). Golden'lar (giriş/Ayarlar) Linux'ta yeniden üretilmeli.
- **1.1.5** (2026-10-07): arayüz tarus tasarım diline geçti (1–2. aşama). `lib/tarus/` tema katmanı
  (`TarusRenkler` kabuk token'ları `tarus.css`'ten üretilir, `TarusOlcu` Pusula Mobil `ui.ts`
  ölçüleri, `TarusTemaKur` tek ThemeData; Saber'in `SaberTheme`, platform seçici, Cupertino/Yaru
  dalları ve ölü `settings_color`/`yaru_builder` kalktı), Inter yazı tipi, tek ikon ailesi Lucide
  (`TarusIkon`), Pusula Mobil gibi yüzen alt çubuk + ortada «+» (tablette kenar rayı), sekmeler
  Hızlı Bakış / Notlar / Beyaz tahta / Ayarlar, yeni kartlar (Karanlık temada not adı okunmuyordu),
  klasör kartları, konum çubuğu, boş durumlar, tarus pencereleri, editör araç çubuğu (40 px,
  seçili = vurgu %14 zemin + %45 kenarlık), Ayarlar baştan (gruplu satırlar, 3 sütun tema ızgarası),
  uygulama içi Hakkında + sürüm notları, giriş ekranı görünümü (Nextcloud markası kalktı, eşitleme
  ve şifreleme mantığı değişmedi). Kağıt çizgileri ve Quill başlık rengi temadan ayrıldı, dışa
  aktarmayla aynı (`TarusKagit`). Diller yalnız Türkçe ve İngilizce.
- **1.1.4** (2026-10-06): başlatıcı ikonu tarus Not işareti (`#AC865A` zeminde beyaz
  defter sayfası, monochrome katmanlı); Saber'in sarı «S» ikonu ve indigo `icon.svg` kalktı.
  İkonlar `ozluk/tarus-kabuk/marka/uret.mjs` ile üretilir (`--hedef flutter` + `--hedef android`).
- **1.1.3** (2026-10-06): gizlilik ve hesap silme tarus'a (silme penceresi), User-Agent
  `tarusNot/`, mağaza metinleri, çeviri düzeltmeleri (10 dilde Saber telif satırı geri),
  Play hazırlığı (API 36, versionCode kaydırma, AAB betiği).
- **1.1.1** (2026-10-04): kayıt yokken varsayılan tema Modern, "Sistem" seçeneği
  kaldırıldı; boş yerde basılı tutunca Hata bildir menüsü; CI: golden'lar tarus
  arayüzüne göre güncellendi, Nextcloud testleri Saber test sunucusuna yönlendi.
- **1.1.0** (2026-10-03): tarus 8 tema, Ayarlar → Hata bildir.

## Lisans (GPL-3.0)
tarus Not, [Saber](https://github.com/saber-notes/saber) (© 2022- Adil Hanney ve
katkıda bulunanlar) üzerine geliştirilmiştir ve Saber gibi **GNU GPL-3.0** ile
lisanslıdır (`LICENSE.md`). APK dağıtılırken kaynak kodu da sunulmalıdır (GPL-3.0 §6):

- Uygulamada: Ayarlar → Destek → Hakkında (ya da en alttaki sürüm): Saber referansı, lisans notu,
  kaynak kodu ve Saber bağlantıları (`lib/pages/user/hakkinda_sayfasi.dart`, metinler
  `lib/components/settings/app_info.dart`).
- Play mağaza açıklamasının sonunda aynı not var (`store/play/tr-TR/uzun-aciklama.txt`).
- **Telif satırı:** `appInfo.licenseNotice` her dilde «Saber … Adil Hanney» kalır (ürün
  adı değil telif sahibi); `test/tarus_yayin_test.dart` denetler.
- İndirme sayfasında (yazilim.tarus.tr) şu not bulunmalı:

  > tarus Not, açık kaynak Saber (© Adil Hanney ve katkıda bulunanlar) üzerine
  > geliştirilmiştir ve GNU GPL-3.0 ile lisanslıdır. Kaynak kodu:
  > https://github.com/tarusatolye/not-mobil — Saber: https://github.com/saber-notes/saber

- Kaynak bağlantısı APK'yı alan herkesin erişebileceği bir yerde olmalı: depo
  özelse ya açılmalı ya da kaynak arşivi indirme sayfasına konmalı.

## Arayüz katmanı (`lib/tarus/`, 1.1.5)
- `tarus_renkler.dart` + `tarus_renkler_veri.dart`: kabuk token'ları (`--card-2` → `card2`,
  `--ovl-3` → `ovl3`, `--elev-1` → `elev1` …) `ThemeExtension` olarak; veri dosyası
  `python scripts/tarus_renkler_uret.py ../ozluk/tarus-kabuk/css/tarus.css lib/tarus/tarus_renkler_veri.dart`
  ile üretilir (ardından `dart format`), elle düzenlenmez. Widget'lar renkleri
  `TarusRenkler.of(context)` ile okur.
- `tarus_olcu.dart`: Pusula Mobil `app/theme/ui.ts` ölçüleri (kart 14, pencere 22, alan 8,
  ikon düğmesi 40, yazı ölçeği) ve `TarusSecim` (seçili = vurgu `#..14` zemin, `#..45` kenarlık).
- `tarus_tema_kur.dart`: tek `ThemeData` (Inter; okunaklı yazı tipi seçiliyse Atkinson Hyperlegible
  Next). Bütün platformlarda aynı Material/tarus görünümü; Cupertino/Yaru yok.
- `tarus_ikon.dart`: tek ikon ailesi Lucide (`lucide_icons_flutter`, MIT; ikonlar ISC). Başka ikon
  paketi kullanılmaz (Font Awesome, Material Symbols, Cupertino ikonları kaldırıldı).
- `tarus_bilesenler.dart`: `TarusKart`, `TarusDialog`, `TarusIkonDugmesi`, `TarusBosDurum`,
  `TarusSayfaUstu`, `TarusMetinAlani`, `TarusSecmeli`, Not ve tarus işaretleri.
- `surum_notlari.dart`: Hakkında → Sürüm notları (kullanıcı dili, en çok üç cümle; STANDARTLAR §19).
  Her sürümde buraya bir kayıt eklenir.
- Kağıt (`TarusKagit`): satır/ızgara çizgisi ve Quill başlık rengi temadan bağımsız, dışa aktarmayla
  aynı mavi/kırmızı; not dosyası değişmez.
- Saber'den güncelleme alınmaz (karar 2026-10-07); Saber dosyaları doğrudan düzenlenir.

## Tema
Ayarlar → Tema: tarus 8 kanonik tema (`lib/data/tarus_tema.dart`). Kimlik, ad ve
sıra `ozluk/tarus-kabuk/components/TemaSecici.tsx`, renkler `tarus-kabuk/css/tarus.css`
ile birebir; değişiklik önce kabukta yapılır, sonra buraya taşınır
(`test/tarus_tema_test.dart` ozluk yanındaysa sırayı karşılaştırır). Kayıt
yokken (ya da kimlik bilinmiyorsa) **Modern** (kullanıcı kararı 2026-10-04; web
ve `tarus-kabuk/mobil` `VARSAYILAN_TEMA` ile aynı); web'de olmadığı için "Sistem"
seçeneği yok (1.1.1'de kaldırıldı). Saber'in tema modu, vurgu rengi
ve Yaru teması kullanılmaz; vurgu temanın kendi `--accent`'i. Tema yalnız uygulama kabuğunu
boyar; not sayfası Saber'in karanlık mod kuralıyla çizilir.

## Hata bildir
Ayarlar → Hata bildir ya da ekranın boş bir yerinde ~0,7 sn basılı tutunca açılan
menü (pusula-mobil / posta-mobil `BaglamMenusu` ile aynı davranış;
`lib/components/baglam_menusu.dart`): Hızlı Bakış, Notlar, Ayarlar, Giriş ve
Kayıtlar ekranlarında. Kendi basılı tutma işlevi olan öğe (not kartı seçimi,
ayarı sıfırlama, metin seçimi) önce kazanır; yazı alanı odaktayken açılmaz.
Düzenleyici ve beyaz tahta çizim yüzeyi olduğu için sarılmaz (kalemi kıpırdatmadan
tutmak orada çizimdir). Bildirim ekranı: başlık, açıklama, isteğe bağlı ekran görüntüsü (en çok 2 MB).
Mobilde Pusula oturumu yoktur; kayıt eşitleme belirteciyle Not sunucusuna
(`POST /mobil/hata-bildir`) gider, Not sunucusu Pusula'ya (`/not/hata-bildir/`)
iletir, kayıt sistem.tarus.tr Hata Panosu'nda `not.tarus.tr` altında görünür.
Sunucu tarafı: not 2.0.4 ve Pusula 1.8.5.
