import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/nextcloud/hata_bildir.dart';
import 'package:saber/data/prefs.dart';

/// not-mobil Hata bildir: Not sunucusunun `/mobil/hata-bildir` ucu
/// (not deposu `server/app.js`) eşitleme belirteciyle çağrılır.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(FlavorConfig.setup);
  setUp(() {
    stows.url.value = 'https://not.ornek.test/';
    stows.username.value = 'pusula';
    stows.ncPassword.value = 'nes_deneme_belirteci_12345678901234';
  });
  tearDown(() {
    stows.url.value = stows.url.defaultValue;
    stows.username.value = stows.username.defaultValue;
    stows.ncPassword.value = stows.ncPassword.defaultValue;
  });

  test('eşitleme belirteciyle Not sunucusuna gönderir', () async {
    late http.Request istek;
    final client = MockClient((r) async {
      istek = r;
      return http.Response('{"durum":"iletildi"}', 201);
    });
    await HataBildir.gonder(
      baslik: ' Kalem çizmiyor ',
      aciklama: 'İz yok',
      modul: 'Ayarlar',
      goruntu: Uint8List.fromList([1, 2, 3]),
      httpClient: client,
    );
    expect(istek.method, 'POST');
    expect(istek.url.toString(), 'https://not.ornek.test/mobil/hata-bildir');
    expect(
      istek.headers['Authorization'],
      'Basic ${base64Encode(utf8.encode('pusula:nes_deneme_belirteci_12345678901234'))}',
    );
    final govde = jsonDecode(istek.body) as Map<String, dynamic>;
    expect(govde['title'], 'Kalem çizmiyor');
    expect(govde['module'], 'Ayarlar');
    expect(govde['screenshot'], 'data:image/png;base64,AQID');
    expect((govde['meta'] as Map)['appVersion'], isNotEmpty);
  });

  test('sunucunun hata ayrıntısını iletir', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"detail":"Eşitleme belirteci geçersiz ya da iptal edilmiş"}',
        401,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await expectLater(
      () => HataBildir.gonder(baslik: 'a', aciklama: 'b', httpClient: client),
      throwsA(
        isA<HataBildirHatasi>().having(
          (e) => e.mesaj,
          'mesaj',
          contains('iptal'),
        ),
      ),
    );
  });

  test('bağlı değilken ve büyük görüntüde göndermez', () async {
    final client = MockClient((_) async => fail('istek gitmemeli'));
    await expectLater(
      () => HataBildir.gonder(
        baslik: 'a',
        aciklama: 'b',
        goruntu: Uint8List(HataBildir.enBuyukGoruntu + 1),
        httpClient: client,
      ),
      throwsA(isA<HataBildirHatasi>()),
    );
    stows.ncPassword.value = '';
    await expectLater(
      () => HataBildir.gonder(baslik: 'a', aciklama: 'b', httpClient: client),
      throwsA(isA<HataBildirHatasi>()),
    );
  });
}
