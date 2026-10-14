import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saber/data/nextcloud/pusula_giris.dart';

/// «Pusula ile giriş»in Pusula'yla konuşması: taklit Pusula sunucusu
/// (Backend users/views.py LoginView, notlar/views.py) üzerinde sınanır.
void main() {
  late HttpServer sunucu;
  late Uri pusula;
  late List<
    (String yol, Map<String, String> basliklar, Map<String, dynamic> govde)
  >
  istekler;
  late Completer<void> cikisYapildi;
  var ikiAdimli = false;

  const belirtec = 'nes_cihaz_belirteci_0123456789abcdefghij';

  setUp(() async {
    istekler = [];
    cikisYapildi = Completer();
    ikiAdimli = false;
    sunucu = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    pusula = Uri.parse('http://127.0.0.1:${sunucu.port}');
    sunucu.listen((istek) async {
      final ham = await utf8.decodeStream(istek);
      final govde = ham.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(ham) as Map<String, dynamic>;
      final basliklar = <String, String>{};
      istek.headers.forEach(
        (ad, degerler) => basliklar[ad] = degerler.join(','),
      );
      istekler.add((istek.uri.path, basliklar, govde));

      Future<void> yanitla(int kod, [Object? veri]) async {
        istek.response.statusCode = kod;
        if (veri != null) {
          istek.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(veri));
        }
        await istek.response.close();
      }

      switch (istek.uri.path) {
        case '/auth/giris/':
          if (govde['challenge_token'] == 'meydan') {
            return govde['totp_code'] == '123456'
                ? yanitla(200, {
                    'access': 'jwt-erisim',
                    'refresh': 'jwt-yenileme',
                  })
                : yanitla(400, {'detail': 'Doğrulama kodu geçersiz.'});
          }
          if (govde['password'] != 'dogru-parola') {
            return yanitla(400, {
              'non_field_errors': ['E-posta veya şifre hatalı.'],
            });
          }
          if (ikiAdimli) {
            return yanitla(202, {
              'code': 'two_factor_required',
              'challenge_token': 'meydan',
            });
          }
          return yanitla(200, {
            'access': 'jwt-erisim',
            'refresh': 'jwt-yenileme',
            'user': {'email': 'ayse@firma.com'},
          });
        case '/not/belirtecler/':
          if (basliklar['authorization'] != 'Bearer jwt-erisim') {
            return yanitla(401, {'detail': 'Kimlik doğrulanmadı.'});
          }
          return yanitla(201, {
            'id': 'b1',
            'ad': govde['ad'],
            'onek': belirtec.substring(0, 12),
            'belirtec': belirtec,
          });
        case '/auth/cikis/':
          await yanitla(200, {'detail': 'Çıkış yapıldı.'});
          if (!cikisYapildi.isCompleted) cikisYapildi.complete();
          return;
        case '/not/belirtecler/birak/':
          return yanitla(
            basliklar['authorization'] == 'Bearer $belirtec' ? 204 : 401,
          );
      }
      return yanitla(404);
    });
  });

  tearDown(() => sunucu.close(force: true));

  test('giriş belirteç alır ve Pusula oturumunu kapatır', () async {
    final sonuc = await PusulaGiris.girisYap(
      eposta: ' ayse@firma.com ',
      parola: 'dogru-parola',
      pusula: pusula,
      cihazAdi: 'Samsung SM-X200',
    );
    expect(sonuc, isA<BelirtecAlindi>());
    expect((sonuc as BelirtecAlindi).belirtec, belirtec);
    expect(sonuc.cihazAdi, 'Samsung SM-X200');

    await cikisYapildi.future.timeout(const Duration(seconds: 5));
    final (girisYolu, girisBasliklari, girisGovdesi) = istekler[0];
    expect(girisYolu, '/auth/giris/');
    expect(girisGovdesi['email'], 'ayse@firma.com');
    expect(girisGovdesi['username'], 'ayse@firma.com');
    expect(girisBasliklari['x-client'], 'mobile');
    expect(girisBasliklari['x-tarus-app'], 'not-mobil');
    expect(girisBasliklari['x-device-name'], 'Samsung SM-X200');

    final (belirtecYolu, _, belirtecGovdesi) = istekler[1];
    expect(belirtecYolu, '/not/belirtecler/');
    expect(belirtecGovdesi['ad'], 'Samsung SM-X200');

    final cikis = istekler.firstWhere((i) => i.$1 == '/auth/cikis/');
    expect(cikis.$3['refresh_token'], 'jwt-yenileme');
  });

  test('iki adımlı hesapta kod istenir, kodla tamamlanır', () async {
    ikiAdimli = true;
    final ilk = await PusulaGiris.girisYap(
      eposta: 'ayse@firma.com',
      parola: 'dogru-parola',
      pusula: pusula,
      cihazAdi: 'iPad Air',
    );
    expect(ilk, isA<IkiAdimGerekli>());
    expect((ilk as IkiAdimGerekli).challenge, 'meydan');
    expect(istekler.map((i) => i.$1), isNot(contains('/not/belirtecler/')));

    await expectLater(
      PusulaGiris.ikiAdimiTamamla(
        challenge: 'meydan',
        kod: '000000',
        pusula: pusula,
        cihazAdi: 'iPad Air',
      ),
      throwsA(
        isA<PusulaGirisHatasi>().having(
          (e) => e.mesaj,
          'mesaj',
          'Doğrulama kodu geçersiz.',
        ),
      ),
    );

    final son = await PusulaGiris.ikiAdimiTamamla(
      challenge: 'meydan',
      kod: ' 123456 ',
      pusula: pusula,
      cihazAdi: 'iPad Air',
    );
    expect((son as BelirtecAlindi).belirtec, belirtec);
  });

  test('yanlış parolada Pusula iletisi gösterilir', () async {
    await expectLater(
      PusulaGiris.girisYap(
        eposta: 'ayse@firma.com',
        parola: 'yanlis',
        pusula: pusula,
        cihazAdi: 'Telefon',
      ),
      throwsA(
        isA<PusulaGirisHatasi>().having(
          (e) => e.mesaj,
          'mesaj',
          'E-posta veya şifre hatalı.',
        ),
      ),
    );
  });

  test('Türkçe cihaz adı başlığa sadeleşerek gider', () async {
    await PusulaGiris.girisYap(
      eposta: 'ayse@firma.com',
      parola: 'dogru-parola',
      pusula: pusula,
      cihazAdi: 'Ayşe’nin Tableti',
    );
    expect(istekler[0].$2['x-device-name'], 'Aysenin Tableti');
    expect(istekler[1].$3['ad'], 'Ayşe’nin Tableti');
  });

  test(
    'çıkışta belirteç bırakılır; nes_ olmayan parola Pusula\'ya gitmez',
    () async {
      expect(await PusulaGiris.birak(belirtec, pusula: pusula), isTrue);
      expect(istekler.single.$1, '/not/belirtecler/birak/');
      expect(istekler.single.$2['authorization'], 'Bearer $belirtec');

      expect(
        await PusulaGiris.birak('nes_bilinmeyen', pusula: pusula),
        isFalse,
      );
      expect(
        await PusulaGiris.birak('nextcloud-uygulama-parolasi', pusula: pusula),
        isFalse,
      );
      expect(istekler, hasLength(2));
    },
  );

  test('Pusula kapalıysa anlaşılır hata', () async {
    await sunucu.close(force: true);
    await expectLater(
      PusulaGiris.girisYap(
        eposta: 'ayse@firma.com',
        parola: 'dogru-parola',
        pusula: pusula,
        cihazAdi: 'Telefon',
      ),
      throwsA(isA<PusulaGirisHatasi>()),
    );
    expect(await PusulaGiris.birak(belirtec, pusula: pusula), isFalse);
  });
}
