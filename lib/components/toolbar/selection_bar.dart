import 'package:flutter/material.dart';
import 'package:saber/data/extensions/axis_extensions.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Seçim aracının seçenekleri: çoğalt ve sil (araç çubuğu ikon düğmeleri;
/// sil tehlike renginde). Kalem seçenekleri gibi araç çubuğuna dik dizilir.
class SelectionBar extends StatelessWidget {
  final VoidCallback duplicateSelection;
  final VoidCallback deleteSelection;

  const new({
    super.key,
    required this.duplicateSelection,
    required this.deleteSelection,
  });

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final axis = stows.editorToolbarAlignment.value.axis.opposite;
    return Flex(
      direction: axis,
      mainAxisAlignment: .center,
      children: [
        Padding(
          padding: const .all(2),
          child: TarusIkonDugmesi(
            ikon: TarusIkon.kopyala,
            tooltip: t.editor.selectionBar.duplicate,
            onPressed: duplicateSelection,
          ),
        ),
        Padding(
          padding: const .all(2),
          child: TarusIkonDugmesi(
            ikon: TarusIkon.sil,
            tooltip: t.editor.selectionBar.delete,
            renk: r.danger,
            onPressed: deleteSelection,
          ),
        ),
      ],
    );
  }
}
