import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/is_this_a_test.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tarus_baglantilar.dart';
import 'package:saber/data/version.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/pages/user/hakkinda_sayfasi.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_renkler.dart';

class const AppInfo({super.key}) extends StatelessWidget {
  /// tarus gizlilik politikası (Saber'in sayfası değil; TarusBaglantilar).
  static Uri get privacyPolicyUrl => TarusBaglantilar.gizlilik;
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
  static Uri get kaynakKoduUrl => TarusBaglantilar.kaynakKodu;

  /// GPL-3.0 kaynak bildirimi (Hakkında penceresinde; TARUS_NOT.md → Lisans).
  static String get tarusLisansNotu =>
      'tarus Not, açık kaynak Saber uygulaması '
      '(© 2022-$buildYear Adil Hanney ve katkıda bulunanlar) üzerine '
      'geliştirilmiştir. tarus Not da Saber gibi GNU Genel Kamu Lisansı '
      'sürüm 3 (GPL-3.0) ile lisanslıdır; tarus değişiklikleri '
      '© 2026-$buildYear tarus. Kaynak kodu aşağıdaki bağlantıdadır.';

  static String get info => [
    // Tests use static values to improve reducibility
    if (isThisATest) '1.35.1' else buildName,
    if (FlavorConfig.flavor.isNotEmpty) FlavorConfig.flavor,
    if (kDebugMode && !isThisATest) t.appInfo.debug,
    if (isThisATest) '(135010)' else '($buildNumber)',
  ].join(' ');

  /// Hakkında sayfasını açar.
  static void hakkindaAc(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const HakkindaSayfasi()));

  /// Ayarlar'ın altındaki sürüm tetikleyicisi (STANDARTLAR §19e: sürüm
  /// numarası Hakkında'yı açar).
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return Center(
      child: TextButton.icon(
        onPressed: () => hakkindaAc(context),
        icon: const TarusNotIsareti(boyut: 18),
        label: ValueListenableBuilder(
          valueListenable: stows.locale,
          builder: (context, _, _) => Text(
            'tarus Not $info',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: r.muted2,
            ),
          ),
        ),
      ),
    );
  }
}
