import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:saber/data/nextcloud/pusula_belirteci.dart';

/// tarus Not sunucusunun `/ocs/v2.php/cloud/user` yanıtının birebir kopyası
/// (not deposu `server/webdav.js`). Nextcloud istemcisinin bu yanıtı
/// çözebildiği burada sınanır.
Map<String, dynamic> _notKullanicisi(String id) => {
  'ocs': {
    'meta': {'status': 'ok', 'statuscode': 200, 'message': 'OK'},
    'data': {
      'enabled': true,
      'storageLocation': '',
      'id': id,
      'firstLoginTimestamp': 0,
      'lastLoginTimestamp': 0,
      'lastLogin': 0,
      'backend': 'Pusula',
      'subadmin': <String>[],
      'quota': {'free': -3, 'used': 0, 'total': -3, 'relative': 0, 'quota': -3},
      'manager': '',
      'email': 'ayse@firma.com',
      'additional_mail': <String>[],
      'displayname': 'Ayşe',
      'display-name': 'Ayşe',
      'phone': '',
      'address': '',
      'website': '',
      'twitter': '',
      'fediverse': '',
      'organisation': 'Firma',
      'role': '',
      'headline': '',
      'biography': '',
      'profile_enabled': '0',
      'pronouns': '',
      'groups': <String>[],
      'language': 'tr',
      'locale': 'tr_TR',
      'notify_email': null,
      'backendCapabilities': {'setDisplayName': false, 'setPassword': false},
    },
  },
};

void main() {
  group('PusulaBelirteci biçimi', () {
    test('nes_ önekli ve yeterince uzun belirteç geçerli', () {
      expect(PusulaBelirteci.gecerliMi('nes_${'a' * 43}'), isTrue);
      expect(PusulaBelirteci.gecerliMi('  nes_${'a' * 43}\n'), isTrue);
      expect(PusulaBelirteci.gecerliMi('nes_kisa'), isFalse);
      expect(PusulaBelirteci.gecerliMi('parola'), isFalse);
    });

    test('boşluklar temizlenir', () {
      expect(PusulaBelirteci.temizle(' nes_ab cd\n'), 'nes_abcd');
    });
  });

  group('PusulaBelirteci.dogrula (taklit Not sunucusu)', () {
    late HttpServer sunucu;
    late Uri adres;
    const belirtec = 'nes_dogru_belirtec_0123456789abcdef';
    String? gelenYetki;

    setUp(() async {
      sunucu = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      adres = Uri.parse('http://127.0.0.1:${sunucu.port}');
      sunucu.listen((istek) async {
        gelenYetki = istek.headers.value(HttpHeaders.authorizationHeader);
        // Not sunucusu ikisini de kabul eder: Bearer (uygulama parolası) ve Basic.
        final kabul = {
          'Bearer $belirtec',
          'Basic ${base64.encode(utf8.encode('${PusulaBelirteci.kullaniciAdiYeri}:$belirtec'))}',
        };
        if (istek.uri.path.endsWith('/cloud/user') &&
            kabul.contains(gelenYetki)) {
          istek.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(_notKullanicisi('11')));
        } else {
          istek.response.statusCode = HttpStatus.unauthorized;
        }
        await istek.response.close();
      });
    });

    tearDown(() => sunucu.close(force: true));

    test('geçerli belirteç Not kullanıcı kimliğini verir', () async {
      final id = await PusulaBelirteci.dogrula(
        sunucu: adres,
        belirtec: ' $belirtec ',
      );
      printOnFailure('yetki: $gelenYetki');
      expect(id, '11');
      expect(
        gelenYetki,
        'Bearer $belirtec',
        reason: 'belirteç boşluksuz gider',
      );
    });

    test('iptal edilmiş belirteç 401 hatası verir', () async {
      await expectLater(
        PusulaBelirteci.dogrula(
          sunucu: adres,
          belirtec: 'nes_iptal_edilmis_000000000000',
        ),
        throwsA(
          isA<DynamiteStatusCodeException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });
  });
}
