import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextcloud/nextcloud.dart' show DynamiteStatusCodeException;
import 'package:saber/components/settings/app_info.dart';
import 'package:saber/data/nextcloud/pusula_giris.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Not marka plakası (`marka.json`). Giriş düğmesi ve «Beni Hatırla» bu
/// rengi taşır (Pusula Mobil bordo, Sistem Mobil zümrüt gibi).
const _marka = Color(0xFFAC865A);

const _genislik = 420.0;

/// tarus Not giriş ekranı — Pusula Mobil / Sistem Mobil `LoginScreen`
/// kalıbı: ortalanmış 64 px marka plakası, «tarus **Not**» ve ürün tanımı,
/// altında «Giriş Yapın» kartı (alan üstü etiketler, Beni Hatırla, marka
/// renkli düğme); iki adımlı doğrulamada aynı kart kod adımına geçer.
/// Sunucu seçimi yok: kimlik Pusula, notlar not.tarus.tr.
class NcLoginStep extends StatelessWidget {
  const new({super.key, required this.recheckCurrentStep});

  final void Function() recheckCurrentStep;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return LayoutBuilder(
      builder: (context, kisit) => SingleChildScrollView(
        keyboardDismissBehavior: .onDrag,
        padding: const .symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (kisit.maxHeight - 48).clamp(0, double.infinity),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _genislik),
              // Web girişindeki `fade-in zoom-in-95 duration-700` karşılığı:
              // marka ve kart tek blok olarak açılır.
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, d, child) => Opacity(
                  opacity: d,
                  child: Transform.scale(scale: 0.95 + 0.05 * d, child: child),
                ),
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    const _Marka(),
                    const SizedBox(height: 28),
                    _GirisKarti(onBaglandi: recheckCurrentStep),
                    const SizedBox(height: 18),
                    Text.rich(
                      t.login.form.agreeToPrivacyPolicy(
                        linkToPrivacyPolicy: (text) => TextSpan(
                          text: text,
                          style: TextStyle(
                            color: r.accentLt,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrl(AppInfo.privacyPolicyUrl),
                        ),
                      ),
                      textAlign: .center,
                      style: TextStyle(fontSize: 11.5, color: r.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 64 px marka plakası (gölgeli) + «tarus **Not**» + ürün tanımı.
class const _Marka() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _marka.withValues(alpha: 0.38),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const TarusNotIsareti(boyut: 64),
        ),
        const SizedBox(height: 10),
        Text.rich(
          const TextSpan(
            text: 'tarus ',
            children: [
              TextSpan(
                text: 'Not',
                style: TextStyle(fontWeight: FontWeight.w800, color: _marka),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w400,
            color: r.text,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.tarus.giris.urunTanimi,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: r.muted2,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

/// «Giriş Yapın» kartı: e-posta + şifre (ve gerekirse iki adımlı kod).
class const _GirisKarti({required final VoidCallback onBaglandi})
    extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final epostaController = useTextEditingController(
      text: stows.kayitliEposta.value,
    );
    final parolaController = useTextEditingController();
    final kodController = useTextEditingController();
    final beniHatirla = useState(true);
    final challenge = useState<String?>(null);
    final bekliyor = useState(false);
    final hata = useState<String?>(null);
    final g = t.tarus.giris;

    Future<void> girisYap() async {
      final eposta = epostaController.text.trim();
      if (challenge.value == null &&
          (eposta.isEmpty || parolaController.text.isEmpty)) {
        hata.value = g.alanlariDoldurun;
        return;
      }
      if (challenge.value != null && kodController.text.trim().isEmpty) {
        hata.value = g.koduGirin;
        return;
      }
      bekliyor.value = true;
      hata.value = null;
      String? belirtec;
      try {
        final sonuc = challenge.value == null
            ? await PusulaGiris.girisYap(
                eposta: eposta,
                parola: parolaController.text,
              )
            : await PusulaGiris.ikiAdimiTamamla(
                challenge: challenge.value!,
                kod: kodController.text,
              );
        switch (sonuc) {
          case IkiAdimGerekli(challenge: final c):
            kodController.clear();
            challenge.value = c;
            return;
          case BelirtecAlindi(belirtec: final b):
            belirtec = b;
            await PusulaGiris.baglan(belirtec: b);
            // «Beni Hatırla» yalnız e-postayı saklar; şifre cihazda tutulmaz.
            stows.kayitliEposta.value = beniHatirla.value ? eposta : '';
            parolaController.clear();
            onBaglandi();
        }
      } on PusulaGirisHatasi catch (e) {
        hata.value = e.mesaj;
      } on DynamiteStatusCodeException catch (e) {
        hata.value =
            'Not sunucusu eşitlemeyi kabul etmedi (${e.statusCode}). '
            'Birazdan yeniden deneyin.';
      } catch (e) {
        hata.value = 'Bağlanılamadı: $e';
      } finally {
        if (belirtec != null && hata.value != null) {
          unawaited(PusulaGiris.birak(belirtec));
        }
        bekliyor.value = false;
      }
    }

    final r = TarusRenkler.of(context);
    final ikiAdim = challenge.value != null;

    Widget etiket(String metin, {double ust = 0}) => Padding(
      padding: EdgeInsets.only(top: ust, bottom: 8),
      child: Text(
        metin,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: r.muted2,
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const .all(24),
      decoration: BoxDecoration(
        color: r.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: r.border),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            if (!ikiAdim) ...[
              Text(
                g.girisYapin,
                textAlign: .center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: r.text,
                ),
              ),
              const SizedBox(height: 18),
              etiket(g.eposta),
              TextField(
                controller: epostaController,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.email,
                  AutofillHints.username,
                ],
                decoration: InputDecoration(hintText: g.epostaOrnek),
              ),
              etiket(g.parola, ust: 16),
              TextField(
                controller: parolaController,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) {
                  if (!bekliyor.value) girisYap();
                },
                decoration: InputDecoration(hintText: g.parolaOrnek),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: .centerLeft,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => beniHatirla.value = !beniHatirla.value,
                  child: Padding(
                    padding: const .symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: beniHatirla.value
                                ? _marka
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              width: 1.5,
                              color: beniHatirla.value ? _marka : r.border,
                            ),
                          ),
                          child: beniHatirla.value
                              ? const Icon(
                                  TarusIkon.tamam,
                                  size: 13,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          g.beniHatirla,
                          style: TextStyle(fontSize: 12.5, color: r.muted2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _marka.withValues(alpha: 0x18 / 0xFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    TarusIkon.guvenlik,
                    size: 24,
                    color: _marka,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                g.ikiAdimBaslik,
                textAlign: .center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: r.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                g.ikiAdimAciklama,
                textAlign: .center,
                style: TextStyle(fontSize: 12.5, color: r.muted2, height: 1.4),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: kodController,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textAlign: .center,
                textCapitalization: .characters,
                keyboardType: TextInputType.visiblePassword,
                autofillHints: const [AutofillHints.oneTimeCode],
                style: TextStyle(
                  fontSize: 22,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w700,
                  color: r.text,
                ),
                onSubmitted: (_) {
                  if (!bekliyor.value) girisYap();
                },
                decoration: const InputDecoration(hintText: '000000'),
              ),
            ],
            if (hata.value != null) ...[
              const SizedBox(height: 14),
              Text(
                hata.value!,
                style: TextStyle(fontSize: 12.5, color: r.danger, height: 1.4),
              ),
            ],
            SizedBox(height: ikiAdim ? 22 : 26),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _marka.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: bekliyor.value ? null : girisYap,
                style: FilledButton.styleFrom(
                  backgroundColor: _marka,
                  disabledBackgroundColor: _marka.withValues(alpha: 0.7),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: bekliyor.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        ikiAdim ? g.dogrula : g.baglan,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
            if (ikiAdim) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: bekliyor.value
                    ? null
                    : () {
                        challenge.value = null;
                        hata.value = null;
                        parolaController.clear();
                      },
                icon: Icon(TarusIkon.geri, size: 16, color: r.muted),
                label: Text(
                  g.girisEkraninaDon,
                  style: TextStyle(fontSize: 12.5, color: r.muted2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
