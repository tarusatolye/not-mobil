import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/components/baglam_menusu.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/pages/user/hata_bildir_sayfasi.dart';

/// Basılı tutunca Hata bildir: pusula-mobil / posta-mobil `BaglamMenusu`.
void main() {
  setUpAll(FlavorConfig.setup);

  var kartSecildi = 0;

  Widget uygulama({bool etkin = true}) => MaterialApp(
    home: BaglamMenusu(
      modul: 'Deneme',
      etkin: etkin,
      child: Scaffold(
        body: Column(
          children: [
            const SizedBox(
              key: Key('bos'),
              height: 200,
              width: 200,
              child: ColoredBox(color: Colors.white),
            ),
            GestureDetector(
              onLongPress: () => kartSecildi++,
              child: const SizedBox(
                key: Key('kart'),
                height: 100,
                width: 200,
                child: ColoredBox(color: Colors.grey),
              ),
            ),
            const TextField(key: Key('yazi')),
          ],
        ),
      ),
    ),
  );

  Future<void> basiliTut(WidgetTester tester, Finder hedef) async {
    final hareket = await tester.startGesture(tester.getCenter(hedef));
    await tester.pump(
      BaglamMenusu.basiliTutma + const Duration(milliseconds: 50),
    );
    await hareket.up();
    await tester.pumpAndSettle();
  }

  setUp(() => kartSecildi = 0);

  testWidgets('boş yerde basılı tutunca menü, Hata bildir ekranı açılır', (
    tester,
  ) async {
    await tester.pumpWidget(uygulama());
    await basiliTut(tester, find.byKey(const Key('bos')));
    expect(find.text('Hata bildir'), findsOneWidget);
    expect(find.text('Vazgeç'), findsOneWidget);

    await tester.tap(find.text('Hata bildir'));
    await tester.pumpAndSettle();
    expect(find.byType(HataBildirSayfasi), findsOneWidget);
    expect(find.text('Ekran: Deneme'), findsOneWidget);
  });

  testWidgets('Vazgeç menüyü kapatır', (tester) async {
    await tester.pumpWidget(uygulama());
    await basiliTut(tester, find.byKey(const Key('bos')));
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(find.text('Hata bildir'), findsNothing);
    expect(find.byType(HataBildirSayfasi), findsNothing);
  });

  testWidgets('kendi basılı tutma işlevi olan öğe kazanır', (tester) async {
    await tester.pumpWidget(uygulama());
    await basiliTut(tester, find.byKey(const Key('kart')));
    expect(kartSecildi, 1);
    expect(find.text('Hata bildir'), findsNothing);
  });

  testWidgets('kısa dokunuş ve kaydırma menü açmaz', (tester) async {
    await tester.pumpWidget(uygulama());
    await tester.tap(find.byKey(const Key('bos')));
    await tester.pumpAndSettle();
    final hareket = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('bos'))),
    );
    await hareket.moveBy(const Offset(0, 60));
    await tester.pump(
      BaglamMenusu.basiliTutma + const Duration(milliseconds: 50),
    );
    await hareket.up();
    await tester.pumpAndSettle();
    expect(find.text('Hata bildir'), findsNothing);
  });

  testWidgets('yazı alanı odaktayken menü açılmaz', (tester) async {
    await tester.pumpWidget(uygulama());
    await tester.tap(find.byKey(const Key('yazi')));
    await tester.pumpAndSettle();
    await basiliTut(tester, find.byKey(const Key('bos')));
    expect(find.text('Hata bildir'), findsNothing);
  });

  testWidgets('etkin değilse (çizim yüzeyi) menü açılmaz', (tester) async {
    await tester.pumpWidget(uygulama(etkin: false));
    await basiliTut(tester, find.byKey(const Key('bos')));
    expect(find.text('Hata bildir'), findsNothing);
  });
}
