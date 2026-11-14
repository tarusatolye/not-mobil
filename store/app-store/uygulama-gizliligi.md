# App Store «App Privacy» (beslenme etiketi) — tarus Not

App Store Connect › App Privacy yanıtları. Kaynak: not-mobil 1.3.0 kodu (`lib/data/nextcloud/`, `lib/data/nextcloud/hata_bildir.dart`, `ios/Runner/Info.plist`); Android karşılığı [../play/veri-guvenligi.md](../play/veri-guvenligi.md). Kod değişirse bu dosya da güncellenir.

**«Do you or your third-party partners collect data from this app?» → Yes.**
«Collect» = cihazdan tarus sunucularına gitmesi. Yalnız cihazda kalan veri sayılmaz. Üçüncü taraf SDK'sı (reklam, analitik, çökme raporu) **yok**; Sentry yalnız testte etkin, DSN Saber'e ait olduğu için kapalı.

## Toplanan veri türleri

| Apple kategorisi › tür | Kullanıcıya bağlı mı | Takip (tracking) | Amaç | Not |
|---|---|---|---|---|
| **Contact Info › Email Address** | Evet | Hayır | App Functionality | Pusula e-postası girişte Pusula'ya gider ve hesap kartında gösterilir. |
| **Contact Info › Name** | Evet | Hayır | App Functionality | Pusula adı hesap kartında gösterilir. |
| **Identifiers › User ID** | Evet | Hayır | App Functionality | Pusula kullanıcı kimliği ve cihaz eşitleme belirteci (`nes_…`, girişte alınır, çıkışta/silmede iptal olur). |
| **User Content › Other User Content** | Evet | Hayır | App Functionality | Notlar, çizimler, eklenen görseller ve PDF'ler not.tarus.tr'ye eşitlenir (zorunlu: giriş ve eşitleme uygulamanın işlevi). |
| **User Content › Photos or Videos** | Evet | Hayır | App Functionality | Yalnız kullanıcı bir notun içine foto eklerse not içeriği olarak eşitlenir; ayrıca «Hata bildir»e kullanıcı ekran görüntüsü eklerse gider (isteğe bağlı, ≤2 MB). |
| **User Content › Customer Support** | Evet | Hayır | App Functionality | «Hata bildir» başlığı ve açıklaması (isteğe bağlı) sistem.tarus.tr'ye gider. |
| **Diagnostics › Other Diagnostic Data** | Evet | Hayır | App Functionality | Yalnız «Hata bildir» ile: işletim sistemi, sürümü, uygulama sürümü (isteğe bağlı). |

## Toplanmayanlar (Hayır)
Konum, kişiler, finans/ödeme bilgisi, sağlık, hassas bilgi, tarama geçmişi, arama geçmişi, satın alımlar, **Identifiers › Device ID (IDFA/IDFV)**, **Usage Data** (ürün etkileşimi, reklam verisi), **Diagnostics › Crash Data / Performance Data**.

## Takip
**Hayır.** Veri, üçüncü taraf verisiyle birleştirilmez, reklam ya da veri aracılarıyla paylaşılmaz; `NSUserTrackingUsageDescription` yoktur (ATT gerekmez).

## Diğer cevaplar
- Aktarılan veri şifreli mi: **Evet** (yalnız HTTPS; not.tarus.tr ve pusula.tarus.tr).
- Veri silme: **Evet**, uygulama içinde Profil › Hesabı sil (Pusula hesabı + sunucudaki notlar + cihazdaki notlar); web yedek yolu https://tarus.tr/hesap-silme.
- Çocuklara yönelik değil; yaş derecesi 4+.
- Gizlilik politikası: https://tarus.tr/gizlilik (§10'da tarus Not bölümü var; «uçtan uca şifreleme» ifadesi 1.1.6'dan beri geçersiz, saklama şifrelemesine göre güncellenmeli; hukuki gözden geçirme önerilir).

## Info.plist izin metinleri (Türkçe, derlemede)
| Anahtar | Metin |
|---|---|
| `NSCameraUsageDescription` | Notlarınıza fotoğraf eklemek için kameranız kullanılır. Görüntüler yalnızca notun içine eklenir. |
| `NSPhotoLibraryUsageDescription` | Notlarınıza eklemek istediğiniz fotoğrafları seçebilmeniz için fotoğraf arşivinize erişilir. |
| `NSPhotoLibraryAddUsageDescription` | Notlarınızdan dışa aktardığınız görselleri fotoğraf arşivinize kaydedebilmek için erişim istenir. |
