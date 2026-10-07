import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:saber/pages/user/hata_bildir_sayfasi.dart';
import 'package:saber/tarus/tarus_ikon.dart';

/// Basılı tutma menüsü: web'deki sağ tık menüsünün mobil karşılığı
/// (pusula-mobil ve posta-mobil `BaglamMenusu` ile aynı davranış).
///
/// Ekranın boş bir yerinde parmak ~0,7 sn kıpırdamadan basılı tutulunca alttan
/// "Hata bildir" menüsü açılır. Tanıyıcı Flutter hareket yarışına katılır:
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
    final renk = Theme.of(context).colorScheme;
    final secim = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: .min,
          children: [
            ListTile(
              leading: Icon(TarusIkon.hataBildir, color: renk.error),
              title: Text(
                'Hata bildir',
                style: TextStyle(color: renk.error, fontWeight: .w600),
              ),
              onTap: () => Navigator.of(context).pop(true),
            ),
            ListTile(
              leading: const Icon(TarusIkon.kapat),
              title: const Text('Vazgeç'),
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
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
