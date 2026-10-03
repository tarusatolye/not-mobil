import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saber/components/theming/dynamic_material_app.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/i18n/strings.g.dart';

void main() {
  group('Theme', () {
    setUpAll(() {
      FlavorConfig.setup();
    });

    // tarus: Saber'in elle vurgu rengi kaldırıldı; renkler TarusTema'dan
    // (test/tarus_tema_test.dart). Burada platform ve yazı tipi sınanır.
    for (final platform in TargetPlatform.values)
      for (final hyperlegible in const [false, true])
        _testTheme(platform: platform, hyperlegible: hyperlegible);
  });
}

void _testTheme({
  required TargetPlatform platform,
  required bool hyperlegible,
}) {
  final repr =
      '${platform.name}_'
      '${hyperlegible ? 'hyperlegible' : 'inter'}';
  testWidgets(repr, (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const Text('hi'))],
    );

    stows.platform.value = platform;
    stows.hyperlegibleFont.value = hyperlegible;
    addTearDown(() {
      stows.platform.value = stows.platform.defaultValue;
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
    for (final theme in [app.theme, ?app.darkTheme]) {
      expect(theme.platform, platform);

      final expectedFontFamily = hyperlegible
          ? 'AtkinsonHyperlegibleNext'
          : switch (platform) {
              .iOS => RegExp('CupertinoSystem(Display|Text)'),
              .linux => 'Adwaita Sans',
              .macOS => '.AppleSystemUIFont',
              .windows => 'Segoe UI',
              _ => 'Roboto',
            };
      for (final font in _extractFonts(theme.textTheme)) {
        expect(font, matches(expectedFontFamily));
      }
    }
  });
}

List<String?> _extractFonts(TextTheme textTheme) {
  return [textTheme.displayLarge?.fontFamily, textTheme.bodyLarge?.fontFamily];
}
