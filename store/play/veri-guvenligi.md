# tarus Not — Play «Veri güvenliği» formu taslağı

Play Console › Uygulama içeriği › Veri güvenliği formu için yanıtlar. Kaynak: not-mobil 1.1.3
kodu (`lib/data/nextcloud/`, `lib/data/nextcloud/hata_bildir.dart`, `android/app/src/main/AndroidManifest.xml`).
Formu göndermeden önce yayımlanan derlemeyle karşılaştırın; kod değişirse bu dosya da güncellenir.

## Genel sorular

| Soru | Yanıt | Gerekçe |
|---|---|---|
| Uygulama gerekli kullanıcı verisi türlerinden herhangi birini topluyor ya da paylaşıyor mu? | **Evet** | Eşitleme açıksa notlar ve kimlik not.tarus.tr'ye gider; Hata bildir isteğe bağlı. |
| Aktarılan tüm kullanıcı verileri şifreleniyor mu? | **Evet** | Tüm trafik HTTPS (not.tarus.tr). Notlar sunucuda diskte ve yedekte şifreli saklanır (1.1.6'dan beri uçtan uca değil). |
| Kullanıcılar verilerinin silinmesini isteyebilir mi? | **Evet** | Uygulamada Profil › Hesabı sil (adımlar + web talebi), web: `https://tarus.tr/hesap-silme` (talep e-postayla yazilim@tarus.tr'ye, Pusula yöneticisi işler). |
| Hesap oluşturma | Uygulamada hesap **oluşturulmaz**; kimlik Pusula'dır (web'de oluşturulur). Giriş: Pusula eşitleme belirteci. | `lib/components/nextcloud/nc_login_step.dart` |
| Hesap silme URL'si (Play zorunlu alanı) | `https://tarus.tr/hesap-silme` (`TarusBaglantilar.hesapSilme`) | 2026-10-06'da açıldı (tarus#c3bb217). |

## Toplanan veri türleri

«Toplama» = cihazdan geliştiricinin (tarus) sunucusuna gitmesi. Yalnız cihazda kalan veri sayılmaz.

| Play veri türü | Toplanıyor mu | Zorunlu / isteğe bağlı | Amaç | Not |
|---|---|---|---|---|
| **Uygulama içindeki diğer kullanıcı içeriği** (notlar, çizimler, görseller, PDF'ler) | Evet | İsteğe bağlı (eşitleme kapalıyken cihazda kalır) | Uygulama işlevselliği (eşitleme) | 1.1.6'dan beri **uçtan uca şifreli değil**: notlar HTTPS ile düz yolla (`Saber/<klasör>/<ad>.sbn2`) gider; web aynı notu açar. Not sunucusu diskte ve yedekte şirket anahtarıyla (AES-256-GCM, anahtar servisi) şifreli saklar. |
| **Kullanıcı kimlikleri** (Pusula kullanıcı adı, eşitleme belirteci) | Evet | Eşitleme için zorunlu | Uygulama işlevselliği, hesap yönetimi | Belirteç Pusula'da üretilir/iptal edilir; Not sunucusu Pusula'ya doğrulatır. |
| **Fotoğraflar** (Hata bildir ekran görüntüsü) | Evet | İsteğe bağlı, kullanıcı ekler | Uygulama işlevselliği / hata ayıklama | En çok 2 MB, yalnız kullanıcı gönderirse. |
| **Uygulama etkinliği › diğer** (Hata bildir başlığı ve açıklaması) | Evet | İsteğe bağlı | Hata ayıklama | Kullanıcının yazdığı metin. |
| **Uygulama bilgileri ve performans › diğer** (işletim sistemi, sürümü, uygulama sürümü) | Evet | İsteğe bağlı (yalnız Hata bildir ile) | Hata ayıklama | `meta.platform`, `platformVersion`, `appVersion`. |
| Konum, kişiler, finans, sağlık, mesajlar, takvim, cihaz kimliği, reklam kimliği | **Hayır** | | | |
| Çökme günlükleri / tanılama | **Hayır** | | | Sentry yalnız testte etkin (`isSentryAvailable => isThisATest`); FOSS derlemesinde SDK hiç yok. |

Her tür için: **paylaşılmıyor** (üçüncü tarafa aktarılmıyor; Not sunucusu ve Pusula tarus'un kendi
sunucularında), **geçici işlenmiyor** (saklanıyor), reklam/pazarlama/analitik amacı **yok**.

## Güvenlik uygulamaları (form metni için)

- Veriler aktarımda şifrelenir (HTTPS).
- Notlar sunucuda diskte ve yedekte şifreli saklanır (saklama şifrelemesi; uçtan uca değil, 1.1.6).
- Kullanıcı eşitleme erişimini Pusula › Ayarlar › Not eşitleme'den anında iptal edebilir.
- Reklam, analitik ve üçüncü taraf izleme SDK'sı yok.

## Kullanıcının yapacakları

1. Play Console'da «Gizlilik politikası» = `https://tarus.tr/gizlilik`.
2. Gizlilik politikasında tarus Not bölümü var (§10, 2026-10-06) ama **«uçtan uca şifreleme» ifadesi
   1.1.6 ile geçersiz**: saklama şifrelemesine (sunucuda diskte/yedekte şifreli) göre güncellenmeli.
   Hukuki gözden geçirme yine önerilir: saklama şifrelemesi, Pusula belirteci, Hata bildir verisi,
   silme yolu ve süresi. Metin hukuki
   gözden geçirmeden geçmeli (`ozluk/tarus.md` §4.2, Not Mobil satırı: lisans).
3. Formu bu tabloya göre doldurun; yayımlanan derleme FOSS değilse (Onyx/Sentry SDK'ları içeride)
   SDK'ların veri toplamadığını yeniden doğrulayın.
