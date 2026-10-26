/// Not araması (web `lib/notAramasi.ts` + `notGenelAramasi.ts` eşi).
///
/// Not içeriği el yazısı olduğu için arama not adında ve klasör yolunda yapılır.
/// Eşleşme Türkçe katlamalıdır («isik» → «Işık»); sıra: adı sorguyla başlayan,
/// adında bir sözcüğü sorguyla başlayan, yalnız içinde geçen (eşitlikte ada göre).
/// Saf modül: dosya sistemine dokunmaz (`test/not_aramasi_test.dart`).
library;

/// Türkçe harfleri katlayıp küçültür: `İ`/`I`/`ı` → `i`, `Ş` → `s`, `Ğ` → `g` …
String notAramaKatla(String metin) {
  final sb = StringBuffer();
  for (final r in metin.runes) {
    final c = String.fromCharCode(r);
    sb.write(switch (c) {
      'İ' || 'I' || 'ı' || 'i' => 'i',
      'Ş' || 'ş' => 's',
      'Ğ' || 'ğ' => 'g',
      'Ü' || 'ü' => 'u',
      'Ö' || 'ö' => 'o',
      'Ç' || 'ç' => 'c',
      _ => c.toLowerCase(),
    });
  }
  return sb.toString();
}

enum NotAramaTuru { not, klasor }

class NotAramaSonucu {
  const new(this.tur, this.yol);

  final NotAramaTuru tur;

  /// Kökten yol: not için `/Okul/ders` (uzantısız), klasör için `/Okul`.
  final String yol;

  String get ad => yol.substring(yol.lastIndexOf('/') + 1);

  /// Üst klasör yolu; kökteyse `/`.
  String get ustKlasor {
    final i = yol.lastIndexOf('/');
    return i <= 0 ? '/' : yol.substring(0, i);
  }

  @override
  bool operator ==(Object other) =>
      other is NotAramaSonucu && other.tur == tur && other.yol == yol;

  @override
  int get hashCode => Object.hash(tur, yol);
}

int _sira(String ad, String sorgu) {
  if (ad.startsWith(sorgu)) return 0;
  if (ad.split(RegExp(r'[\s_\-./]+')).any((s) => s.startsWith(sorgu))) return 1;
  return 2;
}

/// [notlar] kökten uzantısız not yolları, [klasorler] kökten klasör yolları.
/// Sorgudaki her sözcük not adında ya da klasör yolunda geçmelidir; klasör
/// sonuçları yalnız klasör adında aranır. Boş sorgu boş liste verir.
List<NotAramaSonucu> notAra({
  required Iterable<String> notlar,
  required Iterable<String> klasorler,
  required String sorgu,
}) {
  final sozcukler = notAramaKatla(sorgu)
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .toList();
  if (sozcukler.isEmpty) return const [];

  final bulunan = <(int, String, NotAramaSonucu)>[];

  for (final yol in notlar) {
    final s = NotAramaSonucu(NotAramaTuru.not, yol);
    final ad = notAramaKatla(s.ad);
    final tum = notAramaKatla(yol);
    if (sozcukler.every(tum.contains)) {
      bulunan.add((_sira(ad, sozcukler.first), ad, s));
    }
  }
  for (final yol in klasorler) {
    final s = NotAramaSonucu(NotAramaTuru.klasor, yol);
    final ad = notAramaKatla(s.ad);
    if (sozcukler.every(ad.contains)) {
      bulunan.add((_sira(ad, sozcukler.first), ad, s));
    }
  }

  bulunan.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    if (c != 0) return c;
    // Klasörler notlardan önce, sonra ada göre.
    if (a.$3.tur != b.$3.tur) return a.$3.tur == NotAramaTuru.klasor ? -1 : 1;
    return a.$2.compareTo(b.$2);
  });
  return [for (final b in bulunan) b.$3];
}
