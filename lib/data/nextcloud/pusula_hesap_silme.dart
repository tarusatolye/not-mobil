import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:nextcloud/webdav.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/nextcloud/pusula_giris.dart';
import 'package:saber/data/nextcloud/saber_syncer.dart';
import 'package:saber/data/tarus_baglantilar.dart';

/// Uygulama içi hesap silme (App Store 5.1.1(v)).
///
/// Not'un ayrı hesabı yoktur; kimlik Pusula hesabıdır. Silme Pusula'nın
/// `GET|POST /auth/me/hesabi-sil/` ucuyla yapılır (Arkiv ve Sistem'in
/// kullandığı uç). Bu uç Pusula oturum anahtarı (JWT) ister; cihazda yalnız
/// `nes_…` eşitleme belirteci durduğundan kullanıcı e-posta + parolayla
/// yeniden girer, anahtar yalnız bu işlem için alınır ve işlem bitince
/// oturum kapatılır (belirteç alma yolundaki gibi, [PusulaGiris]).
///
/// Sıra: parola doğrulanmış oturum → silinecekler özeti ([plan]) → onay →
/// sunucudaki notlar silinir ([sunucuNotlariniSil], belirteç hâlâ geçerliyken)
/// → hesap silinir ([sil]) → cihaz temizlenir (çağıran, `NotCikisi`).
abstract final class PusulaHesapSilme {
  static final log = Logger('PusulaHesapSilme');

  /// E-posta + parolayla Pusula oturumu açar. İki adımlı doğrulamada
  /// [HesapSilmeIkiAdim] döner; çağıran kodu [ikiAdimiTamamla]'ya verir.
  static Future<HesapSilmeGirisi> girisYap({
    required String eposta,
    required String parola,
    Uri? pusula,
    http.Client? httpClient,
  }) {
    final kimlik = eposta.trim();
    return _giris(
      govde: {'email': kimlik, 'username': kimlik, 'password': parola},
      pusula: pusula,
      httpClient: httpClient,
    );
  }

  static Future<HesapSilmeGirisi> ikiAdimiTamamla({
    required String challenge,
    required String kod,
    Uri? pusula,
    http.Client? httpClient,
  }) => _giris(
    govde: {'challenge_token': challenge, 'totp_code': kod.trim()},
    pusula: pusula,
    httpClient: httpClient,
  );

  static Future<HesapSilmeGirisi> _giris({
    required Map<String, String> govde,
    Uri? pusula,
    http.Client? httpClient,
  }) async {
    final kok = pusula ?? TarusBaglantilar.pusulaApi;
    final client = httpClient ?? NextcloudClientExtension.newHttpClient();
    try {
      final yanit = await client
          .post(
            PusulaGiris.adres(kok, 'auth/giris/'),
            headers: PusulaGiris.basliklar(),
            body: jsonEncode(govde),
          )
          .timeout(PusulaGiris.zamanAsimi);
      final veri = PusulaGiris.json(yanit);
      if (yanit.statusCode == 202 &&
          veri['code'] == 'two_factor_required' &&
          veri['challenge_token'] is String) {
        return HesapSilmeIkiAdim(veri['challenge_token'] as String);
      }
      if (yanit.statusCode != 200) {
        throw HesapSilmeHatasi(
          PusulaGiris.ayrinti(veri) ??
              (yanit.statusCode == 400 || yanit.statusCode == 401
                  ? 'E-posta ya da parola hatalı.'
                  : 'Pusula yanıt vermedi (${yanit.statusCode}).'),
        );
      }
      final erisim = veri['access'];
      if (erisim is! String || erisim.isEmpty) {
        throw const HesapSilmeHatasi('Pusula oturum anahtarı döndürmedi.');
      }
      final yenileme = veri['refresh'];
      return HesapSilmeOturumu(
        erisim,
        yenileme is String && yenileme.isNotEmpty ? yenileme : null,
      );
    } on HesapSilmeHatasi {
      rethrow;
    } on TimeoutException {
      throw const HesapSilmeHatasi(
        'Pusula zamanında yanıt vermedi. Bağlantınızı denetleyip yeniden deneyin.',
      );
    } on SocketException {
      throw const HesapSilmeHatasi(
        "Pusula'ya ulaşılamadı. İnternet bağlantınızı denetleyin.",
      );
    } on http.ClientException catch (e) {
      throw HesapSilmeHatasi("Pusula'ya ulaşılamadı: ${e.message}");
    }
  }

  /// Silinecek ve korunacak verinin özeti (veriye dokunmaz).
  static Future<HesapSilmePlani> plan(
    HesapSilmeOturumu oturum, {
    Uri? pusula,
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? NextcloudClientExtension.newHttpClient();
    try {
      final yanit = await client
          .get(
            PusulaGiris.adres(pusula ?? TarusBaglantilar.pusulaApi,
                'auth/me/hesabi-sil/'),
            headers: {
              ...PusulaGiris.basliklar(),
              'Authorization': 'Bearer ${oturum.erisim}',
            },
          )
          .timeout(PusulaGiris.zamanAsimi);
      final veri = PusulaGiris.json(yanit);
      if (yanit.statusCode != 200) {
        throw HesapSilmeHatasi(
          PusulaGiris.ayrinti(veri) ??
              'Hesap bilgisi alınamadı (${yanit.statusCode}).',
        );
      }
      return HesapSilmePlani.fromJson(veri);
    } on HesapSilmeHatasi {
      rethrow;
    } on TimeoutException {
      throw const HesapSilmeHatasi('Pusula zamanında yanıt vermedi.');
    } on SocketException {
      throw const HesapSilmeHatasi("Pusula'ya ulaşılamadı.");
    } on http.ClientException catch (e) {
      throw HesapSilmeHatasi("Pusula'ya ulaşılamadı: ${e.message}");
    }
  }

  /// Hesabı kalıcı siler (Pusula kişisel veriyi siler, şirket verisini
  /// «Silinmiş kullanıcı» adıyla korur). Eşitleme belirteçleri de gider.
  static Future<void> sil(
    HesapSilmeOturumu oturum, {
    required String parola,
    Uri? pusula,
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? NextcloudClientExtension.newHttpClient();
    try {
      final yanit = await client
          .post(
            PusulaGiris.adres(pusula ?? TarusBaglantilar.pusulaApi,
                'auth/me/hesabi-sil/'),
            headers: {
              ...PusulaGiris.basliklar(),
              'Authorization': 'Bearer ${oturum.erisim}',
            },
            body: jsonEncode({'password': parola}),
          )
          .timeout(PusulaGiris.zamanAsimi);
      if (yanit.statusCode != 200) {
        throw HesapSilmeHatasi(
          PusulaGiris.ayrinti(PusulaGiris.json(yanit)) ??
              'Hesap silinemedi (${yanit.statusCode}).',
        );
      }
    } on HesapSilmeHatasi {
      rethrow;
    } on TimeoutException {
      throw const HesapSilmeHatasi('Pusula zamanında yanıt vermedi.');
    } on SocketException {
      throw const HesapSilmeHatasi("Pusula'ya ulaşılamadı.");
    } on http.ClientException catch (e) {
      throw HesapSilmeHatasi("Pusula'ya ulaşılamadı: ${e.message}");
    }
  }

  /// Yalnız plan alınıp vazgeçilirse Pusula oturumunu kapatır (hesap
  /// silindiyse oturum zaten geçersizdir). Hata sessiz geçer.
  static Future<void> oturumuKapat(
    HesapSilmeOturumu oturum, {
    Uri? pusula,
    http.Client? httpClient,
  }) async {
    final yenileme = oturum.yenileme;
    if (yenileme == null) return;
    final client = httpClient ?? NextcloudClientExtension.newHttpClient();
    try {
      await client
          .post(
            PusulaGiris.adres(pusula ?? TarusBaglantilar.pusulaApi,
                'auth/cikis/'),
            headers: PusulaGiris.basliklar(),
            body: jsonEncode({'refresh_token': yenileme}),
          )
          .timeout(PusulaGiris.zamanAsimi);
    } catch (e) {
      log.info('Pusula oturumu kapatılamadı: $e');
    }
  }

  /// Not sunucusundaki bu kullanıcının tüm notlarını siler (WebDAV, geçerli
  /// eşitleme belirteciyle). Bulunmayan klasör (404) başarı sayılır. Hesap
  /// silinmeden **önce** çağrılır; belirteç hesapla birlikte iptal olur.
  /// Silinemediyse `false` döner (hesap silme engellenmez; arayüz kullanıcıya
  /// notların silinmediğini ve destek yolunu söyler).
  static Future<bool> sunucuNotlariniSil() async {
    final client = SaberSyncInterface.client;
    if (client == null) return false;
    try {
      final yanit = await client.webdav
          .delete(PathUri.parse(FileManager.appRootDirectoryPrefix))
          .timeout(const Duration(seconds: 60));
      await yanit.stream.drain<void>();
      final kod = yanit.statusCode;
      return kod == 404 || (kod >= 200 && kod < 300);
    } catch (e) {
      log.warning('Sunucudaki notlar silinemedi: $e');
      return false;
    }
  }
}

sealed class HesapSilmeGirisi {
  const new();
}

class HesapSilmeIkiAdim extends HesapSilmeGirisi {
  const new(this.challenge);
  final String challenge;
}

class HesapSilmeOturumu extends HesapSilmeGirisi {
  const new(this.erisim, this.yenileme);
  final String erisim;
  final String? yenileme;
}

class HesapSilmePlani {
  const new({
    required this.hesap,
    required this.parolasiz,
    required this.engel,
    required this.silinecek,
    required this.korunan,
    required this.uyari,
  });

  factory HesapSilmePlani.fromJson(Map<String, dynamic> j) {
    List<String> metinler(Object? v) =>
        v is List ? v.whereType<String>().toList() : const [];
    final silinecek = <String>[
      ...metinler(j['silinecek_profil']),
      for (final s in (j['silinecek'] as List? ?? const []))
        if (s is Map && s['ad'] is String) '${s['ad']} (${s['sayi']})',
    ];
    return HesapSilmePlani(
      hesap: (j['hesap'] as String?) ?? '',
      parolasiz: j['parolasiz'] == true,
      engel: j['engel'] is String ? j['engel'] as String : null,
      silinecek: silinecek,
      korunan: metinler(j['korunan']),
      uyari: (j['uyari'] as String?) ?? '',
    );
  }

  final String hesap;

  /// Hesabın parolası yok (yalnız tarus Hesap ile girenler): uygulama içinde
  /// silinemez, web sayfasına yönlendirilir.
  final bool parolasiz;
  final String? engel;
  final List<String> silinecek;
  final List<String> korunan;
  final String uyari;
}

class HesapSilmeHatasi implements Exception {
  const new(this.mesaj);
  final String mesaj;

  @override
  String toString() => mesaj;
}
