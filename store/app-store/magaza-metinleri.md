# App Store Connect — tarus Not: kayıt bilgileri ve mağaza metinleri

## 1. Uygulama kaydı (hesap sahibi açar)

App Store Connect › Apps › **+** › New App:

| Alan | Değer |
|---|---|
| Platforms | iOS |
| Name | **tarus Not** |
| Primary Language | **Turkish** |
| Bundle ID | **tr.tarus.not** (Certificates, Identifiers & Profiles › Identifiers'ta kayıtlı olmalı; Xcode «otomatik imzalama» ilk arşivde oluşturur, yoksa elle ekle) |
| SKU | **tarus-not** |
| User Access | Full Access |

Takım: UQYJQL787C. Sürüm 1.3.0, derleme numarası 103000. Kategori: **Productivity** (Birincil), ikincil **Business**. Fiyat: Ücretsiz. Kullanılabilirlik: yalnız **Türkiye**. Telif: `© 2026 tarus`.

## 2. Mağaza metinleri (Türkçe)

**Ad (≤30):** `tarus Not`

**Alt başlık (≤30):** `El yazısı not ve eskiz` (22)

**Tanıtım metni (≤170):**
Kalemle ya da parmağınızla yazın, çizin; notlarınız Pusula hesabınızla telefon ve web arasında eşitlensin.

**Anahtar kelimeler (≤100, virgülle, boşluksuz):**
`el yazısı,not,eskiz,çizim,pdf,not defteri,beyaz tahta,mimar,mühendis,tarus,pusula,şantiye`

**Açıklama (≤4000):**
```
Not, tarus ekosisteminin el yazısı ve eskiz not uygulamasıdır.

Kalemle ya da parmağınızla yazın ve çizin: kalemler, vurgulayıcı, şekiller, görseller ve PDF'ler; sayfalı not ya da beyaz tahta. Karanlık modda notlarınız ters çevrilebilir, koyu zemine açık mürekkeple yazarsınız; görseller ve PDF'ler de birlikte çevrilir.

Notlarınız telefonda ve webde (not.tarus.tr) tek listede durur: telefonda yazdığınız not webde, webde açtığınız not telefonda görünür. Aktarım HTTPS ile şifrelidir; Not sunucusu notları diskte ve yedekte şifreli saklar. Ayrı bir şifreleme parolası gerekmez.

Not'un ayrı bir hesabı yoktur: yalnız Pusula hesabınızla giriş yaparak kullanılır. Hesabınızı uygulamanın içinden silebilirsiniz (Profil › Hesabı sil); silme notlarınızı da kaldırır. Çıkış yaptığınızda notlar bu cihazdan silinir ve not.tarus.tr'de kalır; eşitlenmemiş değişiklik varsa uygulama önce uyarır. Cihazın erişimini çıkış yaparak ya da Pusula › Hesap › Bağlı cihazlar'dan istediğiniz an kaldırabilirsiniz. Notlar cihazlarınız arasında eşitlenir; aynı not iki yerde değişirse eski sürüm kaybolmaz, çakışma kopyası olarak saklanır.

İç içe klasörlerle düzenleyin, son notlarınızı ana ekranda bulun, sorunları uygulamanın içinden bildirin (Ayarlar › Hata bildir).

Reklam, analitik ya da üçüncü taraf izleme yoktur. Uygulama içi satın alma yoktur.

Gizlilik politikası: https://tarus.tr/gizlilik

Açık kaynak: Not, açık kaynak Saber uygulaması (© 2022- Adil Hanney ve katkıda bulunanlar) üzerine geliştirilmiştir ve Saber gibi GNU Genel Kamu Lisansı sürüm 3 (GPL-3.0) ile lisanslıdır. Kaynak kodu: https://github.com/tarusatolye/not-mobil
```

**Bu sürümde yenilikler (≤4000):** `store/play/tr-TR/yenilikler.txt` ile aynı metin.

## 3. Bağlantılar ve inceleme bilgileri

| Alan | Değer |
|---|---|
| Gizlilik politikası URL'si | https://tarus.tr/gizlilik |
| Destek URL'si | https://tarus.tr |
| Pazarlama URL'si | (boş) |
| Yaş derecesi | 4+ (anket: tümüne «Yok»; kullanıcı içeriği yalnız kişisel, herkese açık değil) |
| İçerik hakları | Üçüncü taraf içerik yok (Saber GPL-3.0 kodu, kaynak açık) |
| Dışa aktarma uyumu (şifreleme) | `ITSAppUsesNonExemptEncryption=false` Info.plist'te; yalnız HTTPS/TLS (işletim sistemi şifrelemesi), kendi şifreleme algoritması yok |
| Sign-in required | Evet: `test@tarus.tr` + parola; ikinci hesap `silme-deneme-not@tarus.tr` |
| Review Notes | [inceleme-yaniti.md](inceleme-yaniti.md) |
| İletişim | Emre Yıldırım, yildirimemre5555@gmail.com |
| App Privacy | [uygulama-gizliligi.md](uygulama-gizliligi.md) |
| Ekran görüntüleri | `ekranlar-6.3/` (6.3" 1206×2622; 6.9" için zorunlu değil, Apple büyük boyu ölçekler) |

## 4. Yükleme (kayıt açıldıktan sonra, hesap sahibi)

Derleme (zaten alındı; yeniden gerekirse):
```bash
flutter build ipa --release --export-method app-store
```
Çıktı `build/ios/ipa/*.ipa`. Yükleme, App Store Connect API anahtarıyla (Users and Access › Integrations › App Store Connect API; anahtar `.p8` dosyası `~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8` altında olmalı):
```bash
xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa --apiKey <KEYID> --apiIssuer <ISSUERID>
```
ya da Transporter uygulamasına `.ipa` sürüklenir. Yükleme sonrası TestFlight'ta işlenmesini bekleyip sürüme bağla.
