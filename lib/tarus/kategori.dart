import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/tarus/projeler.dart';
import 'package:saber/tarus/tarus_ikon.dart';

/// tarus Not kategorileri: Web (`not-web`) ile birebir aynı üç kategori
/// (STANDARTLAR §9 «Kategorik renkler», `not-web/src/components/KategoriRozeti.tsx`).
enum NotKategorisi {
  ozel('private', 'Özel'),
  sirket('internal', 'Şirket İçi'),
  proje('project', 'Proje');

  new(this.kod, this.etiket);

  final String kod;
  final String etiket;

  static NotKategorisi fromKod(String? kod) {
    return switch (kod) {
      'internal' || 'sirket' => NotKategorisi.sirket,
      'project' || 'proje' => NotKategorisi.proje,
      _ => NotKategorisi.ozel,
    };
  }
}

/// Kategorik renkler (STANDARTLAR §9, `tarus.css` `--kat-1..6`):
/// - Özel: `--kat-6` (Turuncu)
/// - Şirket İçi: `--kat-2` (Çivit)
/// - Proje: `--kat-1` (Mor)
abstract final class KategoriRenkleri {
  // Açık tema (Modern, Adaçayı, Kahve: 600 tonu)
  static const ozelAcik = Color(0xFFEA580C);
  static const sirketAcik = Color(0xFF4F46E5);
  static const projeAcik = Color(0xFF9333EA);

  // Koyu tema (Karanlık, Okyanus, Günbatımı vb.: 400 tonu)
  static const ozelKoyu = Color(0xFFFB923C);
  static const sirketKoyu = Color(0xFF818CF8);
  static const projeKoyu = Color(0xFFC084FC);

  static Color renk(NotKategorisi kategori, {bool isDark = false}) {
    if (isDark) {
      return switch (kategori) {
        NotKategorisi.ozel => ozelKoyu,
        NotKategorisi.sirket => sirketKoyu,
        NotKategorisi.proje => projeKoyu,
      };
    }
    return switch (kategori) {
      NotKategorisi.ozel => ozelAcik,
      NotKategorisi.sirket => sirketAcik,
      NotKategorisi.proje => projeAcik,
    };
  }
}

/// Kategori ikonları: Web ile aynı Lucide sembolleri (Kilit, Şirket, Proje).
IconData kategoriIkonu(NotKategorisi kategori) {
  return switch (kategori) {
    NotKategorisi.ozel => TarusIkon.kilit,
    NotKategorisi.sirket => TarusIkon.sirket,
    NotKategorisi.proje => TarusIkon.proje,
  };
}

/// Not kategori bilgisi: Kategori türü ve varsa proje adı/etiketi.
@immutable
class NotKategoriBilgisi {
  const new({
    required this.kategori,
    this.projeAdi,
    this.projeId,
  });

  final NotKategorisi kategori;
  final String? projeAdi;
  final String? projeId;

  /// Kartta ve rozette gösterilecek etiket (STANDARTLAR §10 orta nokta).
  String get etiket {
    if (kategori == NotKategorisi.proje && (projeAdi?.isNotEmpty ?? false)) {
      return projeAdi!;
    }
    return kategori.etiket;
  }

  Map<String, dynamic> toMap() => {
    'category': kategori.kod,
    if (projeAdi != null) 'projectName': projeAdi,
    if (projeId != null) 'projeId': projeId,
  };

  String toJsonString() => jsonEncode(toMap());

  factory NotKategoriBilgisi.fromValue(dynamic val) {
    if (val == null) return const NotKategoriBilgisi(kategori: NotKategorisi.ozel);

    if (val is Map) {
      final kat = NotKategorisi.fromKod(val['category']?.toString());
      final proje = val['projectName']?.toString() ?? val['proje']?.toString();
      final id = val['projeId']?.toString();
      return NotKategoriBilgisi(
        kategori: kat,
        projeAdi: proje,
        projeId: id,
      );
    }

    final str = val.toString().trim();
    if (str.startsWith('{') && str.endsWith('}')) {
      try {
        final dynamic decoded = jsonDecode(str);
        if (decoded is Map) {
          return fromValue(decoded);
        }
      } catch (_) {}
    }

    // Kısa kod biçimi: 'internal', 'project:PRJ-12 · Konut', 'private'
    if (str.startsWith('project:')) {
      final proje = str.substring('project:'.length).trim();
      return NotKategoriBilgisi(
        kategori: NotKategorisi.proje,
        projeAdi: proje.isEmpty ? null : proje,
      );
    }

    return NotKategoriBilgisi(kategori: NotKategorisi.fromKod(str));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotKategoriBilgisi &&
          runtimeType == other.runtimeType &&
          kategori == other.kategori &&
          projeAdi == other.projeAdi &&
          projeId == other.projeId;

  @override
  int get hashCode => Object.hash(kategori, projeAdi, projeId);
}

/// Dosya yolunu kanonikleştirir (başındaki '/' ve gereksiz ekleri temizler).
String kanonikNotYolu(String path) {
  var temiz = path.trim().replaceAll(r'\', '/');
  while (temiz.startsWith('/')) {
    temiz = temiz.substring(1);
  }
  return temiz;
}

/// Verilen not dosyasının kategorisini okur.
///
/// Pusula projesine bağlı not (`stows.notProjeleri`, proje seçici) her zaman
/// Proje kategorisindedir; değilse `stows.notKategorileri`'ne bakılır.
NotKategoriBilgisi notKategorisiAl(String filePath) {
  final bagliProje = notunProjesi(filePath);
  if (bagliProje != null && bagliProje.isNotEmpty) {
    return NotKategoriBilgisi(
      kategori: NotKategorisi.proje,
      projeAdi: bagliProje,
    );
  }

  final harita = stows.notKategorileri.value;
  final kanonik = kanonikNotYolu(filePath);

  // Doğrudan veya '/'+kanonik anahtarıyla ara
  final ham = harita[kanonik] ?? harita['/$kanonik'] ?? harita[filePath];
  if (ham != null) {
    return NotKategoriBilgisi.fromValue(ham);
  }

  return const NotKategoriBilgisi(kategori: NotKategorisi.ozel);
}

/// Verilen not dosyasının kategorisini yerel olarak kaydeder.
void notKategoriAta(String filePath, NotKategoriBilgisi bilgi) {
  final kanonik = kanonikNotYolu(filePath);
  final harita = Map<String, String>.from(stows.notKategorileri.value);
  harita[kanonik] = bilgi.toJsonString();
  stows.notKategorileri.value = harita;
}

/// Kategori değiştirme işlevi: Yerel kaydı günceller ve sunucuya bildirir.
///
/// Sunucu ucu: `POST /api/notes/<filename>/category`
/// Gövde: `{ "category": "private"|"internal"|"project", "projeId": "..." }`
Future<bool> kategoriDegistir({
  required String notYolu,
  required NotKategorisi kategori,
  String? projeId,
  String? projeAdi,
  Uri? notSunucusu,
  String? belirtec,
  http.Client? httpClient,
}) async {
  final kanonik = kanonikNotYolu(notYolu);
  final bilgi = NotKategoriBilgisi(
    kategori: kategori,
    projeAdi: projeAdi,
    projeId: projeId,
  );

  // 1. Yerel durumu hemen güncelle (reaktif UI güncellenir)
  notKategoriAta(kanonik, bilgi);
  if (kategori != NotKategorisi.proje) {
    // Proje dışı kategoride Pusula proje bağı da kalkar (sunucu `proje: null` yazar).
    final projeler = Map<String, String>.from(stows.notProjeleri.value)
      ..remove(kanonik)
      ..remove('/$kanonik');
    stows.notProjeleri.value = projeler;
  }

  // 2. Sunucuya bildir (oturum açıksa)
  final token = (belirtec ?? stows.ncPassword.value).trim();
  final sunucu = notSunucusu ?? NextcloudClientExtension.defaultNextcloudUri;
  final client = httpClient ?? NextcloudClientExtension.newHttpClient();

  try {
    final url = sunucu.resolve('api/notes/${sunucuNotAdi(kanonik)}/category');
    final govde = jsonEncode({
      'category': kategori.kod,
      if (projeId != null && projeId.isNotEmpty) 'projeId': projeId,
    });

    final res = await client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: govde,
    );

    return res.statusCode >= 200 && res.statusCode < 300;
  } catch (_) {
    return false;
  } finally {
    if (httpClient == null) client.close();
  }
}
