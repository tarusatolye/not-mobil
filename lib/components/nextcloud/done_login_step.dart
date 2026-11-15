import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:saber/components/nextcloud/hesap_silme_dialog.dart';
import 'package:saber/components/settings/app_info.dart';
import 'package:saber/components/settings/settings_button.dart';
import 'package:saber/components/settings/settings_subtitle.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/nextcloud/not_cikisi.dart';
import 'package:saber/data/nextcloud/saber_syncer.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/quota.dart';
import 'package:saber/data/tarus_baglantilar.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/pages/user/hata_bildir_sayfasi.dart';
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
    final r = TarusRenkler.of(context);
    final h = t.tarus.hesap;

    // Kardeş uygulamaların Hesap ekranı (Arkiv/Sistem/Pusula) yapısı:
    // profil kartı → bölümler → uygulama kartı → Çıkış yap.
    return ListenableBuilder(
      listenable: Listenable.merge([
        stows.gorunenAd,
        stows.eposta,
        stows.pfp,
        stows.username,
        stows.lastStorageQuota,
      ]),
      builder: (context, _) {
        final quota = stows.lastStorageQuota.value;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            screenWidth > width
                ? (screenWidth - width) / 2
                : TarusOlcu.sayfaYatay + 4,
            TarusOlcu.sayfaUst + 4,
            screenWidth > width
                ? (screenWidth - width) / 2
                : TarusOlcu.sayfaYatay + 4,
            32,
          ),
          children: [
            const _ProfilKarti(),

            TarusBolumEtiketi(h.esitlemeDepolama),
            AyarGrubu(
              children: [
                ListTile(
                  contentPadding: AyarSatiri.ic,
                  leading: AyarSatiri.ikon(TarusIkon.buluttaYukle),
                  title: Text(quota?.describe() ?? Quota.describePlaceholder()),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      child: LinearProgressIndicator(
                        value: quota?.progressIndicatorValue,
                        minHeight: 7,
                        backgroundColor: r.inputBg,
                        valueColor: AlwaysStoppedAnimation<Color>(r.accent),
                      ),
                    ),
                  ),
                ),
                SettingsButton(
                  title: h.simdiEsitle,
                  subtitle: h.simdiEsitleAciklama,
                  icon: TarusIkon.esitle,
                  onPressed: _resyncAll,
                  ok: false,
                ),
                SettingsButton(
                  title: h.webSurumu,
                  subtitle: TarusBaglantilar.notWeb.host,
                  icon: TarusIkon.baglanti,
                  onPressed: () => launchUrl(TarusBaglantilar.notWeb),
                ),
              ],
            ),

            TarusBolumEtiketi(h.destek),
            AyarGrubu(
              children: [
                SettingsButton(
                  title: t.tarus.hataBildir,
                  subtitle: t.tarus.hataBildirAciklama,
                  icon: TarusIkon.hataBildir,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HataBildirSayfasi(modul: 'Hesap'),
                    ),
                  ),
                ),
              ],
            ),

            // App Store 5.1.1(v): hesap uygulama içinden silinebilir.
            TarusBolumEtiketi(h.hesapBolumu),
            AyarGrubu(
              children: [
                SettingsButton(
                  title: t.profile.quickLinks.deleteAccount,
                  icon: TarusIkon.sil,
                  onPressed: () => HesapSilmeDialog.goster(
                    context,
                    onSilindi: () async {
                      await NotCikisi.cikisYap();
                      recheckCurrentStep();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            TarusKart(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TarusOlcu.kart,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Text(
                          h.uygulama,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: r.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SurumSatiri(etiket: h.yukluSurum, deger: AppInfo.info),
                  _SurumSatiri(
                    etiket: h.sunucu,
                    deger: NextcloudClientExtension.defaultNextcloudUri.host,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Çıkış: kırmızı kontur + yumuşak zemin, 14 px köşe (Arkiv/Sistem).
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
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
              icon: const Icon(TarusIkon.cikis, size: 17),
              label: Text(
                t.profile.logout,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Sürüm kartı satırı: sol etiket (ikincil), sağ değer (birincil, 600).
class _SurumSatiri extends StatelessWidget {
  const new({required this.etiket, required this.deger});

  final String etiket, deger;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: r.bdr1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TarusOlcu.kart,
          vertical: 13,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                etiket,
                style: TextStyle(fontSize: 13, color: r.muted2),
              ),
            ),
            Text(
              deger,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: r.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profil kartı (Arkiv `SettingsScreen` profileBlock): ortalı 88 pt avatar
/// (fotoğraf ya da baş harfler), ad 18/800, e-posta, hesap rozeti ve
/// «Tarus Kimlik & SSO Profili» düğmesi.
class _ProfilKarti extends StatelessWidget {
  const new();

  static String _basHarfler(String ad) {
    final parcalar = ad.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final harfler = parcalar.take(2).map((p) => p.substring(0, 1)).join();
    if (harfler.isEmpty) return '?';
    final tr = LocaleSettings.currentLocale.languageCode == 'tr';
    return (tr ? harfler.replaceAll('i', 'İ').replaceAll('ı', 'I') : harfler)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final pfp = stows.pfp.value;
    final ad = stows.gorunenAd.value.isNotEmpty
        ? stows.gorunenAd.value
        : stows.username.value;
    final eposta = stows.eposta.value;
    const avatar = 88.0;
    return TarusKart(
      kose: 18,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(TarusOlcu.rHero),
            child: pfp != null
                ? Image.memory(
                    pfp,
                    width: avatar,
                    height: avatar,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: avatar,
                    height: avatar,
                    alignment: Alignment.center,
                    color: r.accent.withValues(
                      alpha: TarusOlcu.seciliZeminAlfa,
                    ),
                    child: Text(
                      _basHarfler(ad),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: r.accentLt,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            ad,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: r.text,
            ),
          ),
          if (eposta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(eposta, style: TextStyle(fontSize: 12, color: r.muted2)),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: r.accent.withValues(alpha: 0x12 / 0xFF),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: r.accentLt),
            ),
            child: Text(
              bolumMetni(t.tarus.hesap.rozet),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: r.accentLt,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: r.inputBg,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              side: BorderSide(color: r.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => launchUrl(TarusBaglantilar.kimlik),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(TarusIkon.guvenlik, size: 16, color: r.accentLt),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        t.tarus.hesap.kimlikProfili,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: r.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Icon(TarusIkon.disBaglanti, size: 13, color: r.muted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CikisSecimi { cik, esitle }
