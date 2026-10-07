import 'package:flutter/material.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Konum çubuğu (STANDARTLAR §tarusBreadcrumb): kökte «Notlar», alt
/// klasörlerde solda üst klasöre dönüş düğmesi; öğeler 12 px, ayraç 14 px
/// `ChevronRight`, son öğe 600 ve tıklanamaz.
class PathComponents extends StatelessWidget {
  new(String? path, {super.key, required this.onPathComponentTap, this.onBack})
    : components = _splitPath(path);

  final List<String> components;
  final void Function(String? path) onPathComponentTap;

  /// Üst klasöre dön; null ise düğme gösterilmez.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final ogeler = <Widget>[
      _Oge(
        metin: t.home.titles.browse,
        aktif: components.isEmpty,
        onTap: () => onPathComponentTap(null),
      ),
      for (var i = 0; i < components.length; i++) ...[
        Icon(TarusIkon.ileri, size: 14, color: r.muted2),
        _Oge(
          metin: components[i],
          aktif: i == components.length - 1,
          onTap: () =>
              onPathComponentTap('/${components.sublist(0, i + 1).join('/')}'),
        ),
      ],
    ];
    // Kökte başlık zaten «Notlar»; konum çubuğu yalnız alt klasörde.
    if (components.isEmpty) return const SizedBox(height: 4);
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          if (components.isNotEmpty && onBack != null) ...[
            IconButton(
              tooltip: t.home.backFolder,
              onPressed: onBack,
              icon: const Icon(TarusIkon.geri, size: 18),
            ),
            const SizedBox(width: 2),
          ] else
            const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(spacing: 4, children: ogeler),
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _splitPath(String? path) {
    return (path ?? '')
        .split(RegExp(r'[\\/]'))
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }
}

class const _Oge({
  required final String metin,
  required final bool aktif,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final yazi = Text(
      metin,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: aktif ? FontWeight.w600 : FontWeight.w500,
        color: aktif ? r.text : r.muted2,
      ),
    );
    if (aktif) {
      return Padding(padding: const EdgeInsets.all(4), child: yazi);
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(padding: const EdgeInsets.all(4), child: yazi),
    );
  }
}
