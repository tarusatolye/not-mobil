import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/version.dart';

/// tarus Hata bildir (web'deki "Hata bildir"in mobil karşılığı).
///
/// not-mobil'de Pusula oturumu yoktur (Pusula belirteci Not uygulamalarına
/// inmez). Kayıt eşitleme belirteciyle Not sunucusuna (`POST /mobil/hata-bildir`)
/// gider; Not sunucusu onu Pusula'ya (`/not/hata-bildir/`) iletir, oradan
/// sistem.tarus.tr Hata Panosu'na `not.tarus.tr` altında düşer.
abstract final class HataBildir {
  /// Pusula alanı metin; ekran görüntüsü base64 gömülür, büyükse reddedilir.
  static const enBuyukGoruntu = 2 * 1024 * 1024;

  static bool get bagliMi => stows.ncPassword.value.isNotEmpty;

  static Uri get sunucu => stows.url.value.isEmpty
      ? NextcloudClientExtension.defaultNextcloudUri
      : Uri.parse(stows.url.value);

  /// Kaydı gönderir; başarısızsa [HataBildirHatasi] fırlatır.
  static Future<void> gonder({
    required String baslik,
    required String aciklama,
    String modul = 'Not Mobil',
    Uint8List? goruntu,
    String goruntuTuru = 'image/png',
    http.Client? httpClient,
  }) async {
    if (!bagliMi) throw const HataBildirHatasi('Önce Pusula ile bağlanın.');
    if (goruntu != null && goruntu.length > enBuyukGoruntu) {
      throw const HataBildirHatasi('Ekran görüntüsü çok büyük (en çok 2 MB).');
    }
    final kimlik = base64Encode(
      utf8.encode('${stows.username.value}:${stows.ncPassword.value}'),
    );
    final client = httpClient ?? NextcloudClientExtension.newHttpClient();
    final http.Response yanit;
    try {
      yanit = await client.post(
        sunucu.resolve('mobil/hata-bildir'),
        headers: {
          'Authorization': 'Basic $kimlik',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'title': baslik.trim(),
          'description': aciklama.trim(),
          'module': modul,
          'screenshot': goruntu == null
              ? ''
              : 'data:$goruntuTuru;base64,${base64Encode(goruntu)}',
          'meta': {
            'platform': Platform.operatingSystem,
            'platformVersion': Platform.operatingSystemVersion,
            'appVersion': buildName,
          },
        }),
      );
    } on Exception {
      throw const HataBildirHatasi(
        'Sunucuya ulaşılamadı. Bağlantınızı denetleyin.',
      );
    } finally {
      if (httpClient == null) client.close();
    }
    if (yanit.statusCode == 201) return;
    String? detay;
    try {
      detay =
          (jsonDecode(yanit.body) as Map<String, dynamic>)['detail'] as String?;
    } on Object {
      detay = null;
    }
    throw HataBildirHatasi(
      detay ?? 'Bildirim gönderilemedi (${yanit.statusCode}).',
    );
  }
}

class HataBildirHatasi implements Exception {
  const new(this.mesaj);
  final String mesaj;

  @override
  String toString() => mesaj;
}
