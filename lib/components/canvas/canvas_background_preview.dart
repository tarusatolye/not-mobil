import 'package:flutter/material.dart';
import 'package:saber/components/canvas/_canvas_background_painter.dart';
import 'package:saber/components/canvas/canvas_image.dart';
import 'package:saber/components/canvas/image/editor_image.dart';
import 'package:saber/components/canvas/inner_canvas.dart';
import 'package:saber/data/extensions/color_extensions.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:sbn/canvas_background_pattern.dart';

class CanvasBackgroundPreview extends StatelessWidget {
  const new({
    super.key,
    required this.selected,
    required this.invert,
    required this.backgroundColor,
    required this.backgroundPattern,
    required this.backgroundImage,
    this.overrideBoxFit,
    required this.pageSize,
    required this.lineHeight,
    required this.lineThickness,
  });

  final bool selected;
  final bool invert;
  final Color? backgroundColor;
  final CanvasBackgroundPattern backgroundPattern;
  final EditorImage? backgroundImage;
  final BoxFit? overrideBoxFit;
  final Size pageSize;
  final int lineHeight;
  final int lineThickness;

  static const double fixedWidth = 150;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final previewSize = Size(
      fixedWidth,
      pageSize.height / pageSize.width * fixedWidth,
    );
    final canvasSize = pageSize / 2;
    return Container(
      width: previewSize.width,
      height: previewSize.height,
      decoration: BoxDecoration(
        // tarus seçili durumu: vurgu kenarlığı; seçili değilken `--bdr2`.
        border: Border.all(
          color: selected ? r.accent : r.bdr2,
          width: selected ? 2 : 1,
        ),
        borderRadius: const .all(.circular(8)),
      ),
      child: ClipRRect(
        borderRadius: const .all(.circular(8)),
        child: Stack(
          children: [
            FittedBox(
              child: CustomPaint(
                size: canvasSize,
                painter: CanvasBackgroundPainter(
                  invert: invert,
                  backgroundColor: () {
                    if (backgroundImage != null) {
                      return Colors.white;
                    } else {
                      return backgroundColor ??
                          InnerCanvas.defaultBackgroundColor;
                    }
                  }(),
                  backgroundPattern: () {
                    if (backgroundImage != null) {
                      return CanvasBackgroundPattern.none;
                    } else {
                      return backgroundPattern;
                    }
                  }(),
                  lineHeight: lineHeight,
                  lineThickness: lineThickness,
                  // tarus: kağıt çizgileri temadan bağımsız (dışa aktarma).
                  primaryColor: TarusKagit.cizgi
                      .withSaturation(selected ? 1 : 0)
                      .withValues(alpha: selected ? 1 : 0.5),
                  secondaryColor: TarusKagit.kenar
                      .withSaturation(selected ? 1 : 0)
                      .withValues(alpha: selected ? 1 : 0.5),
                  preview: true,
                ),
              ),
            ),
            if (backgroundImage != null)
              CanvasImage(
                filePath: '',
                image: backgroundImage!,
                overrideBoxFit: overrideBoxFit,
                pageSize: previewSize,
                setAsBackground: null,
                isBackground: true,
                readOnly: true,
              ),
          ],
        ),
      ),
    );
  }
}
