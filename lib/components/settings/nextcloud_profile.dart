import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:nextcloud/provisioning_api.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/nextcloud/esitleme_uyarisi.dart';
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/nextcloud/saber_syncer.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/quota.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/pages/user/login.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

class const NextcloudProfile({super.key}) extends HookWidget {
  /// If non-null, this will be used instead of the actual login state.
  @visibleForTesting
  static LoginStep? forceLoginStep;

  @override
  Widget build(BuildContext context) {
    final username = useValueListenable(stows.username);
    final ncPassword = useValueListenable(stows.ncPassword);
    final pfp = useValueListenable(stows.pfp);
    final uyari = useValueListenable(EsitlemeUyarisi.son);

    final quota = useValueListenable(stows.lastStorageQuota);
    useMemoized(getStorageQuota, [username, ncPassword]);

    final loginStep = forceLoginStep ?? NcLoginPage.getCurrentStep();
    final heading = switch (loginStep) {
      .waitingForPrefs => '',
      .nc => t.login.status.loggedOut,
      .done => t.login.status.hi(u: stows.username.value),
    };
    final subheading = switch (loginStep) {
      .waitingForPrefs => '',
      .nc => t.login.status.tapToLogin,
      .done => t.login.status.loggedIn,
    };
    const pfpSize = 44.0;
    final r = TarusRenkler.of(context);

    return TarusKart(
      onTap: () => context.push(RoutePaths.login),
      padding: const .fromLTRB(TarusOlcu.kart, 12, 8, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const .all(.circular(TarusOlcu.rLg)),
            child: pfp == null
                ? const _UnknownPfp(size: pfpSize)
                : Image.memory(pfp, width: pfpSize, height: pfpSize),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  heading,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: r.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subheading,
                  style: TextStyle(fontSize: 12, color: r.muted2),
                ),
                if (loginStep == .done) ...[
                  const SizedBox(height: 8),
                  _QuotaSummary(quota: quota),
                  if (uyari != null) ...[
                    const SizedBox(height: 8),
                    EsitlemeUyariSatiri(uyari: uyari),
                  ],
                ],
              ],
            ),
          ),
          if (loginStep == .done)
            IconButton(
              icon: const Icon(TarusIkon.buluttaYukle),
              tooltip: t.settings.resyncEverything,
              onPressed: () async {
                stows.fileSyncResyncEverythingDate.value = DateTime.now();
                final allFiles = await FileManager.getAllFiles(
                  includeExtensions: true,
                  includeAssets: true,
                );
                for (final file in allFiles) {
                  syncer.uploader.enqueueRel(file);
                }
              },
            )
          else
            Icon(TarusIkon.ileri, size: 18, color: r.muted2),
        ],
      ),
    );
  }

  static Future<Quota?> getStorageQuota() async {
    if (forceLoginStep != null) return stows.lastStorageQuota.value;

    final client = NextcloudClientExtension.withSavedDetails();
    if (client == null) return stows.lastStorageQuota.value = null;

    final user = await client.provisioningApi.users.getCurrentUser();
    final quotaRaw = user.body.ocs.data.quota;
    return stows.lastStorageQuota.value = Quota(quotaRaw);
  }
}

class _UnknownPfp extends StatelessWidget {
  const new({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: ColoredBox(
        color: r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa),
        child: Icon(TarusIkon.kullanici, color: r.accent, size: size * 0.5),
      ),
    );
  }
}

class _QuotaSummary extends StatelessWidget {
  const new({required this.quota});

  final Quota? quota;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      spacing: 4,
      children: [
        LinearProgressIndicator(
          semanticsLabel: 'Storage usage',
          value: quota?.progressIndicatorValue,
          minHeight: 6,
          borderRadius: const .all(.circular(3)),
        ),
        Text(
          quota?.describeConcise() ?? Quota.describeConcisePlaceholder(),
          style: TextStyle(fontSize: 11, color: r.muted),
        ),
      ],
    );
  }
}

/// Eşitleme kartında sunucu uyarısı: 503 (geçici, yeniden denenir) ya da
/// 403 (sunucu reddetti; Not sunucusunun Türkçe açıklaması olduğu gibi gösterilir).
class EsitlemeUyariSatiri extends StatelessWidget {
  const new({super.key, required this.uyari});

  final EsitlemeUyarisi uyari;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final gecici = uyari.tur == .gecici;
    final renk = gecici ? r.warning : r.danger;
    final metin = gecici
        ? t.tarus.esitleme.gecici
        : (uyari.mesaj ?? t.tarus.esitleme.reddedildi);
    return Row(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const .only(top: 1),
          child: Icon(
            gecici ? TarusIkon.bulutKapali : TarusIkon.uyari,
            size: 14,
            color: renk,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            metin,
            style: TextStyle(fontSize: 12, height: 1.35, color: r.text),
          ),
        ),
      ],
    );
  }
}
