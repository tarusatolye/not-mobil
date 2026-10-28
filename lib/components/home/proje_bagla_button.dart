import 'package:flutter/material.dart';
import 'package:saber/components/home/proje_bagla_dialog.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_ikon.dart';

/// Notu bir Pusula projesine bağlamak için düğme (SecimCubugu öğesi).
class ProjeBaglaButton extends StatelessWidget {
  const new({
    super.key,
    required this.filePath,
    required this.unselectNotes,
  });

  final String filePath;
  final void Function() unselectNotes;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      tooltip: t.tarus.proje.bagla,
      onPressed: () {
        ProjeBaglaDialog.dialogAc(
          context,
          existingPath: filePath,
          unselectNotes: unselectNotes,
        );
      },
      icon: const Icon(TarusIkon.proje),
    );
  }
}
