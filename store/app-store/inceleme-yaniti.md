# App Store inceleme notu — tarus Not (tr.tarus.not)

İlk gönderim. Bu metin App Store Connect › sürüm › **App Review Information › Notes** alanına yapıştırılır (4000 karakter sınırı). Ekran kaydı ([cekim-senaryosu.md](cekim-senaryosu.md)) gönderimden sonra inceleme mesajına ek olarak verilir ya da Notes'ta bağlantıyla paylaşılır. Parola burada yok; «Sign-in required» alanına kullanıcı girer.

**Göndermeden önce (hesap sahibi):**
- Pusula'da inceleme hesabı (`test@tarus.tr`, «Demo Şirket») var, iki adımlı doğrulama **kapalı**, hesabın not.tarus.tr'de birkaç örnek notu var (düz yazı, el yazısı, görselli).
- Silme adımı için **ayrı atılabilir hesap** (Demo Şirket'e eklenmiş, tek yönetici olmayan; ör. `silme-deneme-not@…`). İnceleme hesabı silinmesin diye Notes'ta bunun için ikinci hesap yazılır (aşağıda «Demo account 2»); inceleme hesabı kullanılırsa silinince yeniden kurulmalı.
- Cloudflare'de Apple ASN 714 izni `not.tarus.tr` **ve `pusula.tarus.tr`** için geçerli (uygulama girişi Pusula'ya, notlar Not sunucusuna gider); dağıtım yalnız Türkiye.
- Pusula `/auth/me/hesabi-sil/` canlıda (2026-11-14: kimliksiz çağrı 401 döndü).

---

## Notes (English — paste as is)

1. Purpose and target audience
tarus Not is the handwritten note-taking and sketching app of the tarus software suite for architecture and engineering offices in Turkey. Staff write and draw notes with a pen or a finger (pens, highlighter, shapes, images, PDFs), organise them in folders, and the notes sync with the same company's web version (not.tarus.tr). tarus is a multi-tenant service: any architecture or engineering firm can register its company on the web and invite its staff; the app is not built for a single company.

2. How to review the app
- Demo account: test@tarus.tr (password in the "Sign-in required" fields). It belongs to the sample company "Demo Şirket" and already has sample notes. Two-step verification is off for this account.
- Steps: open the app → on the sign-in screen enter the e-mail ("E-posta") and the password ("Şifre") → tap "Giriş Yap" (Sign in). The home screen ("Hızlı Bakış") opens; the "Notlar" tab lists the notes and folders, "Beyaz tahta" is a whiteboard. Tap a note to open it, or the "+" button to create one and draw with a finger (Apple Pencil on iPad). The "Ayarlar" (Settings) tab shows the account card with the sync status and, on the profile screen, the buttons "Çıkış yap" (Sign out) and "Hesabı sil" (Delete account).
- The interface is in Turkish (English if the device language is English).
- Accounts are not created inside the app: a company registers on the web (pusula.tarus.tr) and its administrators add their staff. The app has no separate account of its own; the identity is the Pusula account.
- Account deletion (5.1.1(v)): Settings → account/profile screen → "Hesabı sil". The user enters the account e-mail and password (and the 2-step code if enabled), then sees what will be deleted (profile data, all notes on the Not server, notes on the device, device access tokens) and what stays with the company, and confirms with "Hesabımı kalıcı olarak sil" → "Sil". The notes on the server are deleted first, then the account; the device is wiped and the app returns to the sign-in screen. Signing in again with that account fails. Company records stay with the company, with the author shown as "deleted user". Please use "Demo account 2" below for this step so the main demo account stays usable: silme-deneme-not@tarus.tr (password in the "Sign-in required" notes field; if you prefer, create a throw-away account yourself, no sign-up in the app is needed).
- Content visibility: notes are only visible to the signed-in user who wrote them (and the same user's web session). There is no public, anonymous or shared-with-strangers content, and no user-to-user messaging in the app.

3. External services
- Sign-in: our own Pusula server (pusula.tarus.tr, self-hosted in Turkey). E-mail and password go only to this server; the app keeps only a revocable per-device sync token afterwards. No third-party or social sign-in.
- Notes sync: our own server (not.tarus.tr, self-hosted in Turkey) over HTTPS.
- Optional bug report ("Hata bildir"): sends the text the user types (and an optional screenshot they attach) to our own support system (sistem.tarus.tr).
- Camera / Photos: only when the user adds a photo to a note or exports an image; nothing is uploaded except as part of the note.
- Payments, in-app purchases, advertising, analytics, crash-reporting SDKs, artificial intelligence: none. The app contains no donation or purchase links and does not download or execute code or app updates; updates come only through the App Store.

4. Regional differences
Offered only in Turkey and works the same throughout Turkey. Our services only accept traffic from Turkey; we have allowed Apple's network for App Review. If you see a connection error, please reply with the time and we will allow the address immediately.

5. Regulated industry
Not applicable.

6. Open source
tarus Not is built on the open-source note app Saber (GPL-3.0). The complete source code of this version is public at https://github.com/tarusatolye/not-mobil and is linked in the app under Settings → About (Hakkında) together with the license notice.

Emre Yıldırım — tarus
