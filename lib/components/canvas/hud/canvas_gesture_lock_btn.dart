import 'package:flutter/material.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Tuval üstü göstergesi (HUD) çipinin zemini: yüzen alt çubuk gibi
/// `--card` %97, 1 px `--bdr1`, köşe 10, `--elev-1`. Etkinken Pusula
/// `selectionStyle` kenarlığı.
BoxDecoration tarusHudZemini(TarusRenkler r, {bool secili = false}) =>
    BoxDecoration(
      color: Color.alphaBlend(TarusSecim.zemin(r, secili), r.barBg),
      borderRadius: const .all(.circular(TarusOlcu.rMd)),
      border: Border.all(
        color: secili
            ? r.accent.withValues(alpha: TarusOlcu.seciliKenarAlfa)
            : r.bdr1,
      ),
      boxShadow: r.elev1,
    );

/// HUD çipinin boyu (yakınlaştırma göstergesi de aynı boyda).
const tarusHudBoyu = 36.0;

class CanvasGestureLockBtn extends StatelessWidget {
  /// Either [icon] or [child] must be provided.
  /// If both are provided, [child] will be used.
  /// If [child] is provided, you are required to handle the animation.
  const new({
    super.key,
    required this.lock,
    required this.setLock,
    required this.tooltip,
    this.icon,
    this.child,
  }) : assert(icon != null || child != null);

  final bool lock;
  final ValueChanged<bool> setLock;
  final String tooltip;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final on = lock ? r.accent : r.muted2;
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        toggled: lock,
        label: tooltip,
        child: GestureDetector(
          onTap: () => setLock(!lock),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: tarusHudBoyu,
            height: tarusHudBoyu,
            decoration: tarusHudZemini(r, secili: lock),
            alignment: Alignment.center,
            child: IconTheme.merge(
              data: IconThemeData(color: on, size: 18),
              child:
                  child ??
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(icon, key: ValueKey(icon)),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
