import 'package:flutter/material.dart' hide TransformationController;
import 'package:saber/components/canvas/hud/canvas_gesture_lock_btn.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Yakınlaştırma göstergesi: kilit düğmeleriyle aynı HUD çipi; dokununca
/// yakınlaştırma sıfırlanır.
class CanvasZoomIndicator extends StatelessWidget {
  const new({super.key, required this.scale, required this.resetZoom});

  final double scale;
  final VoidCallback? resetZoom;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    const radius = BorderRadius.all(Radius.circular(TarusOlcu.rMd));
    return DecoratedBox(
      decoration: tarusHudZemini(r),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: resetZoom,
          borderRadius: radius,
          child: Container(
            height: tarusHudBoyu,
            constraints: const BoxConstraints(minWidth: tarusHudBoyu),
            padding: const .symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: Text(
              '${scale.toStringAsFixed(1)}×',
              style: TextStyle(
                color: r.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
