import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saber/components/theming/dynamic_material_app.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tarus_tema.dart';
import 'package:saber/i18n/strings.g.dart';

/// tarus 8 tema: kabuktaki TemaSecici ile aynı kimlik/sıra, tarus.css değerleri.
void main() {
  test('kimlik ve sıra ortak TemaSecici ile aynı', () {
    expect(TarusTema.hepsi.map((t) => t.id), [
      'modern',
      'sage',
      'karanlik',
      'ocean',
      'sand',
      'sunset',
      'forest',
      'violet',
    ]);
    expect(TarusTema.hepsi.where((t) => t.acik).map((t) => t.id), [
      'modern',
      'sage',
      'sand',
    ]);
  });

  test('renkler tarus.css token değerleri', () {
    final karanlik = TarusTema.bul('karanlik')!;
    expect(karanlik.bg, const Color(0xFF050505));
    expect(karanlik.accent, const Color(0xFF2563EB));
    expect(TarusTema.bul('violet')!.accent, const Color(0xFFD946EF));
    expect(TarusTema.bul('sand')!.ad, 'Kahve');
    expect(TarusTema.bul('yok'), isNull);
  });

  test('renk şeması vurguyu ve yüzeyleri taşır', () {
    for (final t in TarusTema.hepsi) {
      final s = t.renkSemasi;
      expect(s.brightness, t.parlaklik, reason: t.id);
      expect(s.primary, t.accent, reason: t.id);
      expect(s.surface, t.bg, reason: t.id);
      expect(s.onSurface, t.text, reason: t.id);
      expect(s.error, t.danger, reason: t.id);
    }
  });

  group('uygulama teması', () {
    setUpAll(FlavorConfig.setup);

    Future<ExplicitlyThemedApp> uygulama(WidgetTester tester) async {
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => const Text('hi'))],
      );
      await tester.pumpWidget(
        TranslationProvider(
          child: DynamicMaterialApp(title: 'title', router: router),
        ),
      );
      return tester.widget<ExplicitlyThemedApp>(
        find.byType(ExplicitlyThemedApp),
      );
    }

    testWidgets('varsayılan: sistem moduna göre Modern Işık / Karanlık', (
      tester,
    ) async {
      final app = await uygulama(tester);
      expect(app.themeMode, ThemeMode.system);
      expect(app.theme.colorScheme.surface, TarusTema.sistemAcik.bg);
      expect(app.darkTheme!.colorScheme.surface, TarusTema.sistemKoyu.bg);
    });

    testWidgets('seçili tema modu ve renkleri belirler', (tester) async {
      stows.tarusTema.value = 'forest';
      addTearDown(() => stows.tarusTema.value = stows.tarusTema.defaultValue);
      final app = await uygulama(tester);
      final orman = TarusTema.bul('forest')!;
      expect(app.themeMode, ThemeMode.dark);
      expect(app.darkTheme!.colorScheme.primary, orman.accent);
      expect(app.theme.colorScheme.surface, orman.bg);
    });
  });

  test('kabuktaki TemaSecici sırasıyla eşleşir (ozluk deposu yanında ise)', () {
    final kabuk = File('../ozluk/tarus-kabuk/components/TemaSecici.tsx');
    if (!kabuk.existsSync()) return; // CI'da ozluk yok
    final idler = RegExp(r"id: '(\w+)'")
        .allMatches(kabuk.readAsStringSync())
        .map((m) => m[1])
        .toList();
    expect(TarusTema.hepsi.map((t) => t.id).toList(), idler);
  });
}
