# Play mağaza girişi: görseller

Metinler `tr-TR/` altında: `baslik.txt` (≤30), `kisa-aciklama.txt` (≤80), `uzun-aciklama.txt` (≤4000), `yenilikler.txt` (≤500, her sürümde güncellenir).

| Görsel | Play şartı | Kaynak |
|---|---|---|
| Uygulama simgesi | 512×512, 32 bit PNG, en çok 1 MB | `simge-512.png` |
| Öne çıkan görsel | 1024×500, JPEG ya da 24 bit PNG (alfa yok) | `one-cikan-1024x500.png` |
| Telefon ekran görüntüleri | 2 ile 8 arası; 24 bit PNG; oran en çok 2:1 | **Hazır (2026-10-07):** `ekranlar/01-son-notlar.png` … `05-malzeme-listesi.png` (Son notlar, kat planı revizyonu, cephe eskizi, saha ziyareti kontrol listesi, malzeme listesi), 1134×2268. `medium_phone` emülatöründe x86_64 debug derlemesiyle, uygulama dili tr-TR, tema Modern Işık. Notlar elle (emülatörde dokunma olaylarıyla) çizildi; proje adları uydurmadır. Ayarlar ekranı alınmadı (Saber'den kalma «Nextcloud» yazısı var), koyu tema alınmadı (kart başlıkları okunmuyor). |

Not: Türkçe karakterli başlıklar `adb input text` ile yazılamadığı için görüntülerdeki metinler ASCII (ör. «Konutlari»).
