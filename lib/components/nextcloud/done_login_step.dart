import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:saber/components/misc/faq.dart';
import 'package:saber/components/nextcloud/hesap_silme_dialog.dart';
import 'package:saber/data/extensions/string_extensions.dart';
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/quota.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:url_launcher/url_launcher.dart';

class DoneLoginStep extends StatelessWidget {
  const new({super.key, required this.recheckCurrentStep});

  final void Function() recheckCurrentStep;

  static const width = 400.0;

  static final log = Logger('DoneLoginStep');

  void _logout() {
    stows.url.value = '';
    stows.username.value = '';
    stows.ncPassword.value = '';
    stows.pfp.value = null;
    stows.lastStorageQuota.value = null;
    recheckCurrentStep();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final quota = stows.lastStorageQuota.value;
    final serverName =
        stows.url.value.ifNotEmpty ?? t.login.ncLoginStep.saberNcServer;
    late final serverUri = stows.url.value.isEmpty
        ? NextcloudClientExtension.defaultNextcloudUri
        : Uri.parse(stows.url.value);
    return ListView(
      padding: .symmetric(
        horizontal: screenWidth > width ? (screenWidth - width) / 2 : 16,
        vertical: 16,
      ),
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            if (stows.pfp.value == null)
              if (stows.url.value.isEmpty)
                const TarusNotIsareti(boyut: 36)
              else
                const Icon(TarusIkon.kullanici, size: 32)
            else
              Image.memory(stows.pfp.value!, width: 32, height: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                t.login.status.hi(u: stows.username.value),
                style: textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(quota?.describe() ?? Quota.describePlaceholder()),
        const SizedBox(height: 2),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: quota?.progressIndicatorValue,
          minHeight: 8,
          borderRadius: const .all(.circular(4)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(TarusIkon.cikis, size: 18),
          label: Text(t.profile.logout),
        ),
        const SizedBox(height: 32),
        Text(t.profile.connectedTo, style: const TextStyle(height: 0.8)),
        Text(serverName, style: textTheme.headlineSmall),
        const SizedBox(height: 4),
        Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: OutlinedButton(
                onPressed: () {
                  log.info('Opening URL: $serverUri');
                  launchUrl(serverUri);
                },
                child: Text(t.profile.quickLinks.serverHomepage),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.tight,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: TarusRenkler.of(context).danger,
                ),
                // tarus: Nextcloud'un hesap silme sayfası yerine tarus'taki
                // silme yolları (Pusula belirteci, cihaz, sunucu verisi).
                onPressed: () => HesapSilmeDialog.goster(context),
                child: Text(t.profile.quickLinks.deleteAccount),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(t.profile.faqTitle, style: textTheme.headlineSmall),
        FaqListView(
          shrinkWrap: true,
          items: [for (final item in t.profile.faq) FaqItem(item.q, item.a)],
        ),
      ],
    );
  }
}
