import 'package:flutter_test/flutter_test.dart';
import 'package:saber/tarus/not_aramasi.dart';

void main() {
  group('notAramaKatla', () {
    test('Türkçe harfleri katlar', () {
      expect(notAramaKatla('IŞIK İş Çağrı'), 'isik is cagri');
      expect(notAramaKatla('ışık'), 'isik');
    });
  });

  group('notAra', () {
    const notlar = ['/Okul/Fizik ışık', '/Okul/ders', '/Gündem', '/fiziksel'];
    const klasorler = ['/Okul', '/Fizik'];

    List<String> ara(String q) => [
      for (final s in notAra(notlar: notlar, klasorler: klasorler, sorgu: q))
        '${s.tur.name}:${s.yol}',
    ];

    test('boş sorgu sonuç vermez', () {
      expect(ara('  '), isEmpty);
    });

    test('«isik» «ışık»ı bulur', () {
      expect(ara('isik'), ['not:/Okul/Fizik ışık']);
    });

    test('klasör yolunda ve ad sırasıyla eşleşir', () {
      // «okul» adı: klasör /Okul; notlar yalnız klasör yolu eşleştiği için gelir.
      expect(ara('okul'), [
        'klasor:/Okul',
        'not:/Okul/ders',
        'not:/Okul/Fizik ışık',
      ]);
    });

    test('adı sorguyla başlayan önce gelir', () {
      expect(ara('fizik'), [
        'klasor:/Fizik',
        'not:/Okul/Fizik ışık',
        'not:/fiziksel',
      ]);
    });

    test('tüm sözcükler geçmeli', () {
      expect(ara('okul isik'), ['not:/Okul/Fizik ışık']);
      expect(ara('okul gundem'), isEmpty);
    });

    test('«Gündem» «gundem» ile bulunur', () {
      expect(ara('gundem'), ['not:/Gündem']);
    });
  });
}
