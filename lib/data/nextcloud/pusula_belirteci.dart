import 'package:http/http.dart' as http;
import 'package:nextcloud/nextcloud.dart';
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/prefs.dart';

/// tarus Not sunucusuna Pusula eşitleme belirteciyle bağlanma.
///
/// Not'un ayrı kullanıcı hesabı yoktur: kullanıcı Pusula → Ayarlar →
/// Not eşitleme ekranında cihaz için bir belirteç (`nes_…`) üretir, burada
/// yapıştırır. Belirteç Nextcloud istemcisinin parola alanında gider
/// (HTTP Basic); Not sunucusu onu Pusula'ya doğrulatır. İptal Pusula'dan.
abstract final class PusulaBelirteci {
  static const onek = 'nes_';

  /// Kullanıcı adı alanı bilgi amaçlıdır; kimliği belirteç belirler.
  static const kullaniciAdiYeri = 'pusula';

  static String temizle(String ham) => ham.trim().replaceAll(RegExp(r'\s'), '');

  static bool gecerliMi(String ham) {
    final b = temizle(ham);
    return b.startsWith(onek) && b.length >= onek.length + 20;
  }

  /// Belirteci sunucuya doğrulatır; başarılıysa Not'taki kullanıcı kimliğini
  /// döndürür. Geçersiz/iptal edilmiş belirteçte [DynamiteStatusCodeException] (401).
  static Future<String> dogrula({
    required Uri sunucu,
    required String belirtec,
    http.Client? httpClient,
  }) async {
    final temiz = temizle(belirtec);
    final client = NextcloudClient(
      sunucu,
      loginName: kullaniciAdiYeri,
      password: temiz,
      appPassword: temiz,
      httpClient: httpClient ?? NextcloudClientExtension.newHttpClient(),
    );
    return client.getUsername();
  }

  /// Doğrulanmış bağlantıyı kaydeder (oturum açık sayılır).
  static void kaydet({
    required Uri sunucu,
    required String kullaniciAdi,
    required String belirtec,
  }) {
    stows.url.value =
        sunucu.toString() ==
            NextcloudClientExtension.defaultNextcloudUri.toString()
        ? ''
        : sunucu.toString();
    stows.username.value = kullaniciAdi;
    stows.ncPassword.value = temizle(belirtec);
    stows.encPassword.value = '';
    stows.pfp.value = null;
  }
}
