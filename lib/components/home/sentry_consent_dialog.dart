import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:saber/components/settings/app_info.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/sentry/sentry_consent.dart';
import 'package:saber/data/sentry/sentry_init.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:url_launcher/url_launcher.dart';

class const SentryConsentDialog({super.key}) extends StatelessWidget {
  static Future<void> showIfNeeded(BuildContext context) async {
    // Don't ask on FOSS builds
    if (!isSentryAvailable) return;

    // Don't ask if consent is already known
    assert(
      stows.sentryConsent.loaded,
      'Sentry consent should be loaded in initSentry',
    );
    if (stows.sentryConsent.value != .unknown) return;

    // Show the dialog
    await show(context);
  }

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SentryConsentDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    void yanitla(SentryConsent yanit) {
      stows.sentryConsent.value = yanit;
      Navigator.of(context).pop();
    }

    return TarusDialog(
      title: Text(t.sentry.consent.title),
      content: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: t.sentry.consent.description.question),
            const TextSpan(text: '\n\n'),
            TextSpan(text: t.sentry.consent.description.scope),
            const TextSpan(text: '\n\n'),
            TextSpan(
              text: isSentryEnabled
                  ? t.sentry.consent.description.currentlyOn
                  : t.sentry.consent.description.currentlyOff,
            ),
            const TextSpan(text: '\n\n'),
            t.sentry.consent.description.learnMoreInPrivacyPolicy(
              link: (text) => TextSpan(
                text: text,
                style: TextStyle(color: r.accent, fontWeight: FontWeight.w600),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launchUrl(AppInfo.privacyPolicyUrl);
                  },
              ),
            ),
          ],
        ),
      ),
      // Sonuncu düğme birincil (Evet); Daha sonra yalnız ilk soruda.
      actions: [
        if (stows.sentryConsent.value == .unknown)
          TarusDialogDugmesi(
            onPressed: () => yanitla(.unknown),
            child: Text(t.sentry.consent.answers.later),
          ),
        TarusDialogDugmesi(
          onPressed: () => yanitla(.denied),
          child: Text(t.sentry.consent.answers.no),
        ),
        TarusDialogDugmesi(
          onPressed: () => yanitla(.granted),
          child: Text(t.sentry.consent.answers.yes),
        ),
      ],
    );
  }
}
