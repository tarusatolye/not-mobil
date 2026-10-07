import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/data/editor/editor_exporter.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';

class ExportNoteButton extends StatefulWidget {
  const new({super.key, required this.selectedFiles});

  final List<String> selectedFiles;

  @override
  State<ExportNoteButton> createState() => _ExportNoteButtonState();
}

class _ExportNoteButtonState extends State<ExportNoteButton> {
  var _currentlyExporting = false;

  Future exportFile(List<String> selectedFiles, bool exportPdf) async {
    setState(() => _currentlyExporting = true);

    final files = <ArchiveFile>[];
    for (final filePath in selectedFiles) {
      final coreInfo = await EditorCoreInfo.loadFromFilePath(filePath);
      if (!mounted) break;

      final fileNameWithoutExtension = coreInfo.filePath.substring(
        coreInfo.filePath.lastIndexOf('/') + 1,
      );

      if (exportPdf) {
        final pdfDoc = await EditorExporter.generatePdf(coreInfo, context);
        final pdfBytes = await pdfDoc.save();
        files.add(
          ArchiveFile(
            '$fileNameWithoutExtension.pdf',
            pdfBytes.length,
            pdfBytes,
          ),
        );
      } else {
        final sba = await coreInfo.saveToSba(currentPageIndex: null);
        files.add(
          ArchiveFile('$fileNameWithoutExtension.sba', sba.length, sba),
        );
      }
    }

    if (!mounted) return;
    if (selectedFiles.length == 1) {
      await FileManager.exportFile(
        files.single.name,
        files.single.content,
        context: context,
      );
    } else if (selectedFiles.length > 1) {
      final archive = Archive();
      for (final archiveFile in files) {
        archive.addFile(archiveFile);
      }
      await FileManager.exportFile(
        '${files.first.name}.zip',
        Uint8List.fromList(ZipEncoder().encode(archive)),
        context: context,
      );
    }

    setState(() => _currentlyExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentlyExporting) {
      return const SizedBox.square(
        dimension: 40,
        child: Center(child: TarusMetinCarki()),
      );
    }
    return PopupMenuButton<bool>(
      tooltip: t.home.tooltips.exportNote,
      icon: const Icon(TarusIkon.disaAktar),
      onSelected: (pdf) => exportFile(widget.selectedFiles, pdf),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: true,
          child: Row(
            children: [
              Icon(TarusIkon.kagit, size: 18),
              SizedBox(width: 10),
              Text('PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: false,
          child: Row(
            children: [
              Icon(TarusIkon.not, size: 18),
              SizedBox(width: 10),
              Text('SBA'),
            ],
          ),
        ),
      ],
    );
  }
}
