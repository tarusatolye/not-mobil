import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextcloud/core.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:regexed_validator/regexed_validator.dart';
import 'package:saber/components/settings/app_info.dart';
import 'package:saber/data/nextcloud/login_flow.dart';
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/nextcloud/pusula_belirteci.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:url_launcher/url_launcher.dart';

const _width = 400.0;

class NcLoginStep extends HookWidget {
  const new({super.key, required this.recheckCurrentStep});

  final void Function() recheckCurrentStep;

  SaberLoginFlow _createLoginFlow(BuildContext context, Uri serverUrl) {
    final loginFlow = SaberLoginFlow.start(serverUrl: serverUrl);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LoginFlowDialog(loginFlow: loginFlow),
    );

    loginFlow.future.then((credentials) async {
      final client = NextcloudClient(
        Uri.parse(credentials.server),
        loginName: credentials.loginName,
        appPassword: credentials.appPassword,
        httpClient: NextcloudClientExtension.newHttpClient(),
      );
      final username = await client.getUsername();

      stows.url.value =
          credentials.server ==
              NextcloudClientExtension.defaultNextcloudUri.toString()
          ? ''
          : credentials.server;
      stows.username.value = username;
      stows.ncPassword.value = credentials.appPassword;

      stows.pfp.value = null;
      client.core.avatar
          .getAvatar(userId: username, size: AvatarGetAvatarSize.$512)
          .then((response) => response.body)
          .then((pfp) => stows.pfp.value = pfp);

      recheckCurrentStep();
    });

    return loginFlow;
  }

  @override
  Widget build(BuildContext context) {
    final loginFlow = useState<SaberLoginFlow?>(null);
    // dispose the login flow when it changes or the widget is disposed
    useEffect(() => loginFlow.value?.dispose, [loginFlow.value]);

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
        const SizedBox(height: TarusOlcu.blokArasi),
        _LoginWithNextcloud(
          login: (url) =>
              loginFlow.value = _createLoginFlow(context, Uri.parse(url)),
        ),
      ],
    );
  }
}

/// Üst bölüm: Not işareti, ad, kısa açıklama ve gizlilik onayı.
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
            const TarusNotIsareti(boyut: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'tarus Not',
                style: TextStyle(
                  fontSize: TarusOlcu.yaziSayfaBasligi,
                  fontWeight: FontWeight.w700,
                  color: r.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          t.tarus.giris.altBaslik,
          style: TextStyle(fontSize: 14, color: r.text, height: 1.45),
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
          style: TextStyle(fontSize: 12, color: r.muted2, height: 1.45),
        ),
      ],
    );
  }
}

class const _LoginWithPusula({required final VoidCallback onBaglandi})
    extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final belirtecController = useTextEditingController();
    final bekliyor = useState(false);
    final hata = useState<String?>(null);
    final gecerli = useListenableSelector(
      belirtecController,
      () => PusulaBelirteci.gecerliMi(belirtecController.text),
    );

    Future<void> baglan() async {
      bekliyor.value = true;
      hata.value = null;
      final sunucu = NextcloudClientExtension.defaultNextcloudUri;
      try {
        final kullaniciAdi = await PusulaBelirteci.dogrula(
          sunucu: sunucu,
          belirtec: belirtecController.text,
        );
        PusulaBelirteci.kaydet(
          sunucu: sunucu,
          kullaniciAdi: kullaniciAdi,
          belirtec: belirtecController.text,
        );
        onBaglandi();
      } on DynamiteStatusCodeException catch (e) {
        hata.value = e.statusCode == 401
            ? 'Belirteç geçersiz ya da iptal edilmiş. Pusula → Ayarlar → Not eşitleme ekranından yeni bir belirteç oluşturun.'
            : 'Sunucu yanıt vermedi (${e.statusCode}). Birazdan yeniden deneyin.';
      } catch (e) {
        hata.value = 'Bağlanılamadı: $e';
      } finally {
        bekliyor.value = false;
      }
    }

    final r = TarusRenkler.of(context);
    return TarusKart(
      padding: const .all(TarusOlcu.kart + 2),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa),
                  borderRadius: const .all(.circular(TarusOlcu.rMd)),
                ),
                child: Icon(TarusIkon.esitle, size: 17, color: r.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.tarus.giris.pusulaBaslik,
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
            t.tarus.giris.pusulaAciklama,
            style: TextStyle(fontSize: 13, color: r.muted2, height: 1.45),
          ),
          const SizedBox(height: 14),
          TextField(
            autocorrect: false,
            enableSuggestions: false,
            controller: belirtecController,
            decoration: InputDecoration(
              labelText: t.tarus.giris.belirtec,
              hintText: '${PusulaBelirteci.onek}…',
              prefixIcon: const Icon(TarusIkon.kilit, size: 18),
              errorText: hata.value,
              errorMaxLines: 4,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: gecerli && !bekliyor.value ? baglan : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(TarusOlcu.birincilDugme),
            ),
            child: bekliyor.value
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(t.tarus.giris.baglan),
          ),
        ],
      ),
    );
  }
}

class const _LoginWithNextcloud({
  required final void Function(String url) login,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final serverUrlController = useTextEditingController();

    final isServerUrlValid = useListenableSelector(serverUrlController, () {
      final url = _prependHttpsIfMissing(serverUrlController.text);
      return validator.url(url);
    });

    final r = TarusRenkler.of(context);
    return TarusKart(
      golge: false,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const .symmetric(horizontal: TarusOlcu.kart + 2),
          childrenPadding: const .fromLTRB(
            TarusOlcu.kart + 2,
            0,
            TarusOlcu.kart + 2,
            TarusOlcu.kart + 2,
          ),
          leading: Icon(TarusIkon.baglanti, size: 18, color: r.muted2),
          title: Text(
            t.login.ncLoginStep.otherNcServer,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: r.text,
            ),
          ),
          expandedCrossAxisAlignment: .stretch,
          children: [
            Text(
              t.tarus.giris.kendiSunucunuzAciklama,
              style: TextStyle(fontSize: 13, color: r.muted2, height: 1.45),
            ),
            const SizedBox(height: 12),
            TextField(
              autocorrect: false,
              autofillHints: const [AutofillHints.url],
              controller: serverUrlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: t.login.ncLoginStep.serverUrl,
                hintText: 'https://sunucu.ornek.com',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isServerUrlValid
                  ? () {
                      serverUrlController.text = _prependHttpsIfMissing(
                        serverUrlController.text,
                      );
                      login(serverUrlController.text);
                    }
                  : null,
              child: Text(t.login.ncLoginStep.loginWithNextcloud),
            ),
          ],
        ),
      ),
    );
  }
}

class const _LoginFlowDialog({required final SaberLoginFlow loginFlow})
    extends HookWidget {
  @override
  Widget build(BuildContext context) {
    useMemoized(
      () => loginFlow.future.then((_) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
      }),
      [loginFlow],
    );

    return AlertDialog(
      title: Text(t.login.ncLoginStep.loginFlow.pleaseAuthorize),
      content: Column(
        mainAxisSize: .min,
        children: [
          Text(t.login.ncLoginStep.loginFlow.followPrompts),
          TextButton(
            onPressed: loginFlow.openLoginUrl,
            child: Text(t.login.ncLoginStep.loginFlow.browserDidntOpen),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            loginFlow.dispose();
            Navigator.of(context).pop();
          },
          child: Text(t.common.cancel),
        ),
        _FakeDoneButton(child: Text(t.common.done)),
      ],
    );
  }
}

/// [SaberLoginFlow] polls the login flow and completes automatically.
///
/// The done button isn't needed, but it's added to prevent the user from
/// closing the dialog before the login flow is completed.
///
/// When pressed, the text will be replaced with a spinner for 2 seconds.
class const _FakeDoneButton({required final Widget child}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final timer = useRef<Timer?>(null);
    useEffect(() => timer.value?.cancel, [timer.value]);

    return TextButton(
      onPressed: pressed.value
          ? null
          : () {
              timer.value?.cancel();
              timer.value = Timer(const Duration(seconds: 2), () {
                pressed.value = false;
              });
              pressed.value = true;
            },
      child: pressed.value
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(),
            )
          : child,
    );
  }
}

String _prependHttpsIfMissing(String url) =>
    url.startsWith(RegExp(r'https?://')) ? url : 'https://$url';
