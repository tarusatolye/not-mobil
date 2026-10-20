import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:saber/components/nextcloud/hesap_silme_dialog.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/nextcloud/not_cikisi.dart';
import 'package:saber/data/nextcloud/saber_syncer.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/quota.dart';
import 'package:saber/data/tarus_baglantilar.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:url_launcher/url_launcher.dart';

/// tarus Not ekosistem kullanıcı profili ve eşitleme durumu ekranı.
class DoneLoginStep extends StatelessWidget {
  const new({super.key, required this.recheckCurrentStep});

  final void Function() recheckCurrentStep;

  static const width = 440.0;
  static final log = Logger('DoneLoginStep');

  /// Çıkış (kullanıcı kararı 2026-10-19): önce eşitleme denetlenir;
  /// eşitlenmemiş değişiklik varsa ya da sunucuya ulaşılamazsa uyarılır.
  /// Çıkışta notlar cihazdan silinir ([NotCikisi]); yönlendirici giriş
  /// ekranına geçer.
  Future<void> _confirmLogout(BuildContext context) async {
    final denetim = await _bekleyerek(context, NotCikisi.denetle());
    if (denetim == null || !context.mounted) return;

    final cikis = t.tarus.cikis;
    final (String baslik, String metin) = switch (denetim) {
      _ when denetim.temiz => (cikis.baslik, cikis.aciklama),
      _ when !denetim.sunucuyaUlasildi => (
        cikis.denetlenemediBaslik,
        cikis.denetlenemediAciklama,
      ),
      _ => (
        cikis.esitlenmemisBaslik,
        cikis.esitlenmemisAciklama(n: denetim.notSayisi),
      ),
    };
    final r = TarusRenkler.of(context);
    final secim = await showDialog<_CikisSecimi>(
      context: context,
      builder: (context) => TarusOnay(
        baslik: baslik,
        mesaj: metin,
        ikon: denetim.temiz
            ? TarusIkon.cikis
            : denetim.sunucuyaUlasildi
            ? TarusIkon.uyari
            : TarusIkon.bulutKapali,
        renk: denetim.temiz ? r.danger : r.warning,
        dugmeler: [
          TarusDialogDugmesi(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.common.cancel),
          ),
          if (!denetim.temiz && denetim.sunucuyaUlasildi)
            TarusDialogDugmesi(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(_CikisSecimi.esitle),
              child: Text(cikis.esitle),
            ),
          TarusDialogDugmesi(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(_CikisSecimi.cik),
            child: Text(denetim.temiz ? t.profile.logout : cikis.yineDeCik),
          ),
        ],
      ),
    );
    switch (secim) {
      case _CikisSecimi.cik:
        await NotCikisi.cikisYap();
        recheckCurrentStep();
      case _CikisSecimi.esitle:
        unawaited(syncer.uploader.refresh());
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(cikis.esitlemeBasladi)));
        }
      case null:
        break;
    }
  }

  /// Denetim sürerken kapatılamayan bekleme penceresi gösterir.
  static Future<T?> _bekleyerek<T>(
    BuildContext context,
    Future<T> islem,
  ) async {
    final navigator = Navigator.of(context);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: TarusOnay(
            baslik: t.tarus.cikis.baslik,
            mesaj: t.tarus.cikis.denetleniyor,
            rozet: const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        ),
      ),
    );
    try {
      return await islem;
    } catch (e) {
      log.warning('Çıkış denetimi başarısız: $e');
      return null;
    } finally {
      navigator.pop();
    }
  }

  void _resyncAll() async {
    stows.fileSyncResyncEverythingDate.value = DateTime.now();
    final allFiles = await FileManager.getAllFiles(
      includeExtensions: true,
      includeAssets: true,
    );
    for (final file in allFiles) {
      syncer.uploader.enqueueRel(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final quota = stows.lastStorageQuota.value;
    final r = TarusRenkler.of(context);
    final pfp = stows.pfp.value;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth > width
            ? (screenWidth - width) / 2
            : TarusOlcu.sayfaYatay + 4,
        vertical: 20,
      ),
      children: [
        // 1. Profil Kartı
        TarusKart(
          padding: const EdgeInsets.all(TarusOlcu.kart + 2),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(TarusOlcu.rLg),
                child: pfp != null
                    ? Image.memory(
                        pfp,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: r.accent.withValues(
                            alpha: TarusOlcu.seciliZeminAlfa,
                          ),
                          borderRadius: BorderRadius.circular(TarusOlcu.rLg),
                        ),
                        child: Icon(
                          TarusIkon.kullanici,
                          color: r.accent,
                          size: 26,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stows.gorunenAd.value.isNotEmpty
                          ? stows.gorunenAd.value
                          : stows.username.value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: r.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stows.eposta.value.isNotEmpty
                          ? stows.eposta.value
                          : 'Pusula Hesabı',
                      style: TextStyle(fontSize: 12, color: r.muted2),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: r.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'not.tarus.tr ile senkronize',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: r.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Depolama & Eşitleme Kartı
        TarusKart(
          padding: const EdgeInsets.all(TarusOlcu.kart + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: r.accent.withValues(
                        alpha: TarusOlcu.seciliZeminAlfa,
                      ),
                      borderRadius: BorderRadius.circular(TarusOlcu.rSm),
                    ),
                    child: Icon(
                      TarusIkon.buluttaYukle,
                      size: 16,
                      color: r.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Depolama & Eşitleme',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: r.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                quota?.describe() ?? Quota.describePlaceholder(),
                style: TextStyle(fontSize: 13, color: r.muted2),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: quota?.progressIndicatorValue,
                  minHeight: 7,
                  backgroundColor: r.inputBg,
                  valueColor: AlwaysStoppedAnimation<Color>(r.accent),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TarusOlcu.rHap),
                        ),
                      ),
                      onPressed: () => launchUrl(TarusBaglantilar.notWeb),
                      icon: const Icon(TarusIkon.baglanti, size: 16),
                      label: const Text(
                        'Web sürümü (not.tarus.tr)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TarusOlcu.rHap),
                      ),
                    ),
                    onPressed: _resyncAll,
                    icon: const Icon(TarusIkon.esitle, size: 16),
                    label: const Text('Eşitle', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Oturum & Güvenlik Kartı
        TarusKart(
          padding: const EdgeInsets.all(TarusOlcu.kart + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Çıkış: kırmızı kontur + yumuşak zemin, 14 px hap (Arkiv/Sistem).
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: r.danger,
                  backgroundColor: r.danger.withValues(
                    alpha: Theme.brightnessOf(context) == Brightness.light
                        ? 0.04
                        : 0.08,
                  ),
                  side: BorderSide(color: r.danger),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                ),
                onPressed: () => _confirmLogout(context),
                icon: const Icon(TarusIkon.cikis, size: 18),
                label: Text(
                  t.profile.logout,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: r.danger,
                  side: BorderSide(color: r.danger.withValues(alpha: 0.4)),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                ),
                onPressed: () => HesapSilmeDialog.goster(context),
                child: Text(
                  t.profile.quickLinks.deleteAccount,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _CikisSecimi { cik, esitle }
