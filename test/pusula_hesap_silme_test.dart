import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saber/data/nextcloud/pusula_hesap_silme.dart';

/// Uygulama içi hesap silme (App Store 5.1.1(v)): Pusula'nın
/// `/auth/me/hesabi-sil/` ucuyla konuşma.
void main() {
  final pusula = Uri.parse('https://pusula.test');
  final istekler = <http.Request>[];

  http.Response yanit(int kod, Object veri) => http.Response(
    jsonEncode(veri),
    kod,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  MockClient sunucu({bool ikiAdim = false, int silmeKodu = 200}) =>
      MockClient((istek) async {
        istekler.add(istek);
        switch ((istek.method, istek.url.path)) {
          case ('POST', '/auth/giris/'):
            final govde = jsonDecode(istek.body) as Map<String, dynamic>;
            if (govde['password'] == 'yanlis') {
              return yanit(401, {'detail': 'E-posta ya da parola hatalı.'});
            }
            if (ikiAdim && govde['challenge_token'] == null) {
              return yanit(202, {
                'code': 'two_factor_required',
                'challenge_token': 'ch1',
              });
            }
            return yanit(200, {'access': 'jwt', 'refresh': 'yenile'});
          case ('GET', '/auth/me/hesabi-sil/'):
            return yanit(200, {
              'hesap': 'test@tarus.tr',
              'parolasiz': false,
              'engel': null,
              'silinecek_profil': ['Ad, soyad, e-posta'],
              'silinecek': [
                {'ad': 'Not eşitleme belirteçleri', 'sayi': 2},
              ],
              'korunan': ['Projeler'],
              'uyari': '',
            });
          case ('POST', '/auth/me/hesabi-sil/'):
            return silmeKodu == 200
                ? yanit(200, {'detail': 'Hesabınız silindi.'})
                : yanit(silmeKodu, {'detail': 'Şirketin tek yöneticisisiniz.'});
        }
        return http.Response('', 404);
      });

  setUp(istekler.clear);

  test('giriş, plan ve silme sırası', () async {
    final istemci = sunucu();
    final giris = await PusulaHesapSilme.girisYap(
      eposta: ' test@tarus.tr ',
      parola: 'sifre',
      pusula: pusula,
      httpClient: istemci,
    );
    expect(giris, isA<HesapSilmeOturumu>());
    final oturum = giris as HesapSilmeOturumu;

    final plan = await PusulaHesapSilme.plan(
      oturum,
      pusula: pusula,
      httpClient: istemci,
    );
    expect(plan.hesap, 'test@tarus.tr');
    expect(plan.engel, isNull);
    expect(plan.silinecek, contains('Not eşitleme belirteçleri (2)'));
    expect(plan.korunan, ['Projeler']);

    await PusulaHesapSilme.sil(
      oturum,
      parola: 'sifre',
      pusula: pusula,
      httpClient: istemci,
    );
    final silme = istekler.last;
    expect(silme.method, 'POST');
    expect(silme.headers['Authorization'], 'Bearer jwt');
    expect(jsonDecode(silme.body), {'password': 'sifre'});
    expect(
      jsonDecode(istekler.first.body),
      containsPair('email', 'test@tarus.tr'),
    );
  });

  test('iki adımlı doğrulama kodu istenir', () async {
    final istemci = sunucu(ikiAdim: true);
    final giris = await PusulaHesapSilme.girisYap(
      eposta: 'a@b.c',
      parola: 'sifre',
      pusula: pusula,
      httpClient: istemci,
    );
    expect(giris, isA<HesapSilmeIkiAdim>());
    final tamam = await PusulaHesapSilme.ikiAdimiTamamla(
      challenge: (giris as HesapSilmeIkiAdim).challenge,
      kod: '123456',
      pusula: pusula,
      httpClient: istemci,
    );
    expect(tamam, isA<HesapSilmeOturumu>());
  });

  test('yanlış parola ve engel iletisi kullanıcıya iletilir', () async {
    final istemci = sunucu(silmeKodu: 409);
    await expectLater(
      PusulaHesapSilme.girisYap(
        eposta: 'a@b.c',
        parola: 'yanlis',
        pusula: pusula,
        httpClient: istemci,
      ),
      throwsA(
        isA<HesapSilmeHatasi>().having(
          (e) => e.mesaj,
          'mesaj',
          contains('parola hatalı'),
        ),
      ),
    );
    await expectLater(
      PusulaHesapSilme.sil(
        const HesapSilmeOturumu('jwt', null),
        parola: 'sifre',
        pusula: pusula,
        httpClient: istemci,
      ),
      throwsA(
        isA<HesapSilmeHatasi>().having(
          (e) => e.mesaj,
          'mesaj',
          contains('tek yöneticisisiniz'),
        ),
      ),
    );
  });
}
