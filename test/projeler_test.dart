import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/tarus/projeler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    stows.ncPassword.value = 'nes_test_token_123';
    stows.notProjeleri.value = {};
  });

  tearDown(() {
    stows.ncPassword.value = stows.ncPassword.defaultValue;
    stows.notProjeleri.value = stows.notProjeleri.defaultValue;
  });

  group('PusulaProjesi & etiketleme', () {
    test('projeEtiketi: refNo ve ad varsa orta nokta ile birleştirir (STANDARTLAR §10)', () {
      const p = PusulaProjesi(id: '1', refNo: 'PRJ-12', ad: 'Kadıköy Konut');
      expect(projeEtiketi(p), 'PRJ-12 · Kadıköy Konut');
    });

    test('projeEtiketi: refNo yoksa yalnız adı döner', () {
      const p = PusulaProjesi(id: '2', ad: 'Şirket İçi Ar-Ge');
      expect(projeEtiketi(p), 'Şirket İçi Ar-Ge');
    });

    test('projeEtiketi: ad yoksa refNo döner', () {
      const p = PusulaProjesi(id: '3', refNo: 'PRJ-99');
      expect(projeEtiketi(p), 'PRJ-99');
    });

    test('projeEtiketi: ad ve refNo yoksa id döner', () {
      const p = PusulaProjesi(id: '105');
      expect(projeEtiketi(p), '105');
    });

    test('eskiEtiket: uzun tireli eski biçim ("PRJ-12 — Ad")', () {
      const p = PusulaProjesi(id: '1', refNo: 'PRJ-12', ad: 'Kadıköy');
      expect(eskiEtiket(p), 'PRJ-12 \u2014 Kadıköy');
    });

    test('seciliProjeEtiketi: eski uzun tireli etiketi güncel orta noktalı etikete çevirir', () {
      const projeler = [
        PusulaProjesi(id: '1', refNo: 'PRJ-12', ad: 'Kadıköy Konut'),
        PusulaProjesi(id: '2', refNo: 'PRJ-15', ad: 'Beşiktaş Ofis'),
      ];
      expect(
        seciliProjeEtiketi(projeler, 'PRJ-12 \u2014 Kadıköy Konut'),
        'PRJ-12 · Kadıköy Konut',
      );
      expect(
        seciliProjeEtiketi(projeler, 'PRJ-15 · Beşiktaş Ofis'),
        'PRJ-15 · Beşiktaş Ofis',
      );
      expect(seciliProjeEtiketi(projeler, 'Kadıköy Konut'), 'PRJ-12 · Kadıköy Konut');
      expect(seciliProjeEtiketi(projeler, 'PRJ-12'), 'PRJ-12 · Kadıköy Konut');
      expect(seciliProjeEtiketi(projeler, 'Bilinmeyen Proje'), 'Bilinmeyen Proje');
      expect(seciliProjeEtiketi(projeler, ''), '');
      expect(seciliProjeEtiketi(projeler, null), '');
    });

    test('projeSecenekleri: listede olmayan kayıtlı değeri de korur', () {
      const projeler = [
        PusulaProjesi(id: '1', refNo: 'PRJ-1', ad: 'Proje Bir'),
      ];
      final secenekler = projeSecenekleri(projeler, 'Eski Arşiv Projesi');
      expect(secenekler.length, 2);
      expect(secenekler[0].value, 'PRJ-1 · Proje Bir');
      expect(secenekler[1].value, 'Eski Arşiv Projesi');
    });

    test('projeleriBirlestir: mükerrer kimlikleri eler, önceki sırayı korur', () {
      const eski = [
        PusulaProjesi(id: '1', refNo: 'PRJ-1', ad: 'Bir'),
        PusulaProjesi(id: '2', refNo: 'PRJ-2', ad: 'İki'),
      ];
      const yeni = [
        PusulaProjesi(id: '2', refNo: 'PRJ-2-yeni', ad: 'İki Güncel'),
        PusulaProjesi(id: '3', refNo: 'PRJ-3', ad: 'Üç'),
      ];
      final birlesik = projeleriBirlestir(eski, yeni);
      expect(birlesik.length, 3);
      expect(birlesik.map((p) => p.id).toList(), ['1', '2', '3']);
      expect(birlesik[1].ad, 'İki'); // Eski sıradaki korunur
    });
  });

  group('projeIdBul', () {
    const projeler = [
      PusulaProjesi(id: 'uuid-1', refNo: 'PRJ-10', ad: 'Fabrika'),
      PusulaProjesi(id: 'uuid-2', refNo: 'PRJ-20', ad: 'Depo'),
    ];

    test('mevcut listede etiket veya kodla kimliği bulur', () async {
      expect(
        await projeIdBul('PRJ-10 · Fabrika', mevcutProjeler: projeler),
        'uuid-1',
      );
      expect(
        await projeIdBul('PRJ-20 \u2014 Depo', mevcutProjeler: projeler),
        'uuid-2',
      );
      expect(await projeIdBul('PRJ-10', mevcutProjeler: projeler), 'uuid-1');
      expect(await projeIdBul('Depo', mevcutProjeler: projeler), 'uuid-2');
      expect(await projeIdBul('', mevcutProjeler: projeler), isNull);
      expect(await projeIdBul(null, mevcutProjeler: projeler), isNull);
    });

    test('özel arayıcı fonksiyonla sunucuda arar', () async {
      final id = await projeIdBul(
        'PRJ-99 · Liman',
        arayici: (q) async {
          if (q == 'PRJ-99' || q == 'PRJ-99 · Liman') {
            return [const PusulaProjesi(id: 'uuid-99', refNo: 'PRJ-99', ad: 'Liman')];
          }
          return [];
        },
      );
      expect(id, 'uuid-99');
    });
  });

  group('ProjeEskizi derin bağlantı ve url çözme', () {
    test('web adresini çözer: https://not.tarus.tr/proje/<projeId>/<sahip>/<yol>', () {
      final eskiz = ProjeEskizi.adresCoz(
        'https://not.tarus.tr/proje/42/emre.yildirim/Santiye%20Eskizi.sbn2',
      );
      expect(eskiz, isNotNull);
      expect(eskiz!.projeId, '42');
      expect(eskiz.sahip, 'emre.yildirim');
      expect(eskiz.yol, 'Santiye Eskizi.sbn2');
      expect(eskiz.kanonikYol, '/proje/42/emre.yildirim/Santiye Eskizi.sbn2');
    });

    test('özel şema adresini çözer: tarus-not://proje/<projeId>/<sahip>/<yol>', () {
      final eskiz = ProjeEskizi.adresCoz(
        'tarus-not://proje/101/ahmet/Toplanti/Eskiz.sbn2',
      );
      expect(eskiz, isNotNull);
      expect(eskiz!.projeId, '101');
      expect(eskiz.sahip, 'ahmet');
      expect(eskiz.yol, 'Toplanti/Eskiz.sbn2');
    });

    test('göreli web yolunu çözer: /proje/5/mehmet/Not.sbn2', () {
      final eskiz = ProjeEskizi.adresCoz('/proje/5/mehmet/Not.sbn2');
      expect(eskiz, isNotNull);
      expect(eskiz!.projeId, '5');
      expect(eskiz.sahip, 'mehmet');
      expect(eskiz.yol, 'Not.sbn2');
    });

    test('eskiz yolu düzenleyicinin uzantısız not yoluna çevrilir', () {
      expect(eskizNotYolu('Toplanti/Eskiz.sbn2'), '/Toplanti/Eskiz');
      expect(eskizNotYolu('Eski.sbn'), '/Eski');
      expect(eskizNotYolu('/Not'), '/Not');
    });

    test('sunucu not adı uzantılı ve parça parça kodlanır', () {
      expect(sunucuNotAdi('/Saha/Gözlem'), 'Saha/G%C3%B6zlem.sbn2');
      expect(sunucuNotAdi('Saha/Gözlem.sbn2'), 'Saha/G%C3%B6zlem.sbn2');
    });

    test('geçersiz adreslerde null döner', () {
      expect(ProjeEskizi.adresCoz('https://not.tarus.tr/hizli-bakis'), isNull);
      expect(ProjeEskizi.adresCoz('/proje/5/mehmet'), isNull); // yol eksik
      expect(ProjeEskizi.adresCoz(''), isNull);
    });
  });

  group('fetchPusulaProjects & projeBagla', () {
    test('fetchPusulaProjects: Pusula API listesini çeker', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/not/projeler/');
        expect(req.headers['Authorization'], 'Bearer nes_test_token_123');
        return http.Response(
          jsonEncode([
            {'id': '10', 'ref_no': 'PRJ-10', 'ad': 'Merkez Ofis'},
            {'id': '20', 'ref_no': 'PRJ-20', 'ad': 'Şantiye Blok A'},
          ]),
          200,
        );
      });

      final projeler = await fetchPusulaProjects(
        pusula: Uri.parse('https://pusula.tarus.tr'),
        belirtec: 'nes_test_token_123',
        httpClient: client,
      );
      expect(projeler.length, 2);
      expect(projeler[0].refNo, 'PRJ-10');
      expect(projeler[1].ad, 'Şantiye Blok A');
    });

    test('projeBagla ve notunProjesi: yerel kaydı günceller ve sunucuya bildirir', () async {
      late http.Request gidenIstek;
      final client = MockClient((req) async {
        gidenIstek = req;
        return http.Response('{"success":true}', 200);
      });

      const notYolu = '/Saha/Gözlem.sbn2';
      const proje = PusulaProjesi(id: '55', refNo: 'PRJ-55', ad: 'Metro');

      final sonuc = await projeBagla(
        notYolu: notYolu,
        projeId: '55',
        proje: proje,
        notSunucusu: Uri.parse('https://not.tarus.tr'),
        belirtec: 'nes_test_token_123',
        httpClient: client,
      );

      expect(sonuc, isTrue);
      expect(notunProjesi(notYolu), 'PRJ-55 · Metro');
      expect(notunProjesi('Saha/Gözlem.sbn2'), 'PRJ-55 · Metro');
      expect(gidenIstek.url.path, '/api/notes/Saha/G%C3%B6zlem.sbn2/category');
      final govde = jsonDecode(gidenIstek.body) as Map<String, dynamic>;
      expect(govde['category'], 'project');
      expect(govde['projeId'], '55');
    });

    test('projeBagiKaldir: yerel kaydı ve sunucuyu private kategoriye alır', () async {
      stows.notProjeleri.value = {'/Saha.sbn2': 'PRJ-1 · Ad'};
      expect(notunProjesi('/Saha.sbn2'), 'PRJ-1 · Ad');

      final client = MockClient((req) async {
        return http.Response('{"success":true}', 200);
      });

      await projeBagiKaldir(
        notYolu: '/Saha.sbn2',
        notSunucusu: Uri.parse('https://not.tarus.tr'),
        belirtec: 'nes_test_token_123',
        httpClient: client,
      );

      expect(notunProjesi('/Saha.sbn2'), isNull);
    });
  });
}
