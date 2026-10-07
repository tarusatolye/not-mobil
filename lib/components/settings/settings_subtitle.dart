import 'package:flutter/material.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Ayarlar bölüm başlığı (tarus bölüm etiketi).
class SettingsSubtitle extends StatelessWidget {
  const new({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) => TarusBolumEtiketi(subtitle);
}

/// Ayarlar grubu: tek tarus kartında, aralarında ince ayırıcı olan satırlar.
class AyarGrubu extends StatelessWidget {
  const new({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return TarusKart(
      child: ListTileTheme.merge(
        tileColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, indent: 50, color: r.bdr1),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Ayar satırlarının ortak parçaları.
abstract final class AyarSatiri {
  static const ic = EdgeInsets.symmetric(
    horizontal: TarusOlcu.kart,
    vertical: 2,
  );

  static Widget ikon(IconData ikon) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 100),
    child: Icon(ikon, key: ValueKey(ikon), size: 20),
  );

  /// Değer varsayılandan farklıysa başlık italik (Saber davranışı).
  static Widget baslik(String metin, {bool degisti = false}) => Text(
    metin,
    style: TextStyle(fontStyle: degisti ? FontStyle.italic : null),
  );
}
