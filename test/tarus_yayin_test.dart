import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/settings/app_info.dart';
import 'package:saber/components/settings/update_manager.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/tarus_baglantilar.dart';
import 'package:saber/data/version.dart';
import 'package:saber/pages/user/login.dart';

/// tarus Not yayın güvenliği: Saber'e özgü imza, güncelleme ve hata
/// raporlama yolları kapalı kalmalı (TARUS_NOT.md → "tarus için kapatılanlar").
void main() {
  test('güncelleme denetimi kapalı (Saber sürümüne bakmaz)', () {
    expect(UpdateManager.etkin, isFalse);
    FlavorConfig.setupFromEnvironment();
    expect(FlavorConfig.shouldCheckForUpdatesByDefault, isFalse);
  });

  test('Saber yedek imza anahtarı depoda yok ve kullanılmıyor', () {
    expect(File('android/fallback-key.jks').existsSync(), isFalse);
    expect(File('android/fallback-key.properties').existsSync(), isFalse);
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, isNot(contains('fallback-key.properties")')));
    expect(gradle, contains('key.properties yok'));
  });

  test("Sentry DSN'i yalnız testte kullanılabilir", () {
    final kaynak = File('lib/data/sentry/sentry_init.dart').readAsStringSync();
    expect(kaynak, contains('bool get isSentryAvailable => isThisATest;'));
  });

  test('GPL-3.0: Saber referansı ve kaynak bağlantıları', () {
    expect(AppInfo.tarusLisansNotu, contains('Saber'));
    expect(AppInfo.tarusLisansNotu, contains('GPL-3.0'));
    expect(AppInfo.kaynakKoduUrl.toString(), contains('tarusatolye/not-mobil'));
    expect(AppInfo.saberKaynakUrl.toString(), contains('saber-notes/saber'));
    expect(
      File('LICENSE.md').readAsStringSync(),
      contains('GNU GENERAL PUBLIC LICENSE'),
    );
  });

  test('GPL-3.0: Saber telif bildirimi her dilde Saber adını taşır', () {
    // 1.1.2'deki mekanik "Saber → tarus Not" değişimi bu satırı 10 dilde
    // bozmuştu (telif Adil Hanney'in, ürün adı değil). 1.1.5'ten beri yalnız
    // Türkçe ve İngilizce (kullanıcı kararı 2026-10-07).
    final diller = Directory('lib/i18n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.i18n.yaml'));
    expect(diller.map((f) => f.uri.pathSegments.last).toSet(), {
      'en.i18n.yaml',
      'tr.i18n.yaml',
    });
    for (final dil in diller) {
      final satirlar = dil.readAsLinesSync();
      final i = satirlar.indexWhere(
        (s) => s.trimLeft().startsWith('licenseNotice'),
      );
      if (i < 0) continue;
      expect(satirlar[i + 1], contains('Saber'), reason: dil.path);
      expect(satirlar[i + 1], isNot(contains('tarus')), reason: dil.path);
    }
  });

  test("Saber'in gizlilik, kayıt ve Nextcloud silme adresleri kullanılmaz", () {
    for (final adres in [
      AppInfo.privacyPolicyUrl,
      TarusBaglantilar.hesapSilme,
      NcLoginPage.signupUrl,
    ]) {
      expect(adres.scheme, 'https');
      expect(adres.host, isNot(contains('saber')));
      expect(adres.host, isNot(contains('hanney')));
    }
    // yazilim.tarus.tr kapatılıyor (2026-10-06): gizlilik ve silme tarus.tr'de
    expect(AppInfo.privacyPolicyUrl.toString(), 'https://tarus.tr/gizlilik');
    expect(
      TarusBaglantilar.hesapSilme.toString(),
      'https://tarus.tr/hesap-silme',
    );
    final profil = File('lib/components/nextcloud/done_login_step.dart')
        .readAsStringSync();
    expect(profil, isNot(contains('drop_account')));
    expect(profil, contains('HesapSilmeDialog'));
  });

  test("User-Agent tarus Not'unki", () {
    final kaynak = File('lib/data/nextcloud/nextcloud_client_extension.dart')
        .readAsStringSync();
    expect(kaynak, contains(r"'tarusNot/$buildName '"));
    expect(kaynak, isNot(contains("'Saber/")));
  });

  test('Play: hedef API ve versionCode Saber dönemi kodlarından büyük', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('targetSdk = maxOf(36, flutter.targetSdkVersion)'));
    expect(
      gradle,
      contains('versionCode = flutter.versionCode + playSurumKaydirma'),
    );
    final kaydirma = int.parse(
      RegExp(r'val playSurumKaydirma = ([\d_]+)')
          .firstMatch(gradle)!
          .group(1)!
          .replaceAll('_', ''),
    );
    // Saber 1.36.1 (136010) ve ABI'ye bölünmüş APK kodu (×10 + 3).
    expect(buildNumber + kaydirma, greaterThan(136010 * 10 + 3));
  });
}
