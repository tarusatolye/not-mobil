import 'package:flutter/material.dart';
import 'package:saber/data/tarus_baglantilar.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Profil › "Hesabı sil": tarus'ta hesap ve veri silmenin yolları.
///
/// Saber burada Nextcloud'un `settings/user/drop_account` sayfasını açıyordu;
/// Not sunucusu Nextcloud değil ve Not'un ayrı hesabı yok (kimlik Pusula).
/// Play "hesap silme" şartı için uygulama içinde açık yol + web adresi
/// (`TarusBaglantilar.hesapSilme`, Play Console'a da aynı adres yazılır).
class HesapSilmeDialog extends StatelessWidget {
  const new({super.key});

  static Future<void> goster(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const HesapSilmeDialog(),
  );

  static final _eposta = Uri(
    scheme: 'mailto',
    path: TarusBaglantilar.iletisimEposta,
    query: 'subject=tarus%20Not%20hesap%20ve%20veri%20silme',
  );

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    Widget baslik(String metin) => Padding(
      padding: const .only(top: 16, bottom: 4),
      child: Text(
        metin,
        style: TextStyle(
          fontSize: TarusOlcu.yaziKartBasligi,
          fontWeight: FontWeight.w600,
          color: r.text,
        ),
      ),
    );
    Widget baglanti(String metin, Uri adres) => Align(
      alignment: .centerLeft,
      child: TextButton(
        onPressed: () => launchUrl(adres, mode: .externalApplication),
        child: Text(metin),
      ),
    );

    return TarusDialog(
      title: const Text('Hesap ve veri silme'),
      content: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          const Text(
            "tarus Not'un ayrı bir hesabı yoktur; kimliğiniz Pusula "
            'hesabınızdır. Bu uygulamadan eşitlenen notlar Not sunucusunda '
            'şifreli saklanır.',
          ),
          baslik('1. Bu cihazın erişimini kaldırın'),
          const Text(
            'Pusula › Ayarlar › Not eşitleme bölümünde bu cihazın '
            'belirtecini iptal edin. Cihaz en geç 30 saniye içinde '
            'eşitleyemez olur.',
          ),
          baglanti("Pusula Ayarlar'ı aç", TarusBaglantilar.pusulaAyarlar),
          baslik('2. Bu cihazdaki verileri silin'),
          const Text(
            'Profil ekranından çıkış yapın, ardından uygulamayı kaldırın. '
            'Kaldırınca cihazdaki notlar silinir.',
          ),
          baslik('3. Sunucudaki notları ve hesabı sildirin'),
          const Text(
            'Not sunucusundaki tüm notlarınızın ve hesap bilgilerinizin '
            'silinmesini web sayfasından ya da '
            '${TarusBaglantilar.iletisimEposta} adresine yazarak '
            'isteyebilirsiniz. Talepler en geç 30 gün içinde sonuçlanır.',
          ),
          baglanti('Silme talebi (web)', TarusBaglantilar.hesapSilme),
          baglanti('E-postayla iste', _eposta),
        ],
      ),
      actions: [
        TarusDialogDugmesi(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}
