import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/pages/editor/editor.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Ortadaki «+» (Pusula Mobil hızlı ekle): dokununca «Yeni not» ve
/// «Not içeri aktar» seçeneklerini alt sayfada açar. Saber'in açılır
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

  /// «Yeni» alt sayfası.
  static Future<void> menuyuAc(BuildContext context, String? klasor) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (sayfa) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  t.tarus.olustur,
                  style: Theme.of(sayfa).textTheme.titleMedium,
                ),
              ),
              _Secenek(
                ikon: TarusIkon.yeniNot,
                baslik: t.home.create.newNote,
                onTap: () {
                  Navigator.of(sayfa).pop();
                  yeniNot(context, klasor);
                },
              ),
              const SizedBox(height: TarusOlcu.aralik),
              _Secenek(
                ikon: TarusIkon.notIceAktar,
                baslik: t.home.create.importNote,
                aciklama: '.sbn2, .sbn, .sba, .pdf',
                onTap: () {
                  Navigator.of(sayfa).pop();
                  iceAktar(context, klasor);
                },
              ),
            ],
          ),
        ),
      ),
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

class const _Secenek({
  required final IconData ikon,
  required final String baslik,
  final String? aciklama,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final radius = BorderRadius.circular(TarusOlcu.rHero);
    return Material(
      color: r.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: r.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: r.accent.withValues(alpha: 0x18 / 0xFF),
                  borderRadius: BorderRadius.circular(TarusOlcu.rLg),
                ),
                child: Icon(ikon, size: 19, color: r.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: r.text,
                      ),
                    ),
                    if (aciklama != null)
                      Text(
                        aciklama!,
                        style: TextStyle(fontSize: 12, color: r.muted),
                      ),
                  ],
                ),
              ),
              Icon(TarusIkon.ileri, size: 16, color: r.muted),
            ],
          ),
        ),
      ),
    );
  }
}
