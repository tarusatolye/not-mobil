import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tarus_baglantilar.dart';

/// Pusula projesi (eskiz bağlama ve projeden açma için).
///
/// Web (`not/src/lib/projeler.ts`) ile tam uyumlu model ve fonksiyonlar.
class PusulaProjesi {
  final String id;
  final String? refNo;
  final String? ad;

  const PusulaProjesi({
    required this.id,
    this.refNo,
    this.ad,
  });

  factory PusulaProjesi.fromJson(Map<String, dynamic> json) {
    return PusulaProjesi(
      id: json['id']?.toString() ?? '',
      refNo: (json['ref_no'] ?? json['code'])?.toString(),
      ad: (json['ad'] ?? json['title'] ?? json['name'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (refNo != null) 'ref_no': refNo,
    if (ad != null) 'ad': ad,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PusulaProjesi &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => projeEtiketi(this);
}

/// Seçicilerde gösterilen etiket: "PRJ-12 · Proje adı" (uzun tire yok, STANDARTLAR §10 Tire Kullanımı).
String projeEtiketi(PusulaProjesi p) {
  final kod = p.refNo?.trim();
  final baslik = p.ad?.trim();
  if (kod != null && kod.isNotEmpty) {
    return baslik != null && baslik.isNotEmpty ? '$kod · $baslik' : kod;
  }
  return baslik != null && baslik.isNotEmpty ? baslik : p.id;
}

/// 2.0.3'e kadar kaydedilen etiket biçimi ("PRJ-12 — Proje adı"); eski kayıtlar eşleşsin diye.
String? eskiEtiket(PusulaProjesi p) {
  final kod = p.refNo?.trim();
  final baslik = p.ad?.trim();
  if (kod != null && kod.isNotEmpty) {
    return baslik != null && baslik.isNotEmpty ? '$kod \u2014 $baslik' : null;
  }
  return null;
}

/// Kayıtlı proje adını (etiket, ad ya da kod) seçicideki etikete çevirir.
String seciliProjeEtiketi(List<PusulaProjesi> projeler, String? kayitli) {
  if (kayitli == null || kayitli.trim().isEmpty) return '';
  final aranan = kayitli.trim();
  for (final p in projeler) {
    if (aranan == p.ad ||
        aranan == p.refNo ||
        aranan == p.id ||
        aranan == projeEtiketi(p) ||
        aranan == eskiEtiket(p)) {
      return projeEtiketi(p);
    }
  }
  return aranan;
}

/// Proje seçeneği (değer ve etiket çifti).
class ProjeSecenegi {
  final String value;
  final String label;

  const ProjeSecenegi({required this.value, required this.label});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjeSecenegi &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => label;
}

/// Proje seçici seçenekleri; listede olmayan kayıtlı değer de korunur.
List<ProjeSecenegi> projeSecenekleri(
  List<PusulaProjesi> projeler,
  String? kayitli,
) {
  final secenekler = projeler
      .map(
        (p) => ProjeSecenegi(value: projeEtiketi(p), label: projeEtiketi(p)),
      )
      .toList();
  final secili = seciliProjeEtiketi(projeler, kayitli);
  if (secili.isNotEmpty && !secenekler.any((s) => s.value == secili)) {
    secenekler.add(ProjeSecenegi(value: secili, label: secili));
  }
  return secenekler;
}

/// İki proje listesini kimliğe göre birleştirir (önceki sıra korunur, yeniler sona eklenir).
List<PusulaProjesi> projeleriBirlestir(
  List<PusulaProjesi> eski,
  List<PusulaProjesi> yeni,
) {
  final kimlikler = eski.map((p) => p.id).toSet();
  return [...eski, ...yeni.where((p) => !kimlikler.contains(p.id))];
}

/// Seçicinin verdiği etiketten Pusula proje kimliğini bulur.
Future<String?> projeIdBul(
  String? etiket, {
  Future<List<PusulaProjesi>> Function(String arama)? arayici,
  List<PusulaProjesi>? mevcutProjeler,
}) async {
  if (etiket == null || etiket.trim().isEmpty) return null;
  final temiz = etiket.trim();
  final parcalar = temiz.split(RegExp(r' · | — '));
  final kod = parcalar[0].trim();

  // Önce mevcut listede ara
  if (mevcutProjeler != null) {
    for (final p in mevcutProjeler) {
      if (projeEtiketi(p) == temiz ||
          eskiEtiket(p) == temiz ||
          p.ad == temiz ||
          p.refNo == temiz ||
          p.id == temiz) {
        return p.id;
      }
    }
  }

  if (arayici != null) {
    final aranan = await arayici(kod.isNotEmpty ? kod : temiz);
    final projeler = aranan.isNotEmpty ? aranan : await arayici('');
    for (final p in projeler) {
      if (projeEtiketi(p) == temiz ||
          eskiEtiket(p) == temiz ||
          p.ad == temiz ||
          p.refNo == temiz ||
          p.id == temiz) {
        return p.id;
      }
    }
  }

  return null;
}

/// Pusula proje eskizi: Pusula proje sayfasından gelen eskiz yolu.
///
/// Adres kalıbı: `/proje/<projeId>/<sahip>/<yol>`
class ProjeEskizi {
  final String projeId;
  final String sahip;
  final String yol;

  const ProjeEskizi({
    required this.projeId,
    required this.sahip,
    required this.yol,
  });

  /// URL ya da URI'den proje eskizini çözer.
  /// Örnekler:
  /// - `/proje/42/emre/Saha%20Notu.sbn2`
  /// - `https://not.tarus.tr/proje/42/emre/Saha/Not.sbn2`
  /// - `tarus-not://proje/42/emre/Saha%20Notu.sbn2`
  static ProjeEskizi? urlCoz(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    // Segmentler: 'proje', '<projeId>', '<sahip>', ...<yol>
    int projeIndex = segments.indexOf('proje');
    if (projeIndex < 0 && uri.host == 'proje') {
      // tarus-not://proje/<projeId>/<sahip>/<yol>
      if (segments.length < 3) return null;
      final projeId = Uri.decodeComponent(segments[0]);
      final sahip = Uri.decodeComponent(segments[1]);
      final yol = segments.sublist(2).map(Uri.decodeComponent).join('/');
      if (projeId.isEmpty || sahip.isEmpty || yol.isEmpty) return null;
      return ProjeEskizi(projeId: projeId, sahip: sahip, yol: yol);
    }
    if (projeIndex < 0 || segments.length < projeIndex + 4) return null;

    final projeId = Uri.decodeComponent(segments[projeIndex + 1]);
    final sahip = Uri.decodeComponent(segments[projeIndex + 2]);
    final yol = segments
        .sublist(projeIndex + 3)
        .map(Uri.decodeComponent)
        .join('/');

    if (projeId.isEmpty || sahip.isEmpty || yol.isEmpty) return null;
    return ProjeEskizi(projeId: projeId, sahip: sahip, yol: yol);
  }

  /// Metin adresten çözer.
  static ProjeEskizi? adresCoz(String adres) {
    try {
      final uri = Uri.parse(adres);
      return urlCoz(uri);
    } catch (_) {
      return null;
    }
  }

  String get kanonikYol => '/proje/$projeId/$sahip/$yol';
  Uri get webUrl =>
      Uri.parse('https://not.tarus.tr/proje/$projeId/$sahip/$yol');
  Uri get deepLink => Uri.parse('tarus-not://proje/$projeId/$sahip/$yol');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjeEskizi &&
          runtimeType == other.runtimeType &&
          projeId == other.projeId &&
          sahip == other.sahip &&
          yol == other.yol;

  @override
  int get hashCode => Object.hash(projeId, sahip, yol);
}

/// Kullanıcının görebildiği Pusula projelerini çeker.
///
/// Ağ isteği başarısız olursa boş liste döner.
Future<List<PusulaProjesi>> fetchPusulaProjects({
  String arama = '',
  Uri? pusula,
  String? belirtec,
  http.Client? httpClient,
}) async {
  final kok = pusula ?? TarusBaglantilar.pusulaApi;
  final token = belirtec ?? stows.ncPassword.value;
  if (token.isEmpty) return [];

  final client = httpClient ?? NextcloudClientExtension.newHttpClient();
  try {
    final query =
        arama.isNotEmpty ? '?q=${Uri.encodeQueryComponent(arama)}' : '';
    final url = kok.resolve('not/projeler/$query');
    final resp = await client
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) return [];
    final dynamic data = jsonDecode(utf8.decode(resp.bodyBytes));
    final List<dynamic> list = data is List
        ? data
        : (data is Map && data['results'] is List
            ? data['results'] as List
            : []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(PusulaProjesi.fromJson)
        .toList();
  } catch (_) {
    return [];
  } finally {
    if (httpClient == null) client.close();
  }
}

/// Notu Pusula projesine bağlar ve yerel kaydı günceller.
Future<bool> projeBagla({
  required String notYolu,
  required String projeId,
  PusulaProjesi? proje,
  Uri? notSunucusu,
  String? belirtec,
  http.Client? httpClient,
}) async {
  final temizYol = notYolu.startsWith('/') ? notYolu.substring(1) : notYolu;
  final etiket = proje != null ? projeEtiketi(proje) : projeId;

  // Yerel tercihi güncelle
  final guncel = Map<String, String>.from(stows.notProjeleri.value);
  guncel[notYolu] = etiket;
  if (notYolu != temizYol) guncel[temizYol] = etiket;
  stows.notProjeleri.value = guncel;

  // Çevrimdışıysa yerel kayıt yeterlidir
  final token = belirtec ?? stows.ncPassword.value;
  if (token.isEmpty) return true;

  final sunucu = notSunucusu ?? NextcloudClientExtension.defaultNextcloudUri;
  final client = httpClient ?? NextcloudClientExtension.newHttpClient();
  try {
    final url = sunucu.resolve(
      'api/notes/${sunucuNotAdi(temizYol)}/category',
    );
    final resp = await client
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'category': 'project', 'projeId': projeId}),
        )
        .timeout(const Duration(seconds: 10));
    return resp.statusCode == 200;
  } catch (_) {
    return true; // Yerel kayıt başarılı olduğu için sessizce geçer
  } finally {
    if (httpClient == null) client.close();
  }
}

/// Notun Pusula projesi bağını kaldırır.
Future<bool> projeBagiKaldir({
  required String notYolu,
  Uri? notSunucusu,
  String? belirtec,
  http.Client? httpClient,
}) async {
  final temizYol = notYolu.startsWith('/') ? notYolu.substring(1) : notYolu;

  // Yerel tercihten çıkar
  final guncel = Map<String, String>.from(stows.notProjeleri.value);
  guncel.remove(notYolu);
  guncel.remove(temizYol);
  stows.notProjeleri.value = guncel;

  final token = belirtec ?? stows.ncPassword.value;
  if (token.isEmpty) return true;

  final sunucu = notSunucusu ?? NextcloudClientExtension.defaultNextcloudUri;
  final client = httpClient ?? NextcloudClientExtension.newHttpClient();
  try {
    final url = sunucu.resolve(
      'api/notes/${sunucuNotAdi(temizYol)}/category',
    );
    final resp = await client
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'category': 'private'}),
        )
        .timeout(const Duration(seconds: 10));
    return resp.statusCode == 200;
  } catch (_) {
    return true;
  } finally {
    if (httpClient == null) client.close();
  }
}

/// Not sunucusundaki dosya adı (`/api/notes/<ad>/...` için, parça parça kodlu).
///
/// Uygulamadaki not yolları uzantısızdır (`/Saha/Gözlem`); sunucu meta
/// kaydını dosya adıyla (`Saha/Gözlem.sbn2`) tutar.
String sunucuNotAdi(String notYolu) {
  var ad = notYolu.startsWith('/') ? notYolu.substring(1) : notYolu;
  if (!ad.endsWith('.sbn2') && !ad.endsWith('.sbn')) ad = '$ad.sbn2';
  return ad.split('/').map(Uri.encodeComponent).join('/');
}

/// Pusula eskiz bağlantısındaki yolu düzenleyicinin uzantısız not yoluna çevirir.
String eskizNotYolu(String yol) {
  final temiz = yol.replaceFirst(RegExp(r'\.sbn2?$'), '');
  return temiz.startsWith('/') ? temiz : '/$temiz';
}

/// Notun bağlı olduğu Pusula projesinin etiketini döner (yoksa null).
String? notunProjesi(String notYolu) {
  final harita = stows.notProjeleri.value;
  if (harita.containsKey(notYolu)) return harita[notYolu];
  final temiz = notYolu.startsWith('/') ? notYolu.substring(1) : notYolu;
  if (harita.containsKey(temiz)) return harita[temiz];
  final baslikli = '/$temiz';
  return harita[baslikli];
}
