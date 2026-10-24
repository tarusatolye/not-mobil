import 'package:flutter/material.dart';
import 'package:saber/components/home/kategori_secim_dialog.dart';
import 'package:saber/tarus/tarus_ikon.dart';

/// Seçim çubuğunda tek not seçiliyken beliren «Kategori belirle» düğmesi.
class KategoriDegistirButton extends StatelessWidget {
  const new({
    super.key,
    required this.filePath,
    required this.unselectNotes,
  });

  final String filePath;
  final VoidCallback unselectNotes;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      tooltip: 'Kategori belirle',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => KategoriSecimDialog(
            filePath: filePath,
            onSaved: unselectNotes,
          ),
        );
      },
      icon: const Icon(TarusIkon.etiket),
    );
  }
}
