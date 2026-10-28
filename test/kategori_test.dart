import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/tarus/kategori.dart';
import 'package:saber/tarus/tarus_ikon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    stows.ncPassword.value = 'nes_test_token_123';
    stows.notKategorileri.value = {};
    stows.notProjeleri.value = {};
  });

  tearDown(() {
    stows.ncPassword.value = stows.ncPassword.defaultValue;
    stows.notKategorileri.value = stows.notKategorileri.defaultValue;
    stows.notProjeleri.value = stows.notProjeleri.defaultValue;
  });

  group('NotKategorisi enum & fromKod', () {
    test('kod ve etiketler doğru tanımlıdır (STANDARTLAR §9)', () {
      expect(NotKategorisi.ozel.kod, 'private');
      expect(NotKategorisi.ozel.etiket, 'Özel');

      expect(NotKategorisi.sirket.kod, 'internal');
      expect(NotKategorisi.sirket.etiket, 'Şirket İçi');

      expect(NotKategorisi.proje.kod, 'project');
      expect(NotKategorisi.proje.etiket, 'Proje');
    });

    test('fromKod: kodları doğru kategoriye dönüştürür, bilinmeyende özele döner', () {
      expect(NotKategorisi.fromKod('private'), NotKategorisi.ozel);
      expect(NotKategorisi.fromKod('ozel'), NotKategorisi.ozel);
      expect(NotKategorisi.fromKod('internal'), NotKategorisi.sirket);
      expect(NotKategorisi.fromKod('sirket'), NotKategorisi.sirket);
      expect(NotKategorisi.fromKod('project'), NotKategorisi.proje);
      expect(NotKategorisi.fromKod('proje'), NotKategorisi.proje);
      expect(NotKategorisi.fromKod(null), NotKategorisi.ozel);
      expect(NotKategorisi.fromKod('gecersiz'), NotKategorisi.ozel);
    });
  });

  group('KategoriRenkleri (STANDARTLAR §9 --kat-1..6)', () {
    test('açık tema renkleri (600 tonu)', () {
      expect(
        KategoriRenkleri.renk(NotKategorisi.ozel, isDark: false),
        const Color(0xFFEA580C), // --kat-6 turuncu
      );
      expect(
        KategoriRenkleri.renk(NotKategorisi.sirket, isDark: false),
        const Color(0xFF4F46E5), // --kat-2 çivit
      );
      expect(
        KategoriRenkleri.renk(NotKategorisi.proje, isDark: false),
        const Color(0xFF9333EA), // --kat-1 mor
      );
    });

    test('koyu tema renkleri (400 tonu)', () {
      expect(
        KategoriRenkleri.renk(NotKategorisi.ozel, isDark: true),
        const Color(0xFFFB923C), // --kat-6 açık turuncu
      );
      expect(
        KategoriRenkleri.renk(NotKategorisi.sirket, isDark: true),
        const Color(0xFF818CF8), // --kat-2 açık çivit
      );
      expect(
        KategoriRenkleri.renk(NotKategorisi.proje, isDark: true),
        const Color(0xFFC084FC), // --kat-1 açık mor
      );
    });

    test('kategoriIkonu: Lucide ikon ailesinden döner', () {
      expect(kategoriIkonu(NotKategorisi.ozel), TarusIkon.kilit);
      expect(kategoriIkonu(NotKategorisi.sirket), TarusIkon.sirket);
      expect(kategoriIkonu(NotKategorisi.proje), TarusIkon.proje);
    });
  });

  group('NotKategoriBilgisi model & etiket', () {
    test('etiket: projede proje adı varsa onu, yoksa kategori adını döner', () {
      const b1 = NotKategoriBilgisi(
        kategori: NotKategorisi.proje,
        projeAdi: 'PRJ-12 · Kadıköy Konut',
      );
      expect(b1.etiket, 'PRJ-12 · Kadıköy Konut');

      const b2 = NotKategoriBilgisi(kategori: NotKategorisi.proje);
      expect(b2.etiket, 'Proje');

      const b3 = NotKategoriBilgisi(kategori: NotKategorisi.sirket);
      expect(b3.etiket, 'Şirket İçi');

      const b4 = NotKategoriBilgisi(kategori: NotKategorisi.ozel);
      expect(b4.etiket, 'Özel');
    });

    test('JSON serileştirme ve çözme', () {
      const orijinal = NotKategoriBilgisi(
        kategori: NotKategorisi.proje,
        projeAdi: 'PRJ-45 · Metro',
        projeId: '45',
      );
      final json = orijinal.toJsonString();
      final cozulmus = NotKategoriBilgisi.fromValue(json);

      expect(cozulmus.kategori, NotKategorisi.proje);
      expect(cozulmus.projeAdi, 'PRJ-45 · Metro');
      expect(cozulmus.projeId, '45');
    });

    test('fromValue: geriye dönük düz dizgi ve null desteği', () {
      expect(NotKategoriBilgisi.fromValue(null).kategori, NotKategorisi.ozel);
      expect(NotKategoriBilgisi.fromValue('internal').kategori, NotKategorisi.sirket);
      expect(NotKategoriBilgisi.fromValue('private').kategori, NotKategorisi.ozel);

      final projeDizgi = NotKategoriBilgisi.fromValue('project:PRJ-99 · Liman');
      expect(projeDizgi.kategori, NotKategorisi.proje);
      expect(projeDizgi.projeAdi, 'PRJ-99 · Liman');
    });
  });

  group('Yol kanonikleştirme & yerel kategori saklama', () {
    test('kanonikNotYolu: başta bulunan bölü işaretlerini temizler', () {
      expect(kanonikNotYolu('/Notlar/Not1.sbn2'), 'Notlar/Not1.sbn2');
      expect(kanonikNotYolu('///Not1.sbn2'), 'Not1.sbn2');
      expect(kanonikNotYolu(r'Notlar\Not1.sbn2'), 'Notlar/Not1.sbn2');
    });

    test('notKategoriAta ve notKategorisiAl: yerel hafızaya yazar ve okur', () {
      const yol = '/Saha/Gözlem.sbn2';
      const bilgi = NotKategoriBilgisi(kategori: NotKategorisi.sirket);

      expect(notKategorisiAl(yol).kategori, NotKategorisi.ozel); // varsayılan
      notKategoriAta(yol, bilgi);

      expect(notKategorisiAl(yol).kategori, NotKategorisi.sirket);
      expect(notKategorisiAl('Saha/Gözlem.sbn2').kategori, NotKategorisi.sirket);
    });
  });

  group('kategoriDegistir & HTTP sunucu bildirimi', () {
    test('sunucuya POST /api/notes/<yol>/category gönderir', () async {
      late http.Request gidenIstek;
      final client = MockClient((req) async {
        gidenIstek = req;
        return http.Response('{"success":true}', 200);
      });

      const notYolu = '/Mimari/Plan.sbn2';
      final sonuc = await kategoriDegistir(
        notYolu: notYolu,
        kategori: NotKategorisi.proje,
        projeId: '101',
        projeAdi: 'PRJ-101 · Kule',
        notSunucusu: Uri.parse('https://not.tarus.tr'),
        belirtec: 'nes_test_token_123',
        httpClient: client,
      );

      expect(sonuc, isTrue);
      // Yerel durum güncellendi mi?
      final yerel = notKategorisiAl(notYolu);
      expect(yerel.kategori, NotKategorisi.proje);
      expect(yerel.projeAdi, 'PRJ-101 · Kule');

      // Giden HTTP isteği doğrulandı mı?
      expect(gidenIstek.url.path, '/api/notes/Mimari/Plan.sbn2/category');
      expect(gidenIstek.headers['Authorization'], 'Bearer nes_test_token_123');
      final govde = jsonDecode(gidenIstek.body) as Map<String, dynamic>;
      expect(govde['category'], 'project');
      expect(govde['projeId'], '101');
    });

    test('şirket içi kategoriye alındığında projeId göndermez', () async {
      late http.Request gidenIstek;
      final client = MockClient((req) async {
        gidenIstek = req;
        return http.Response('{"success":true}', 200);
      });

      final sonuc = await kategoriDegistir(
        notYolu: '/Duyuru.sbn2',
        kategori: NotKategorisi.sirket,
        notSunucusu: Uri.parse('https://not.tarus.tr'),
        belirtec: 'nes_test_token_123',
        httpClient: client,
      );

      expect(sonuc, isTrue);
      final yerel = notKategorisiAl('/Duyuru.sbn2');
      expect(yerel.kategori, NotKategorisi.sirket);

      final govde = jsonDecode(gidenIstek.body) as Map<String, dynamic>;
      expect(govde['category'], 'internal');
      expect(govde.containsKey('projeId'), isFalse);
    });

    test('Pusula proje bağı kategoriyi Proje yapar, başka kategori bağı kaldırır', () async {
      stows.notProjeleri.value = {'/Saha/Kesit': 'PRJ-7 · Liman'};
      final bagli = notKategorisiAl('/Saha/Kesit');
      expect(bagli.kategori, NotKategorisi.proje);
      expect(bagli.projeAdi, 'PRJ-7 · Liman');

      late http.Request gidenIstek;
      final client = MockClient((req) async {
        gidenIstek = req;
        return http.Response('{"success":true}', 200);
      });
      final sonuc = await kategoriDegistir(
        notYolu: '/Saha/Kesit',
        kategori: NotKategorisi.sirket,
        notSunucusu: Uri.parse('https://not.tarus.tr'),
        belirtec: 'nes_test_token_123',
        httpClient: client,
      );

      expect(sonuc, isTrue);
      expect(gidenIstek.url.path, '/api/notes/Saha/Kesit.sbn2/category');
      expect(stows.notProjeleri.value, isEmpty);
      expect(notKategorisiAl('/Saha/Kesit').kategori, NotKategorisi.sirket);
    });
  });
}
