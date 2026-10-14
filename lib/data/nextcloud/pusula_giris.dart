import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/nextcloud/pusula_belirteci.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tarus_baglantilar.dart';

/// «Pusula ile giriş»: Pusula hesabıyla girip bu cihaz için Not eşitleme
/// belirteci (`nes_…`) alır (kullanıcı kararı 2026-10-14).
///
/// Pusula Mobil ve Posta Mobil'le aynı yol: uygulama içi e-posta + parola
/// formu `POST /auth/giris/`'e `X-Client: mobile` ile gider, Pusula oturum
/// anahtarlarını gövdede döndürür; iki adımlı doğrulama açıksa önce 202 +
/// `challenge_token` gelir. Tarayıcı, OAuth istemcisi ya da yönlendirme
/// adresi yoktur.
///
/// Oturum anahtarı (JWT) yalnız belirteci almak için kullanılır:
///   1. `POST /not/belirtecler/` {ad: cihaz modeli} → `nes_…`
///   2. `POST /auth/cikis/` ile Pusula oturumu hemen kapatılır.
/// Cihazda yalnız eşitleme belirteci kalır; Not sunucusu Pusula anahtarını
/// hiç görmez. Çıkışta belirteç `POST /not/belirtecler/birak/` ile iptal
/// edilir; cihaz Pusula › Hesap › Bağlı cihazlar'da da kaldırılabilir.
abstract final class PusulaGiris {
  static final log = Logger('PusulaGiris');

  static const uygulama = 'not-mobil';
  static const _zamanAsimi = Duration(seconds: 20);

  /// E-posta + parolayla giriş. İki adımlı doğrulamada [IkiAdimGerekli] döner;
  /// çağıran kodu alıp [ikiAdimiTamamla] ile sürdürür.
  static Future<PusulaGirisSonucu> girisYap({
    required String eposta,
    required String parola,
    Uri? pusula,
    String? cihazAdi,
    http.Client? httpClient,
  }) {
    final kimlik = eposta.trim();
    return _giris(
      govde: {'email': kimlik, 'username': kimlik, 'password': parola},
      pusula: pusula,
      cihazAdi: cihazAdi,
      httpClient: httpClient,
    );
  }

  /// İkinci adım: Authenticator kodu ya da kurtarma kodu.
  static Future<PusulaGirisSonucu> ikiAdimiTamamla({
    required String challenge,
    required String kod,
    Uri? pusula,
    String? cihazAdi,
    http.Client? httpClient,
  }) => _giris(
    govde: {'challenge_token': challenge, 'totp_code': kod.trim()},
    pusula: pusula,
    cihazAdi: cihazAdi,
    httpClient: httpClient,
  );

  static Future<PusulaGirisSonucu> _giris({
    required Map<String, String> govde,
    Uri? pusula,
    String? cihazAdi,
    http.Client? httpClient,
  }) async {
    final kok = pusula ?? TarusBaglantilar.pusulaApi;
    final ad = cihazAdi ?? await buCihazinAdi();
    final client = httpClient ?? NextcloudClientExtension.newHttpClient();
    try {
      final giris = await client
          .post(
            _adres(kok, 'auth/giris/'),
            headers: _basliklar(cihazAdi: ad),
            body: jsonEncode(govde),
          )
          .timeout(_zamanAsimi);
      final veri = _json(giris);
      if (giris.statusCode == 202 &&
          veri['code'] == 'two_factor_required' &&
          veri['challenge_token'] is String) {
        return IkiAdimGerekli(veri['challenge_token'] as String);
      }
      if (giris.statusCode != 200) {
        throw PusulaGirisHatasi(
          _ayrinti(veri) ??
              (giris.statusCode == 400 || giris.statusCode == 401
                  ? 'E-posta ya da parola hatalı.'
                  : 'Pusula yanıt vermedi (${giris.statusCode}).'),
        );
      }
      final erisim = veri['access'];
      final yenileme = veri['refresh'];
      if (erisim is! String || erisim.isEmpty) {
        throw const PusulaGirisHatasi(
          'Pusula oturum anahtarı döndürmedi. Pusula sürümünü güncelleyin.',
        );
      }
      try {
        final yanit = await client
            .post(
              _adres(kok, 'not/belirtecler/'),
              headers: {
                ..._basliklar(cihazAdi: ad),
                'Authorization': 'Bearer $erisim',
              },
              body: jsonEncode({'ad': ad, 'cihaz_adi': ad}),
            )
            .timeout(_zamanAsimi);
        final belirtecVerisi = _json(yanit);
        final belirtec = belirtecVerisi['belirtec'];
        if (yanit.statusCode != 201 || belirtec is! String) {
          throw PusulaGirisHatasi(
            _ayrinti(belirtecVerisi) ??
                'Eşitleme erişimi alınamadı (${yanit.statusCode}).',
          );
        }
        return BelirtecAlindi(belirtec, cihazAdi: ad);
      } finally {
        // Pusula oturumu cihazda tutulmaz; başarısız olsa da oturum
        // Pusula › Hesap › Aktif oturumlar'dan kapatılabilir.
        if (yenileme is String && yenileme.isNotEmpty) {
          unawaited(
            client
                .post(
                  _adres(kok, 'auth/cikis/'),
                  headers: _basliklar(),
                  body: jsonEncode({'refresh_token': yenileme}),
                )
                .timeout(_zamanAsimi)
                .then<void>(
                  (_) {},
                  onError: (Object e) {
                    log.info('Pusula oturumu kapatılamadı: $e');
                  },
                ),
          );
        }
      }
    } on PusulaGirisHatasi {
      rethrow;
    } on TimeoutException {
      throw const PusulaGirisHatasi(
        'Pusula zamanında yanıt vermedi. Bağlantınızı denetleyip yeniden deneyin.',
      );
    } on SocketException {
      throw const PusulaGirisHatasi(
        "Pusula'ya ulaşılamadı. İnternet bağlantınızı denetleyin.",
      );
    } on http.ClientException catch (e) {
      throw PusulaGirisHatasi("Pusula'ya ulaşılamadı: ${e.message}");
    }
  }

  /// Belirteç Not sunucusunda doğrulanır ve kaydedilir (oturum açılır).
  static Future<void> baglan({
    required String belirtec,
    Uri? notSunucusu,
    http.Client? httpClient,
  }) async {
    final sunucu = notSunucusu ?? NextcloudClientExtension.defaultNextcloudUri;
    final kullaniciAdi = await PusulaBelirteci.dogrula(
      sunucu: sunucu,
      belirtec: belirtec,
      httpClient: httpClient,
    );
    PusulaBelirteci.kaydet(
      sunucu: sunucu,
      kullaniciAdi: kullaniciAdi,
      belirtec: belirtec,
    );
  }

  /// Bu oturum Pusula eşitleme belirteciyle mi açık (elle yapıştırılmış eski
  /// belirteçler dahil)? Başka Nextcloud sunucusunun uygulama parolası değil.
  static bool get pusulaBelirteciyleMi =>
      stows.url.value.isEmpty &&
      stows.ncPassword.value.startsWith(PusulaBelirteci.onek);

  /// Çıkışta cihazın belirtecini Pusula'da iptal eder. Ağ yoksa sessizce
  /// geçer; belirteç Pusula › Hesap › Bağlı cihazlar'dan kaldırılabilir.
  static Future<bool> birak(
    String belirtec, {
    Uri? pusula,
    http.Client? httpClient,
  }) async {
    final temiz = PusulaBelirteci.temizle(belirtec);
    if (!temiz.startsWith(PusulaBelirteci.onek)) return false;
    final client = httpClient ?? NextcloudClientExtension.newHttpClient();
    try {
      final yanit = await client
          .post(
            _adres(
              pusula ?? TarusBaglantilar.pusulaApi,
              'not/belirtecler/birak/',
            ),
            headers: {..._basliklar(), 'Authorization': 'Bearer $temiz'},
          )
          .timeout(_zamanAsimi);
      return yanit.statusCode == 204;
    } catch (e) {
      log.info('Eşitleme belirteci bırakılamadı: $e');
      return false;
    }
  }

  /// Pusula'daki «Bağlı cihazlar» listesinde görünecek ad (ör. «Samsung SM-X200»).
  static Future<String> buCihazinAdi() async {
    try {
      final bilgi = DeviceInfoPlugin();
      String ad;
      if (Platform.isAndroid) {
        final a = await bilgi.androidInfo;
        final uretici = _buyukBasla(a.manufacturer);
        ad = a.model.toLowerCase().startsWith(uretici.toLowerCase())
            ? a.model
            : '$uretici ${a.model}';
      } else if (Platform.isIOS) {
        final i = await bilgi.iosInfo;
        ad = i.modelName.isNotEmpty ? i.modelName : i.model;
      } else {
        ad = Platform.localHostname;
      }
      ad = ad.trim();
      return ad.isEmpty
          ? 'Not Mobil'
          : (ad.length > 80 ? ad.substring(0, 80) : ad);
    } catch (_) {
      return 'Not Mobil';
    }
  }

  static String _buyukBasla(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static Uri _adres(Uri kok, String yol) {
    final taban = kok.path.endsWith('/')
        ? kok
        : kok.replace(path: '${kok.path}/');
    return taban.resolve(yol);
  }

  static Map<String, String> _basliklar({String? cihazAdi}) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Pusula mobil istemciyi tanır, anahtarları gövdede döndürür; giriş
    // uyarısı e-postası «Not Mobil · <cihaz>» yazar (users/cihaz.py).
    'X-Client': 'mobile',
    'X-Tarus-App': uygulama,
    if (cihazAdi != null && cihazAdi.isNotEmpty)
      'X-Device-Name': _basligaUygun(cihazAdi),
  };

  /// HTTP başlığı yalnız Latin-1 taşır; Türkçe harfler sadeleşir.
  static String _basligaUygun(String s) {
    const harita = {'ı': 'i', 'İ': 'I', 'ş': 's', 'Ş': 'S', 'ğ': 'g', 'Ğ': 'G'};
    final b = StringBuffer();
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      final yeni = harita[c] ?? c;
      if (yeni.codeUnitAt(0) < 256) b.write(yeni);
    }
    return b.toString();
  }

  static Map<String, dynamic> _json(http.Response yanit) {
    try {
      final v = jsonDecode(utf8.decode(yanit.bodyBytes));
      return v is Map<String, dynamic> ? v : const {};
    } catch (_) {
      return const {};
    }
  }

  static String? _ayrinti(Map<String, dynamic> veri) {
    final detay = veri['detail'];
    if (detay is String && detay.isNotEmpty) return detay;
    for (final alan in ['non_field_errors', 'email', 'password']) {
      final v = veri[alan];
      if (v is List && v.isNotEmpty && v.first is String)
        return v.first as String;
    }
    return null;
  }
}

sealed class PusulaGirisSonucu {
  const new();
}

/// Hesapta iki adımlı doğrulama açık; kod istenmeli (challenge 5 dk geçerli).
class IkiAdimGerekli extends PusulaGirisSonucu {
  const new(this.challenge);
  final String challenge;
}

/// Giriş tamam; [belirtec] bu cihazın Not eşitleme belirtecidir.
class BelirtecAlindi extends PusulaGirisSonucu {
  const new(this.belirtec, {required this.cihazAdi});
  final String belirtec;
  final String cihazAdi;
}

class PusulaGirisHatasi implements Exception {
  const new(this.mesaj);
  final String mesaj;

  @override
  String toString() => mesaj;
}
