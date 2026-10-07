import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saber/components/theming/dynamic_material_app.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tarus_tema.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:saber/tarus/tarus_tema_kur.dart';

void main() {
  group('Theme', () {
    setUpAll(FlavorConfig.setup);

    // tarus: Saber'in platform seçicisi ve Cupertino/Yaru görünümü kalktı;
    // yazı tipi her platformda Inter, okunaklı yazı tipi seçiliyse
    // Atkinson Hyperlegible Next.
    for (final hyperlegible in const [false, true])
      testWidgets(hyperlegible ? 'hyperlegible' : 'inter', (tester) async {
        final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, _) => const Text('hi'))],
        );

        stows.hyperlegibleFont.value = hyperlegible;
        addTearDown(() {
          stows.hyperlegibleFont.value = stows.hyperlegibleFont.defaultValue;
        });

        await tester.pumpWidget(
          TranslationProvider(
            child: DynamicMaterialApp(title: 'title', router: router),
          ),
        );

        final app = tester.widget<ExplicitlyThemedApp>(
          find.byType(ExplicitlyThemedApp),
        );
        final beklenen = hyperlegible ? okunakliYaziTipi : tarusYaziTipi;
        for (final theme in [app.theme, ?app.darkTheme]) {
          expect(theme.textTheme.displayLarge?.fontFamily, beklenen);
          expect(theme.textTheme.bodyLarge?.fontFamily, beklenen);
        }
      });

    test('her temada kabuk token uzantısı ve ölçüler', () {
      for (final tema in TarusTema.hepsi) {
        final theme = TarusTemaKur.kur(tema);
        final r = theme.extension<TarusRenkler>()!;
        expect(r.accent, tema.accent, reason: tema.id);
        expect(r.bg, tema.bg, reason: tema.id);
        expect(r.card, tema.card, reason: tema.id);
        expect(theme.scaffoldBackgroundColor, tema.bg, reason: tema.id);

        final kart = theme.cardTheme.shape! as RoundedRectangleBorder;
        expect(
          kart.borderRadius,
          const BorderRadius.all(Radius.circular(TarusOlcu.rKart)),
        );
        expect(kart.side.width, 1);
        final pencere = theme.dialogTheme.shape! as RoundedRectangleBorder;
        expect(
          pencere.borderRadius,
          const BorderRadius.all(Radius.circular(TarusOlcu.rModal)),
        );
      }
    });

    test('kağıt çizgileri temadan bağımsız (dışa aktarmayla aynı)', () {
      expect(TarusKagit.cizgi, Colors.blue);
      expect(TarusKagit.kenar, Colors.red);
    });
  });
}
