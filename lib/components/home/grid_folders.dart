import 'package:flutter/material.dart';
import 'package:saber/components/home/delete_folder_button.dart';
import 'package:saber/components/home/rename_folder_button.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Notlar sekmesindeki klasör kartları (tarus kartı, 56 px satır):
/// dokununca klasöre girer, sağdaki menüden yeniden adlandırılır ya da
/// silinir. Üst klasöre dönüş ve yeni klasör konum çubuğunda/başlıktadır.
class GridFolders extends StatelessWidget {
  const new({
    super.key,
    required this.onTap,
    required this.crossAxisCount,
    required this.renameFolder,
    required this.isFolderEmpty,
    required this.deleteFolder,
    required this.doesFolderExist,
    required this.folders,
  });

  final Function(String) onTap;
  final int crossAxisCount;

  final bool Function(String) doesFolderExist;
  final Future<void> Function(String oldName, String newName) renameFolder;
  final Future<bool> Function(String) isFolderEmpty;
  final Future<void> Function(String) deleteFolder;

  final List<String> folders;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: TarusOlcu.sayfaYatay),
      sliver: SliverGrid.builder(
        itemCount: folders.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: TarusOlcu.aralik,
          crossAxisSpacing: TarusOlcu.aralik,
          mainAxisExtent: 56,
        ),
        itemBuilder: (context, index) => _KlasorKarti(
          ad: folders[index],
          onTap: () => onTap(folders[index]),
          doesFolderExist: doesFolderExist,
          renameFolder: renameFolder,
          isFolderEmpty: isFolderEmpty,
          deleteFolder: deleteFolder,
        ),
      ),
    );
  }
}

enum _KlasorEylemi { adlandir, sil }

class const _KlasorKarti({
  required final String ad,
  required final VoidCallback onTap,
  required final bool Function(String) doesFolderExist,
  required final Future<void> Function(String oldName, String newName)
  renameFolder,
  required final Future<bool> Function(String) isFolderEmpty,
  required final Future<void> Function(String) deleteFolder,
}) extends StatelessWidget {
  Future<void> _menu(BuildContext context, _KlasorEylemi eylem) async {
    switch (eylem) {
      case .adlandir:
        await RenameFolderButton.dialogAc(
          context,
          folderName: ad,
          doesFolderExist: doesFolderExist,
          renameFolder: (yeni) => renameFolder(ad, yeni),
        );
      case .sil:
        await DeleteFolderButton.dialogAc(
          context,
          folderName: ad,
          deleteFolder: deleteFolder,
          isFolderEmpty: isFolderEmpty,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return TarusKart(
      onTap: onTap,
      padding: const EdgeInsets.only(left: 10, right: 2),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa),
              borderRadius: BorderRadius.circular(TarusOlcu.rMd),
            ),
            child: Icon(TarusIkon.klasor, size: 18, color: r.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ad,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: r.text,
              ),
            ),
          ),
          PopupMenuButton<_KlasorEylemi>(
            tooltip: t.tarus.klasorIslemleri,
            icon: const Icon(TarusIkon.dahaFazla, size: 18),
            onSelected: (e) => _menu(context, e),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: .adlandir,
                child: _MenuSatiri(
                  ikon: TarusIkon.yenidenAdlandir,
                  metin: t.home.renameFolder.renameFolder,
                ),
              ),
              PopupMenuItem(
                value: .sil,
                child: _MenuSatiri(
                  ikon: TarusIkon.sil,
                  metin: t.home.deleteFolder.deleteFolder,
                  renk: r.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class const _MenuSatiri({
  required final IconData ikon,
  required final String metin,
  final Color? renk,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return Row(
      children: [
        Icon(ikon, size: 18, color: renk ?? r.muted2),
        const SizedBox(width: 10),
        Text(metin, style: TextStyle(color: renk ?? r.text)),
      ],
    );
  }
}
