import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saber/data/nextcloud/pusula_hesap_silme.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tarus_baglantilar.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Profil › "Hesabı sil": uygulama içinde hesap ve veri silme
/// (App Store 5.1.1(v); Arkiv'deki «Hesabı Sil» akışının Not karşılığı).
///
/// Not'un ayrı hesabı yoktur; kimlik Pusula hesabıdır ve silme Pusula'nın
/// `/auth/me/hesabi-sil/` ucuyla yapılır ([PusulaHesapSilme]). Pusula'nın
/// silme ucu oturum anahtarı ister, cihazda yalnız eşitleme belirteci
/// durduğundan kullanıcı Pusula e-postası + parolasıyla yeniden girer.
///
/// Adımlar: giriş → (iki adımlı kod) → silinecek/korunacak özeti → onay →
/// sunucudaki notlar silinir → Pusula hesabı silinir → cihaz temizlenir
/// ([onSilindi]: `NotCikisi.cikisYap()` + yönlendirme).
///
/// Web sayfası (`TarusBaglantilar.hesapSilme`) ve e-posta yolu, uygulamaya
/// giremeyenler (parolasız tarus Hesap kullanıcıları, parolasını unutanlar)
/// için yedek olarak kalır; Play'in "web'den silme" şartını da karşılar.
class HesapSilmeDialog extends StatefulWidget {
  const new({super.key, required this.onSilindi});

  /// Hesap silindikten sonra çağrılır: cihazdaki oturum ve notlar temizlenir.
  final Future<void> Function() onSilindi;

  static Future<void> goster(
    BuildContext context, {
    required Future<void> Function() onSilindi,
  }) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => HesapSilmeDialog(onSilindi: onSilindi),
  );

  @override
  State<HesapSilmeDialog> createState() => _HesapSilmeDialogState();
}

enum _Adim { giris, ikiAdim, ozet, bitti }

class _HesapSilmeDialogState extends State<HesapSilmeDialog> {
  static final _eposta = Uri(
    scheme: 'mailto',
    path: TarusBaglantilar.iletisimEposta,
    query: 'subject=tarus%20Not%20hesap%20ve%20veri%20silme',
  );

  final _epostaDenetleyici = TextEditingController(text: stows.eposta.value);
  final _parolaDenetleyici = TextEditingController();
  final _kodDenetleyici = TextEditingController();

  _Adim _adim = _Adim.giris;
  bool _mesgul = false;
  String? _hata;
  String? _challenge;
  HesapSilmeOturumu? _oturum;
  HesapSilmePlani? _plan;
  bool _sunucuNotlariSilindi = true;

  @override
  void dispose() {
    _epostaDenetleyici.dispose();
    _parolaDenetleyici.dispose();
    _kodDenetleyici.dispose();
    final oturum = _oturum;
    if (oturum != null && _adim != _Adim.bitti) {
      unawaited(PusulaHesapSilme.oturumuKapat(oturum));
    }
    super.dispose();
  }

  Future<void> _calistir(Future<void> Function() islem) async {
    setState(() {
      _mesgul = true;
      _hata = null;
    });
    try {
      await islem();
    } on HesapSilmeHatasi catch (e) {
      if (mounted) setState(() => _hata = e.mesaj);
    } finally {
      if (mounted) setState(() => _mesgul = false);
    }
  }

  Future<void> _girisYap() => _calistir(() async {
    final eposta = _epostaDenetleyici.text.trim();
    final parola = _parolaDenetleyici.text;
    if (eposta.isEmpty || parola.isEmpty) {
      throw const HesapSilmeHatasi('E-posta ve parolanızı yazın.');
    }
    final sonuc = await PusulaHesapSilme.girisYap(
      eposta: eposta,
      parola: parola,
    );
    await _girisSonucu(sonuc);
  });

  Future<void> _koduGonder() => _calistir(() async {
    final kod = _kodDenetleyici.text.trim();
    if (kod.isEmpty) throw const HesapSilmeHatasi('Doğrulama kodunu yazın.');
    final sonuc = await PusulaHesapSilme.ikiAdimiTamamla(
      challenge: _challenge!,
      kod: kod,
    );
    await _girisSonucu(sonuc);
  });

  Future<void> _girisSonucu(HesapSilmeGirisi sonuc) async {
    switch (sonuc) {
      case HesapSilmeIkiAdim(:final challenge):
        if (mounted) {
          setState(() {
            _challenge = challenge;
            _adim = _Adim.ikiAdim;
          });
        }
      case HesapSilmeOturumu():
        final plan = await PusulaHesapSilme.plan(sonuc);
        if (!mounted) return;
        setState(() {
          _oturum = sonuc;
          _plan = plan;
          _adim = _Adim.ozet;
        });
    }
  }

  Future<void> _sil() async {
    final oturum = _oturum!;
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => TarusOnay(
        baslik: 'Hesabınız kalıcı olarak silinsin mi?',
        mesaj: 'Bu işlem geri alınamaz.',
        ikon: TarusIkon.uyari,
        renk: TarusRenkler.of(context).danger,
        dugmeler: [
          TarusDialogDugmesi(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TarusDialogDugmesi(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;

    await _calistir(() async {
      // Belirteç hesapla birlikte iptal olacağından notlar önce silinir.
      final notlarSilindi = await PusulaHesapSilme.sunucuNotlariniSil();
      await PusulaHesapSilme.sil(oturum, parola: _parolaDenetleyici.text);
      await widget.onSilindi();
      if (!mounted) return;
      setState(() {
        _sunucuNotlariSilindi = notlarSilindi;
        _adim = _Adim.bitti;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    Widget baslik(String metin) => Padding(
      padding: const .only(top: 14, bottom: 4),
      child: Text(
        metin,
        style: TextStyle(
          fontSize: TarusOlcu.yaziKartBasligi,
          fontWeight: FontWeight.w600,
          color: r.text,
        ),
      ),
    );
    Widget madde(String metin) => Padding(
      padding: const .only(bottom: 2),
      child: Text('• $metin'),
    );
    Widget baglanti(String metin, Uri adres) => Align(
      alignment: .centerLeft,
      child: TextButton(
        onPressed: () => launchUrl(adres, mode: .externalApplication),
        child: Text(metin),
      ),
    );
    final hata = _hata;
    final hataMetni = hata == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const .only(top: 10),
            child: Text(hata, style: TextStyle(color: r.danger)),
          );

    switch (_adim) {
      case _Adim.giris:
        return TarusDialog(
          title: const Text('Hesabı sil'),
          content: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              const Text(
                "tarus Not'un ayrı bir hesabı yoktur; kimliğiniz Pusula "
                'hesabınızdır. Hesabı silmek için Pusula e-postanızı ve '
                'parolanızı yazın. Silmeden önce nelerin silineceğini '
                'göreceksiniz.',
              ),
              const SizedBox(height: 12),
              TarusMetinAlani(
                controller: _epostaDenetleyici,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                focusOrder: const NumericFocusOrder(1),
                placeholder: 'E-posta',
                prefixIcon: const Icon(TarusIkon.kullanici),
                autofocus: _epostaDenetleyici.text.isEmpty,
              ),
              const SizedBox(height: 8),
              TarusMetinAlani(
                controller: _parolaDenetleyici,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                focusOrder: const NumericFocusOrder(2),
                placeholder: 'Parola',
                prefixIcon: const Icon(TarusIkon.kilit),
                autofocus: _epostaDenetleyici.text.isNotEmpty,
              ),
              hataMetni,
              baslik('Giremiyor musunuz?'),
              const Text(
                'Parolanız yoksa ya da giremiyorsanız silme talebini web '
                'sayfasından ya da ${TarusBaglantilar.iletisimEposta} '
                'adresine yazarak iletebilirsiniz. Talepler en geç 30 gün '
                'içinde sonuçlanır.',
              ),
              baglanti('Silme talebi (web)', TarusBaglantilar.hesapSilme),
              baglanti('E-postayla iste', _eposta),
            ],
          ),
          actions: [
            TarusDialogDugmesi(
              onPressed: _mesgul ? null : () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            TarusDialogDugmesi(
              isDefaultAction: true,
              onPressed: _mesgul ? null : _girisYap,
              child: Text(_mesgul ? 'Giriliyor…' : 'Devam'),
            ),
          ],
        );

      case _Adim.ikiAdim:
        return TarusDialog(
          title: const Text('İki adımlı doğrulama'),
          content: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              const Text(
                'Hesabınızda iki adımlı doğrulama açık. Authenticator '
                'uygulamanızdaki kodu ya da bir kurtarma kodunu yazın.',
              ),
              const SizedBox(height: 12),
              TarusMetinAlani(
                controller: _kodDenetleyici,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                focusOrder: const NumericFocusOrder(1),
                placeholder: 'Doğrulama kodu',
                prefixIcon: const Icon(TarusIkon.kilit),
              ),
              hataMetni,
            ],
          ),
          actions: [
            TarusDialogDugmesi(
              onPressed: _mesgul ? null : () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            TarusDialogDugmesi(
              isDefaultAction: true,
              onPressed: _mesgul ? null : _koduGonder,
              child: Text(_mesgul ? 'Doğrulanıyor…' : 'Devam'),
            ),
          ],
        );

      case _Adim.ozet:
        final plan = _plan!;
        return TarusDialog(
          title: const Text('Hesabı kalıcı olarak sil'),
          content: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              Text(
                plan.engel ??
                    '${plan.hesap} hesabı kalıcı olarak silinir; bu hesapla '
                        'bir daha giriş yapamazsınız. Bu işlem geri alınamaz.',
                style: TextStyle(color: r.danger, fontWeight: FontWeight.w600),
              ),
              baslik('Silinecekler'),
              madde(
                'Not sunucusundaki (not.tarus.tr) tüm notlarınız ve bu '
                'cihazdaki notlar',
              ),
              for (final s in plan.silinecek) madde(s),
              baslik('Şirkette kalanlar'),
              for (final s in plan.korunan) madde(s),
              const SizedBox(height: 4),
              const Text('Bu kayıtlarda adınız yerine «Silinmiş kullanıcı» görünür.'),
              if (plan.uyari.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(plan.uyari, style: TextStyle(color: r.warning)),
              ],
              hataMetni,
            ],
          ),
          actions: [
            TarusDialogDugmesi(
              onPressed: _mesgul ? null : () => Navigator.of(context).pop(),
              child: const Text('Vazgeç'),
            ),
            if (plan.engel == null)
              TarusDialogDugmesi(
                isDestructiveAction: true,
                onPressed: _mesgul ? null : _sil,
                child: Text(_mesgul ? 'Siliniyor…' : 'Hesabımı kalıcı olarak sil'),
              ),
          ],
        );

      case _Adim.bitti:
        return TarusDialog(
          title: const Text('Hesabınız silindi'),
          content: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              const Text(
                'Pusula hesabınız silindi ve bu cihazdaki notlar kaldırıldı. '
                'Bu hesapla bir daha giriş yapılamaz.',
              ),
              if (!_sunucuNotlariSilindi) ...[
                const SizedBox(height: 8),
                Text(
                  'Not sunucusundaki notlarınız silinemedi. Silinmesi için '
                  '${TarusBaglantilar.iletisimEposta} adresine yazın.',
                  style: TextStyle(color: r.warning),
                ),
              ],
            ],
          ),
          actions: [
            TarusDialogDugmesi(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
    }
  }
}
