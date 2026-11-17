# not-mobil — ajan haritası

Not uygulamasının mobil istemcisi: Flutter, Saber çatalı (Saber'den güncelleme alınmaz; dosyaları doğrudan düzenlenir). Kurallar `ozluk/ajan-ozeti.md`, mobil kuralları `ozluk/tarus-kabuk/STANDARTLAR-MOBIL.md`. Ayrıntılı kılavuz `TARUS_NOT.md` (21 KB): bütün okuma, `rg -n "^## " TARUS_NOT.md` ile bölüm aç.

**Belgeler Beyin'e** (kullanıcı 2026-11-14): tasarım, plan, not, rapor ve md belgeleri repoya ya da yerel diske değil Beyin'e yazılır (`bilgi` MCP ya da `PUT https://yetki.tarus.tr/bilgi/belgeler/<yol>/`); repoda yalnız kod ve kodun yanındaki zorunlu belgeler (README, CLAUDE.md, AGENTS.md, CHANGELOG) kalır.

## Yapı
- `lib/tarus/` tarus katmanı — yeni arayüzü buradan kur:
  - `tarus_bilesenler.dart`: `TarusKart`, `TarusDialog`, `TarusIkonDugmesi`, `TarusBosDurum`, `TarusSayfaUstu`, `TarusMetinAlani`, `TarusSecmeli`. **Kullanmadan önce yapıcısını oku** (`rg -n "const .*\(\{" -A15`): örneğin `TarusMetinAlani` `placeholder` alır (`hintText` değil), `onChanged` yoktur, `focusOrder` zorunludur.
  - `tarus_olcu.dart` ölçüler (`TarusOlcu`; olmayan sabit uydurma), `tarus_renkler.dart` renkler (`TarusRenkler.of(context)`; `tarus_renkler_veri.dart` üretilir, elle düzenlenmez), `tarus_ikon.dart` tek ikon ailesi (Lucide).
  - `surum_notlari.dart` Hakkında › Sürüm notları.
- `lib/pages/` ekranlar (ana liste `pages/home/browse.dart`), `lib/components/` parçalar (`components/home/` kartlar, seçim çubuğu), `lib/data/` ayar ve rota (`prefs.dart`, `routes.dart`, `version.dart`).
- Metinler `lib/i18n/*.i18n.yaml` (tr ve en birlikte); `strings_*.g.dart` üretilir (`dart run slang`), elle düzenlenmez.
- Testler `test/*_test.dart`; `test/goldens/` yalnız Linux'ta üretilir.

## Sürüm
`dart scripts/bump_version.dart --custom X.Y.Z --quiet` (`dart run` değil) → `lib/data/version.dart`, `pubspec.yaml`; sonra `metadata/en-US/changelogs/<buildNumber>.txt`, `store/play/tr-TR/yenilikler.txt` (≤500 karakter), `lib/tarus/surum_notlari.dart`, `TARUS_NOT.md` «Sürüm notları» ve `ozluk/surum-notlari/surum-notlari-not-mobil.md`. `test/version_test.dart` eşitliği denetler.

## Doğrulama (derleme gerçekten çalışmalı)
```
flutter pub get
flutter analyze lib/<değişen klasör>     # derleme hatası 0 olmalı
flutter test test/<ilgili>_test.dart       # testler değişen kodu içe aktarıp derler
```
Derleme hatası varsa iş bitmemiştir; araç çalışmıyorsa (analiz sunucusu açılmıyor vb.) testçi «kaldı» yazar, «geçti» yazmaz. Linux'ta `libgtk-3-dev` gerekir; `flutter build` Rust ister (`rust-toolchain.toml`), testler için şart değil.

## Bilinen tuzaklar
- Saber kodu büyük (`lib/components/canvas`, `lib/data/editor`): ilgisiz yerleri okuma; değişikliği `lib/tarus` ve dokunduğun ekranla sınırla.
- Birkaç eşlik PR'ı aynı sürümü (1.3.0 gibi) açarsa sürüm dosyaları çakışır; PR'dan önce `main` ile birleştir, notları birleştir.

## Taslak ve onay kuralı

- Arayüz ya da tasarım taslağı HTML olarak Beyin'e `<uygulama>/taslak/<ad>.html` yoluyla yazılır; kullanıcıya yerel dosya yolu verilmez.
- Kullanıcının kararını gerektiren her şey Sistem › Projeler'de onay olarak açılır; karar orada verilir ve ilgili işe düşer.

## Beyin (bilgi kaynağı)

- Göreve başlamadan önce Beyin dizinini oku: `T:\Ortak\Beyin\genel\tarus.md` (Mac: `/Volumes/arkiv/Ortak/Beyin/genel/tarus.md`); sonra yalnız işle ilgili parçayı aç.
- Paylaşıma erişemeyen ajanlar aynı belgeleri yetki Beyin API'si (`/bilgi/belgeler/<yol>/`) üzerinden okur.
- Beyin'de gizli değer (parola, anahtar, belirteç) tutulmaz; yalnız nerede durduğu yazılır.
