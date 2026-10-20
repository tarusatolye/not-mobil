import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/pages/editor/editor.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Ortadaki «+» (Pusula Mobil hızlı ekle): dokununca «Yeni not» ve
/// «Not içeri aktar» seçeneklerini ortalı pencerede açar. Saber'in açılır
/// SpeedDial düğmesinin yerine.
class const YeniNotDugmesi({
  super.key,

  /// Yeni notun oluşturulacağı klasör; null ise kök.
  final String? klasor,
  final double cap = 52,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return Tooltip(
      message: t.home.tooltips.newNote,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: t.home.tooltips.newNote,
        child: Material(
          color: r.accent,
          shape: CircleBorder(side: BorderSide(color: r.bg, width: 4)),
          elevation: 6,
          shadowColor: r.accent.withValues(alpha: 0.6),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => menuyuAc(context, klasor),
            child: SizedBox.square(
              dimension: cap,
              child: const Icon(TarusIkon.ekle, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  /// «Oluştur» penceresi: ortalı, iki sütunlu seçenek ızgarası (Arkiv eylem
  /// menüsü). Alttan açılan sayfa kullanılmaz (ekosistem standardı).
  static Future<void> menuyuAc(BuildContext context, String? klasor) {
    return showDialog<void>(
      context: context,
      builder: (pencere) {
        final r = TarusRenkler.of(pencere);
        return TarusDialog(
          title: Text(t.tarus.olustur),
          genislik: 420,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TarusSecenekDugmesi(
                      ikon: TarusIkon.yeniNot,
                      etiket: t.home.create.newNote,
                      onTap: () {
                        Navigator.of(pencere).pop();
                        yeniNot(context, klasor);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TarusSecenekDugmesi(
                      ikon: TarusIkon.notIceAktar,
                      etiket: t.home.create.importNote,
                      onTap: () {
                        Navigator.of(pencere).pop();
                        iceAktar(context, klasor);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${t.home.create.importNote}: .sbn2, .sbn, .sba, .pdf',
                style: TextStyle(fontSize: 11.5, color: r.muted),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> yeniNot(BuildContext context, String? klasor) async {
    if (klasor == null || klasor.isEmpty || klasor == '/') {
      await context.push(RoutePaths.edit);
    } else {
      final yol = await FileManager.newFilePath('$klasor/');
      if (!context.mounted) return;
      await context.push(RoutePaths.editFilePath(yol));
    }
  }

  static Future<void> iceAktar(BuildContext context, String? klasor) async {
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return;

    final filePath = file.path;
    final fileName = file.name;
    if (filePath == null) return;
    final kucuk = filePath.toLowerCase();

    if (kucuk.endsWith('.sbn') ||
        kucuk.endsWith('.sbn2') ||
        kucuk.endsWith('.sba')) {
      final path = await FileManager.importFile(filePath, '${klasor ?? ''}/');
      if (path == null) return;
      if (!context.mounted) return;
      await context.push(RoutePaths.editFilePath(path));
    } else if (kucuk.endsWith('.pdf')) {
      if (!Editor.canRasterPdf) return;
      final adi = fileName.substring(0, fileName.length - '.pdf'.length);
      final sbnFilePath = await FileManager.suffixFilePathToMakeItUnique(
        '${klasor ?? ''}/$adi',
      );
      if (!context.mounted) return;
      await context.push(RoutePaths.editImportPdf(sbnFilePath, filePath));
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.home.invalidFormat)));
      }
      throw 'Invalid file type';
    }
  }
}
