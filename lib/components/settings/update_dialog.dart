import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saber/components/settings/app_info.dart';
import 'package:saber/components/settings/update_manager.dart';
import 'package:saber/data/locales.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:url_launcher/url_launcher.dart';

class const UpdateDialog({super.key}) extends StatefulWidget {
  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  String? directDownloadLink;
  var downloadNotAvailableYet = false;

  /// Null if not started yet, or the [TaskStatus] of the download.
  TaskStatus? directDownloadStatus;

  /// Null if not started yet, or the progress (0.0 to 1.0) of the download.
  final directDownloadProgress = ValueNotifier<double?>(null);

  late final localeCode = LocaleSettings.currentLocale == .en
      ? null
      : LocaleSettings.currentLocale.languageTag;
  String? englishChangelog;
  String? translatedChangelog;
  var showTranslatedChangelog = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    directDownloadProgress.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    directDownloadLink = await UpdateManager.getLatestDownloadUrl();
    if (!mounted) return;
    downloadNotAvailableYet =
        UpdateManager.platformFileRegex.containsKey(defaultTargetPlatform) &&
        directDownloadLink == null;

    englishChangelog = await UpdateManager.getChangelog();
    if (!mounted) return;
    translatedChangelog = localeCode == null
        ? null
        : await UpdateManager.getChangelog(localeCode: localeCode!);
    if (!mounted) return;
    showTranslatedChangelog = translatedChangelog != null;
    setState(() {});
  }

  bool get _canStartDownload {
    if (downloadNotAvailableYet) return false;
    if (directDownloadStatus?.isNotFinalState ?? false) return false;
    return true;
  }

  Future<void> _startDownload() async {
    if (!_canStartDownload) return;
    if (directDownloadLink == null) {
      launchUrl(AppInfo.releasesUrl);
      return;
    }
    if (!mounted) return;

    await UpdateManager.directlyDownloadUpdate(
      directDownloadLink!,
      onStatus: (status) {
        directDownloadStatus = status;
        if (mounted) setState(() {});
      },
      onProgress: (progress) {
        directDownloadProgress.value = progress;
      },
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final degisiklikler = showTranslatedChangelog && translatedChangelog != null
        ? translatedChangelog
        : englishChangelog;
    return TarusDialog(
      title: Text(t.update.updateAvailable),
      content: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          Text(t.update.updateAvailableDescription),

          if (degisiklikler != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const .all(12),
              decoration: BoxDecoration(
                color: r.card2,
                borderRadius: const .all(.circular(TarusOlcu.rLg)),
                border: Border.all(color: r.bdr1),
              ),
              child: Text(
                degisiklikler,
                style: TextStyle(fontSize: 12.5, color: r.text, height: 1.5),
              ),
            ),
          ],

          if (translatedChangelog != null && englishChangelog != null)
            Align(
              alignment: .centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  showTranslatedChangelog = !showTranslatedChangelog;
                }),
                icon: const Icon(TarusIkon.dil, size: 16),
                label: Text(
                  showTranslatedChangelog
                      ? localeNames[localeCode] ?? localeCode!
                      : localeNames['en']!,
                ),
              ),
            ),

          if (downloadNotAvailableYet) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: .start,
              children: [
                Icon(TarusIkon.uyari, size: 16, color: r.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.update.downloadNotAvailableYet,
                    style: TextStyle(color: r.danger),
                  ),
                ),
              ],
            ),
          ],

          ValueListenableBuilder(
            valueListenable: directDownloadProgress,
            builder: (context, progress, _) {
              if (progress == null) return const SizedBox();
              return Padding(
                padding: const .only(top: 16.0),
                child: ClipRRect(
                  borderRadius: const .all(.circular(999)),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: r.accent,
                    backgroundColor: r.ovl2,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        TarusDialogDugmesi(
          onPressed: () => Navigator.pop(context),
          child: Text(
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
          ),
        ),
        TarusDialogDugmesi(
          onPressed: _canStartDownload ? _startDownload : null,
          child: Text(t.update.update),
        ),
      ],
    );
  }
}
