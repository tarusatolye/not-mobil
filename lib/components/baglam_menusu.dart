import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:saber/pages/user/hata_bildir_sayfasi.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Basılı tutma menüsü: web'deki sağ tık menüsünün mobil karşılığı
/// (pusula-mobil ve posta-mobil `BaglamMenusu` ile aynı davranış).
///
/// Ekranın boş bir yerinde parmak ~0,7 sn kıpırdamadan basılı tutulunca ortada
/// "Hata bildir" onayı açılır (alttan açılan sayfa yok, ekosistem standardı). Tanıyıcı Flutter hareket yarışına katılır:
/// kaydırma, dokunma ve kendi basılı tutma işlevi olan öğeler (not kartı
/// seçimi, ayarı sıfırlama, metin seçimi) önce kazanır, o dokunuşta menü
/// açılmaz. Yazı alanı odaklıysa da açılmaz.
///
/// Çizim yüzeyleri (düzenleyici, beyaz tahta) sarılmaz: kalemi kıpırdatmadan
/// tutmak orada çizimdir.
class BaglamMenusu extends StatelessWidget {
  const new({
    super.key,
    required this.modul,
    required this.child,
    this.etkin = true,
  });

  /// Hata bildiriminin "Ekran" alanı (Pusula'da modül).
  final String modul;
  final Widget child;
  final bool etkin;

  static const basiliTutma = Duration(milliseconds: 700);

  /// Odakta bir yazı alanı var mı (metin seçme/yapıştırma menüsü onundur).
  static bool get _yaziOdakta {
    final odak = FocusManager.instance.primaryFocus?.context;
    if (odak == null) return false;
    return odak.widget is EditableText ||
        odak.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  static Future<void> menuyuAc(BuildContext context, String modul) async {
    final r = TarusRenkler.of(context);
    final secim = await showDialog<bool>(
      context: context,
      builder: (context) => TarusOnay(
        baslik: 'Hata bildir',
        mesaj: '«$modul» ekranıyla ilgili bir sorunu bildirmek ister misiniz?',
        ikon: TarusIkon.hataBildir,
        renk: r.danger,
        dugmeler: [
          TarusDialogDugmesi(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TarusDialogDugmesi(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bildir'),
          ),
        ],
      ),
    );
    if (secim != true || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => HataBildirSayfasi(modul: modul)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!etkin) return child;
    return RawGestureDetector(
      behavior: .translucent,
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: basiliTutma),
              (tanima) => tanima.onLongPress = () {
                if (_yaziOdakta) return;
                menuyuAc(context, modul);
              },
            ),
      },
      child: child,
    );
  }
}
