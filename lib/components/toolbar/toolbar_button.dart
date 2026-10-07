import 'package:flutter/material.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_olcu.dart';

/// Editör araç çubuğu düğmesi: 40 px, Lucide ikon; seçili araç vurgu
/// %14 zemin + %45 kenarlıkla (Pusula Mobil `selectionStyle`) gösterilir.
class ToolbarIconButton extends StatelessWidget {
  const new({
    super.key,
    this.tooltip,
    this.selected = false,
    this.enabled = true,
    required this.onPressed,
    required this.padding,
    required this.child,
  });

  final String? tooltip;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: TarusIkonDugmesi(
        ikon: null,
        tooltip: tooltip,
        secili: selected && enabled,
        onPressed: enabled ? onPressed : null,
        ikonBoyutu: TarusOlcu.ikon,
        child: child,
      ),
    );
  }
}
