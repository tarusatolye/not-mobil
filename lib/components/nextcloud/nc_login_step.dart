import 'dart:async';

import 'package:dynamite_runtime/dynamite_runtime.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:saber/components/settings/app_info.dart';
import 'package:saber/data/nextcloud/pusula_giris.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:url_launcher/url_launcher.dart';

const _width = 420.0;

/// tarus Not ekosistem giriş adımı:
/// Harici sunucu seçimi içermez; kimlik Pusula'dır ve notlar not.tarus.tr ile eşitlenir.
class NcLoginStep extends StatelessWidget {
  const new({super.key, required this.recheckCurrentStep});

  final void Function() recheckCurrentStep;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    return ListView(
      padding: .symmetric(
        horizontal: screenSize.width > _width + 32
            ? (screenSize.width - _width) / 2
            : TarusOlcu.sayfaYatay + 4,
        vertical: 24,
      ),
      children: [
        const _Header(),
        const SizedBox(height: 20),
        _LoginWithPusula(onBaglandi: recheckCurrentStep),
      ],
    );
  }
}

/// Üst bölüm: Not işareti, ad, web sürümü etiketi, kısa açıklama ve gizlilik onayı.
class const _Header() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa),
                borderRadius: BorderRadius.circular(TarusOlcu.rLg),
                border: Border.all(
                  color: r.accent.withValues(alpha: 0.22),
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: const TarusNotIsareti(boyut: 36),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'tarus Not',
                    style: TextStyle(
                      fontSize: TarusOlcu.yaziSayfaBasligi,
                      fontWeight: FontWeight.w700,
                      color: r.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: r.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: r.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'not.tarus.tr',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: r.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          t.tarus.giris.altBaslik,
          style: TextStyle(fontSize: 13, color: r.muted2, height: 1.45),
        ),
        const SizedBox(height: 6),
        Text.rich(
          t.login.form.agreeToPrivacyPolicy(
            linkToPrivacyPolicy: (text) => TextSpan(
              text: text,
              style: TextStyle(color: r.accent, fontWeight: FontWeight.w600),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launchUrl(AppInfo.privacyPolicyUrl);
                },
            ),
          ),
          style: TextStyle(fontSize: 12, color: r.muted, height: 1.45),
        ),
      ],
    );
  }
}

/// «Pusula ile giriş»: Pusula Mobil / Sistem Mobil standartlarında
/// e-posta + parola (ve gerekirse 2FA kodu) formu.
class const _LoginWithPusula({required final VoidCallback onBaglandi})
    extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final epostaController = useTextEditingController();
    final parolaController = useTextEditingController();
    final kodController = useTextEditingController();
    final parolaGizli = useState(true);
    final challenge = useState<String?>(null);
    final bekliyor = useState(false);
    final hata = useState<String?>(null);
    final alanlar = useMemoized(
      () => Listenable.merge([
        epostaController,
        parolaController,
        kodController,
        challenge,
      ]),
    );
    final girilebilir = useListenableSelector(
      alanlar,
      () => challenge.value == null
          ? epostaController.text.trim().isNotEmpty &&
                parolaController.text.isNotEmpty
          : kodController.text.trim().length >= 6,
    );

    Future<void> girisYap() async {
      bekliyor.value = true;
      hata.value = null;
      String? belirtec;
      try {
        final sonuc = challenge.value == null
            ? await PusulaGiris.girisYap(
                eposta: epostaController.text,
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
    return TarusKart(
      padding: const .all(TarusOlcu.kart + 2),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: r.accent.withValues(
                      alpha: TarusOlcu.seciliZeminAlfa,
                    ),
                    borderRadius: const .all(.circular(TarusOlcu.rMd)),
                    border: Border.all(
                      color: r.accent.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    ikiAdim ? TarusIkon.guvenlik : TarusIkon.kullanici,
                    size: 18,
                    color: r.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ikiAdim
                        ? t.tarus.giris.ikiAdimBaslik
                        : t.tarus.giris.pusulaBaslik,
                    style: TextStyle(
                      fontSize: TarusOlcu.yaziBolumBasligi,
                      fontWeight: FontWeight.w700,
                      color: r.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ikiAdim
                  ? t.tarus.giris.ikiAdimAciklama
                  : t.tarus.giris.pusulaAciklama,
              style: TextStyle(fontSize: 13, color: r.muted2, height: 1.45),
            ),
            const SizedBox(height: 14),
            if (!ikiAdim) ...[
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
                decoration: InputDecoration(
                  labelText: t.tarus.giris.eposta,
                  prefixIcon: const Icon(TarusIkon.kullanici, size: 18),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: parolaController,
                obscureText: parolaGizli.value,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) {
                  if (girilebilir && !bekliyor.value) girisYap();
                },
                decoration: InputDecoration(
                  labelText: t.tarus.giris.parola,
                  prefixIcon: const Icon(TarusIkon.kilit, size: 18),
                  errorText: hata.value,
                  errorMaxLines: 4,
                  suffixIcon: IconButton(
                    onPressed: () => parolaGizli.value = !parolaGizli.value,
                    icon: Icon(
                      parolaGizli.value ? TarusIkon.goster : TarusIkon.gizle,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ] else
              TextField(
                controller: kodController,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                autofillHints: const [AutofillHints.oneTimeCode],
                onSubmitted: (_) {
                  if (girilebilir && !bekliyor.value) girisYap();
                },
                decoration: InputDecoration(
                  labelText: t.tarus.giris.kod,
                  prefixIcon: const Icon(TarusIkon.guvenlik, size: 18),
                  errorText: hata.value,
                  errorMaxLines: 4,
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: girilebilir && !bekliyor.value ? girisYap : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(TarusOlcu.birincilDugme),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TarusOlcu.rMd),
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
                      ikiAdim ? t.tarus.giris.dogrula : t.tarus.giris.baglan,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
            if (ikiAdim)
              TextButton(
                onPressed: bekliyor.value
                    ? null
                    : () {
                        challenge.value = null;
                        hata.value = null;
                      },
                child: Text(t.common.cancel),
              ),
          ],
        ),
      ),
    );
  }
}
