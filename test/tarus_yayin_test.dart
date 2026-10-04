import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/settings/app_info.dart';
import 'package:saber/components/settings/update_manager.dart';
import 'package:saber/data/flavor_config.dart';

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
}
