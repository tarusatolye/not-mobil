import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tarus_tema.dart';
import 'package:saber/pages/home/home.dart';
import 'package:saber/tarus/tarus_tema_kur.dart';

/// Hızlı Bakış iki tarus temasında (açık Modern, koyu Karanlık). 1.1.5'ten
/// beri bütün platformlarda aynı görünüm olduğu için platform başına
/// golden tutulmaz.
void main() {
  group('Home themes', () {
    for (final temaId in const ['modern', 'karanlik'])
      testGoldens(temaId, (tester) async {
        FlavorConfig.setup();
        stows.sentryConsent.value = .granted;

        final theme = TarusTemaKur.kur(TarusTema.bul(temaId)!);
        await tester.pumpWidget(
          ScreenshotApp.withConditionalTitlebar(
            device: GoldenScreenshotDevices.androidPhone.device,
            title: 'tarus Not',
            theme: theme,
            home: Theme(
              data: theme,
              child: const HomePage(subpage: HomePage.recentSubpage, path: ''),
            ),
          ),
        );
        await tester.loadAssets();
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/home_theme_$temaId.png'),
        );
      });
  });
}
