import 'package:flutter/material.dart';
import 'package:saber/components/home/delete_note_button.dart';
import 'package:saber/components/home/export_note_button.dart';
import 'package:saber/components/home/move_note_button.dart';
import 'package:saber/components/home/rename_note_button.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Not seçiliyken altta beliren yüzen eylem kartı: seçim sayısı,
/// yeniden adlandır (tek not), taşı, sil, dışa aktar ve seçimi kaldır.
class const SecimCubugu({
  super.key,
  required final ValueNotifier<List<String>> selectedFiles,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final secili = selectedFiles.value;
    void birak() => selectedFiles.value = [];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TarusOlcu.sayfaYatay,
          0,
          TarusOlcu.sayfaYatay,
          TarusOlcu.aralik,
        ),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: r.modalBg,
            borderRadius: BorderRadius.circular(TarusOlcu.rHero),
            border: Border.all(
              color: r.accent.withValues(alpha: TarusOlcu.seciliKenarAlfa),
            ),
            boxShadow: r.elev2,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: birak,
                icon: const Icon(TarusIkon.kapat),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${secili.length} seçili',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: r.text,
                  ),
                ),
              ),
              if (secili.length == 1)
                RenameNoteButton(
                  existingPath: secili.first,
                  unselectNotes: birak,
                ),
              MoveNoteButton(filesToMove: secili, unselectNotes: birak),
              ExportNoteButton(selectedFiles: secili),
              DeleteNoteButton(filesToDelete: secili, unselectNotes: birak),
            ],
          ),
        ),
      ),
    );
  }
}
