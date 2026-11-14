# Ekran kaydı çekim senaryosu — tarus Not (App Store 2.1)

Gerçek iPhone, **en son iOS** sürümü, TestFlight'tan kurulan inceleme derlemesi (1.3.0 (103000) ya da sonrası). Süre 2–3 dakika; kesintisiz tek kayıt (montaj yok). Kayıt App Store Connect'te ret/inceleme mesajına **ek** olarak gönderilir.

## Hazırlık
1. Ayarlar › Denetim Merkezi › **Ekran Kaydı** ekli olsun. Odak › **Rahatsız Etme** açık (bildirim düşmesin).
2. Uygulamayı **sil ve TestFlight'tan yeniden kur** (ilk açılış, giriş ekranı görünsün).
3. `test@tarus.tr` Pusula hesabında (Demo Şirket) not.tarus.tr'de örnek notlar olsun: bir el yazısı, bir görselli, bir PDF'li; bir klasör.
4. Silme adımı için **ayrı, atılabilir hesap** (Demo Şirket'e eklenmiş `silme-deneme-not@…`, iki adımlı doğrulama kapalı, şirketin tek yöneticisi değil). `test@tarus.tr`'yi silme; o inceleme hesabı.
5. Fotoğraflar'da notlara eklemek için bir görsel olsun.
6. Pusula `/auth/me/hesabi-sil/` ucu canlıda olmalı (12.–14. adımlar için).

## Çekim
| # | Ekran | Ne yapılır | Süre |
|---|---|---|---|
| 1 | Ayarlar | Kaydı başlat; Ayarlar › Genel › Hakkında › iOS sürümü (2 sn), sonra ana ekrana dön | 8 sn |
| 2 | Açılış | tarus Not simgesine dokun; açılış ve giriş ekranı | 5 sn |
| 3 | Giriş | E-posta `test@tarus.tr` + Şifre › **Giriş Yap** | 15 sn |
| 4 | Ana ekran | Hızlı Bakış (son notlar) ve Notlar sekmesi; bir notu aç (örnek el yazısı) | 15 sn |
| 5 | Yazma | Yeni not (**+**) › parmakla birkaç çizgi yaz, kalem türünü/rengini değiştir, geri al | 25 sn |
| 6 | Görsel | Araç çubuğunda görsel ekle › Fotoğraflar'dan seç (izin sorulursa «İzin Ver») | 15 sn |
| 7 | Klasörler | **Notlar** sekmesi › klasör listesi: bir klasöre gir, yeni klasör oluştur | 10 sn |
| 8 | Dışa aktarma | Not menüsü › paylaş / PDF olarak dışa aktar (iOS paylaşım sayfası), kapat | 10 sn |
| 9 | Profil | Ayarlar sekmesi › hesap kartı › profil ekranı: eşitleme durumu | 10 sn |
| 10 | Hakkında | Ayarlar › **Hakkında**: sürüm, GPL-3.0 bildirimi, kaynak kodu ve gizlilik bağlantıları | 10 sn |
| 11 | Çıkış | Profil › **Çıkış yap** › onay; giriş ekranına dönüş | 10 sn |
| 12 | Silme hesabıyla giriş | Atılabilir hesapla giriş formu | 10 sn |
| 13 | Hesap silme | Profil › **Hesabı sil** › e-posta + parola › **Devam** › silinecek/korunacak özetini kaydır › **Hesabımı kalıcı olarak sil** › onayda **Sil** › «Hesabınız silindi» › **Tamam** › giriş ekranı | 30 sn |
| 14 | Doğrulama | Aynı hesapla tekrar giriş dene → hata iletisi | 10 sn |

Kaydı durdur. 14. adım silmenin gerçek olduğunu gösterir.

## Kayıtta olmayacaklar
- Satın alma, bağış, fiyat, abonelik ekranı (uygulamada yok).
- Gerçek müşteri notları; yalnız Demo Şirket verisi.
