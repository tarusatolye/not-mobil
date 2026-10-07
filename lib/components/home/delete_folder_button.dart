import 'package:flutter/material.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';

class DeleteFolderButton extends StatelessWidget {
  const new({
    super.key,
    required this.folderName,
    required this.deleteFolder,
    required this.isFolderEmpty,
  });

  final String folderName;
  final Future<void> Function(String) deleteFolder;
  final Future<bool> Function(String) isFolderEmpty;

  /// Klasör silme penceresi (klasör kartının menüsünden).
  static Future<void> dialogAc(
    BuildContext context, {
    required String folderName,
    required Future<void> Function(String) deleteFolder,
    required Future<bool> Function(String) isFolderEmpty,
  }) => showDialog(
    context: context,
    builder: (context) => _DeleteFolderDialog(
      folderName: folderName,
      deleteFolder: deleteFolder,
      isFolderEmpty: isFolderEmpty,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: .zero,
      tooltip: t.home.deleteFolder.deleteFolder,
      onPressed: () => dialogAc(
        context,
        folderName: folderName,
        deleteFolder: deleteFolder,
        isFolderEmpty: isFolderEmpty,
      ),
      icon: const Icon(TarusIkon.sil),
    );
  }
}

class _DeleteFolderDialog extends StatefulWidget {
  const new({
    required this.folderName,
    required this.deleteFolder,
    required this.isFolderEmpty,
  });

  final String folderName;
  final Future<void> Function(String) deleteFolder;
  final Future<bool> Function(String) isFolderEmpty;

  @override
  State<_DeleteFolderDialog> createState() => _DeleteFolderDialogState();
}

class _DeleteFolderDialogState extends State<_DeleteFolderDialog> {
  var isFolderEmpty = false;
  var alsoDeleteContents = false;

  @override
  void initState() {
    super.initState();
    checkIfFolderIsEmpty();
  }

  Future<void> checkIfFolderIsEmpty() async {
    isFolderEmpty = await widget.isFolderEmpty(widget.folderName);
    if (isFolderEmpty) alsoDeleteContents = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final deleteAllowed = isFolderEmpty || alsoDeleteContents;
    return TarusDialog(
      title: Text(t.home.deleteFolder.deleteName(f: widget.folderName)),
      content: isFolderEmpty
          ? const SizedBox.shrink()
          : CheckboxListTile(
              value: alsoDeleteContents,
              onChanged: (value) {
                setState(() => alsoDeleteContents = value!);
              },
              controlAffinity: .leading,
              contentPadding: .zero,
              title: Text(t.home.deleteFolder.alsoDeleteContents),
            ),
      actions: [
        TarusDialogDugmesi(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        TarusDialogDugmesi(
          onPressed: deleteAllowed
              ? () async {
                  await widget.deleteFolder(widget.folderName);
                  if (context.mounted) Navigator.of(context).pop();
                }
              : null,
          isDestructiveAction: true,
          child: Text(t.home.deleteFolder.delete),
        ),
      ],
    );
  }
}
