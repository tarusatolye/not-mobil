import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/is_this_a_test.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/version.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:url_launcher/url_launcher.dart';

class const AppInfo({super.key}) extends StatelessWidget {
  static final Uri privacyPolicyUrl = Uri.parse(
    'https://saber.adil.hanney.org/privacy-policy/',
  );
  static final Uri licenseUrl = Uri.parse(
    'https://github.com/saber-notes/saber/blob/main/LICENSE.md',
  );
  static final Uri releasesUrl = Uri.parse(
    'https://github.com/saber-notes/saber/releases',
  );

  /// tarus Not'un üzerine geliştirildiği açık kaynak Saber.
  static final Uri saberKaynakUrl = Uri.parse(
    'https://github.com/saber-notes/saber',
  );

  /// tarus Not'un kaynak kodu (GPL-3.0 §6: ikili dağıtımla birlikte kaynak).
  static final Uri kaynakKoduUrl = Uri.parse(
    'https://github.com/tarusatolye/not-mobil',
  );

  /// GPL-3.0 kaynak bildirimi (Hakkında penceresinde; TARUS_NOT.md → Lisans).
  static String get tarusLisansNotu =>
      'tarus Not, açık kaynak Saber uygulaması '
      '(© 2022-$buildYear Adil Hanney ve katkıda bulunanlar) üzerine '
      'geliştirilmiştir. tarus Not da Saber gibi GNU Genel Kamu Lisansı '
      'sürüm 3 (GPL-3.0) ile lisanslıdır; tarus değişiklikleri '
      '© 2026-$buildYear tarus. Kaynak kodu aşağıdaki bağlantıdadır.';

  static String get info => [
    // Tests use static values to improve reducibility
    if (isThisATest) 'v1.35.1' else 'v$buildName',
    if (FlavorConfig.flavor.isNotEmpty) FlavorConfig.flavor,
    if (kDebugMode && !isThisATest) t.appInfo.debug,
    if (isThisATest) '(135010)' else '($buildNumber)',
  ].join(' ');

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _showAboutDialog(context),
      child: ValueListenableBuilder(
        valueListenable: stows.locale,
        builder: (context, _, _) => Text(info),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) => showAboutDialog(
    context: context,
    applicationVersion: info,
    applicationIcon: SvgPicture.asset(
      'assets/icon/icon.svg',
      width: 50,
      height: 50,
    ),
    applicationLegalese: t.appInfo.licenseNotice(buildYear: buildYear),
    children: [
      const SizedBox(height: 10),
      Text(tarusLisansNotu),
      const SizedBox(height: 10),
      TextButton(
        onPressed: () => launchUrl(kaynakKoduUrl),
        child: const SizedBox(
          width: double.infinity,
          child: Text('tarus Not kaynak kodu'),
        ),
      ),
      TextButton(
        onPressed: () => launchUrl(saberKaynakUrl),
        child: const SizedBox(
          width: double.infinity,
          child: Text('Saber (temel alınan proje)'),
        ),
      ),
      // tarus: Saber geliştiricisine bağış/depolama düğmesi kaldırıldı
      // (tarus Not kullanıcısını Saber'in ücretli sunucusuna yönlendiriyordu).
      TextButton(
        onPressed: () => launchUrl(licenseUrl),
        child: SizedBox(
          width: double.infinity,
          child: Text(t.appInfo.licenseButton),
        ),
      ),
      TextButton(
        onPressed: () => launchUrl(privacyPolicyUrl),
        child: SizedBox(
          width: double.infinity,
          child: Text(t.appInfo.privacyPolicyButton),
        ),
      ),
    ],
  );
}
