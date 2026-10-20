import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/nextcloud/not_cikisi.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/routes.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPathProvider();
  FlavorConfig.setup();

  group('Giriş zorunlu', () {
    tearDown(() {
      stows.url.value = '';
      stows.username.value = '';
      stows.ncPassword.value = '';
    });

    test('oturum yokken her sayfa girişe yönlenir, Kayıtlar serbest', () {
      expect(RoutePaths.girisYonlendirmesi('/home/recent'), RoutePaths.login);
      expect(RoutePaths.girisYonlendirmesi('/edit'), RoutePaths.login);
      expect(
        RoutePaths.girisYonlendirmesi(RoutePaths.profile),
        RoutePaths.login,
      );
      expect(RoutePaths.girisYonlendirmesi(RoutePaths.login), isNull);
      expect(RoutePaths.girisYonlendirmesi(RoutePaths.logs), isNull);
    });

    test('oturum açılınca giriş ekranından ana sayfaya geçilir', () {
      stows.username.value = 'pusula-42';
      stows.ncPassword.value = 'nes_0123456789abcdefghij';
      expect(RoutePaths.girisYonlendirmesi(RoutePaths.login), '/home/recent');
      expect(RoutePaths.girisYonlendirmesi('/home/browse'), isNull);
      expect(RoutePaths.girisYonlendirmesi(RoutePaths.profile), isNull);
    });

    test('eski «Başka sunucu» oturumu açık sayılmaz (sunucu sabit)', () {
      stows.url.value = 'https://bulut.ornek.com';
      stows.username.value = 'ali';
      stows.ncPassword.value = 'uygulama-parolasi';
      expect(stows.loggedIn, isFalse);
      expect(RoutePaths.girisYonlendirmesi('/home/recent'), RoutePaths.login);
    });
  });

  group('Eşitlenmemiş değişiklik denetimi', () {
    final t0 = DateTime.utc(2026, 10, 20, 12);

    test('sunucuda olmayan ya da yerelde daha yeni dosyalar', () {
      final sonuc = NotCikisi.esitlenmemisleriBul(
        yerel: {
          '/esit.sbn2': t0,
          '/yeni.sbn2': t0,
          '/degisti.sbn2': t0.add(const Duration(minutes: 3)),
          '/tolerans.sbn2': t0.add(const Duration(milliseconds: 300)),
          '/sunucuda-yeni.sbn2': t0,
          // Sunucu saniyeye keser: 14:00:00.876 yüklenince 14:00:00 döner.
          '/saniye.sbn2': t0.add(const Duration(milliseconds: 876)),
        },
        uzak: {
          '/saniye.sbn2': t0,
          '/esit.sbn2': t0,
          '/degisti.sbn2': t0,
          '/tolerans.sbn2': t0,
          '/sunucuda-yeni.sbn2': t0.add(const Duration(hours: 1)),
          '/yalniz-sunucuda.sbn2': t0,
        },
      );
      expect(sonuc, ['/degisti.sbn2', '/yeni.sbn2']);
    });

    test('görsel ve önizleme notuyla birlikte sayılır', () {
      expect(NotCikisi.notYolu('/a/b.sbn2.0'), '/a/b.sbn2');
      expect(NotCikisi.notYolu('/a/b.sbn2.12'), '/a/b.sbn2');
      expect(NotCikisi.notYolu('/a/b.sbn2.p'), '/a/b.sbn2');
      expect(NotCikisi.notYolu('/a/b.sbn2'), '/a/b.sbn2');
      const denetim = CikisDenetimi(
        esitlenmemis: ['/a/b.sbn2', '/a/b.sbn2.0', '/a/b.sbn2.p', '/c.sbn2'],
        sunucuyaUlasildi: true,
      );
      expect(denetim.notSayisi, 2);
      expect(denetim.temiz, isFalse);
    });

    test('sunucuya ulaşılamazsa temiz sayılmaz', () {
      const denetim = CikisDenetimi(esitlenmemis: [], sunucuyaUlasildi: false);
      expect(denetim.temiz, isFalse);
      expect(
        const CikisDenetimi(esitlenmemis: [], sunucuyaUlasildi: true).temiz,
        isTrue,
      );
    });
  });

  group('Çıkışta notlar cihazdan silinir', () {
    setUpAll(() async {
      await FileManager.init(shouldWatchRootDirectory: false);
    });

    test(
      'notlar, görseller ve boşalan klasörler silinir; yoksayılanlar kalır',
      () async {
        final kok = FileManager.documentsDirectory;
        Future<File> yaz(String yol) async {
          final f = File('$kok$yol');
          await f.create(recursive: true);
          await f.writeAsString('x');
          return f;
        }

        final not = await yaz('/cikis_test/klasor/not.sbn2');
        final gorsel = await yaz('/cikis_test/klasor/not.sbn2.0');
        final onizleme = await yaz('/cikis_test/klasor/not.sbn2.p');
        final kok2 = await yaz('/cikis_test_kok.sbn2');
        final gizli = await yaz('/.not/meta.json');

        await NotCikisi.yerelNotlariSil();

        expect(not.existsSync(), isFalse);
        expect(gorsel.existsSync(), isFalse);
        expect(onizleme.existsSync(), isFalse);
        expect(kok2.existsSync(), isFalse);
        expect(Directory('$kok/cikis_test').existsSync(), isFalse);
        // Eşitleme kapsamı dışındaki dosyalara dokunulmaz.
        expect(gizli.existsSync(), isTrue);
        await gizli.parent.delete(recursive: true);
      },
    );
  });
}
