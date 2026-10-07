import 'package:flutter/material.dart';
import 'package:saber/components/toolbar/size_picker.dart';
import 'package:saber/data/extensions/axis_extensions.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tools/_tool.dart';
import 'package:saber/data/tools/highlighter.dart';
import 'package:saber/data/tools/pen.dart';
import 'package:saber/data/tools/pencil.dart';
import 'package:saber/data/tools/shape_pen.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';

class PenModal extends StatefulWidget {
  const new({super.key, required this.getTool, required this.setTool});

  final Tool Function() getTool;
  final void Function(Pen) setTool;

  @override
  State<PenModal> createState() => _PenModalState();
}

class _PenModalState extends State<PenModal> {
  @override
  Widget build(BuildContext context) {
    final axis = stows.editorToolbarAlignment.value.axis.opposite;
    final Tool currentTool = widget.getTool();
    final Pen currentPen;
    if (currentTool is Pen) {
      currentPen = currentTool;
    } else {
      return const SizedBox();
    }

    return Flex(
      direction: axis,
      mainAxisAlignment: .center,
      children: [
        SizePicker(axis: axis, pen: currentPen),
        if (currentPen is! Highlighter && currentPen is! Pencil) ...[
          const SizedBox.square(dimension: 8),
          for (final (ikon, ad, uret) in [
            (Pen.fountainPenIcon, t.editor.pens.fountainPen, Pen.fountainPen),
            (
              Pen.ballpointPenIcon,
              t.editor.pens.ballpointPen,
              Pen.ballpointPen,
            ),
            (ShapePen.shapePenIcon, t.editor.pens.shapePen, ShapePen.new),
          ])
            Padding(
              padding: const .all(2),
              child: TarusIkonDugmesi(
                ikon: ikon,
                tooltip: ad,
                secili: Pen.currentPen.icon == ikon,
                onPressed: () => setState(() {
                  widget.setTool(uret());
                }),
              ),
            ),
        ],
      ],
    );
  }
}
