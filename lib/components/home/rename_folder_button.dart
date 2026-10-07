import 'package:flutter/material.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';

class RenameFolderButton extends StatelessWidget {
  const new({
    super.key,
    required this.folderName,
    required this.doesFolderExist,
    required this.renameFolder,
  });

  final String folderName;
  final bool Function(String) doesFolderExist;
  final Future<void> Function(String newName) renameFolder;

  /// Klasör yeniden adlandırma penceresi (klasör kartının menüsünden).
  static Future<void> dialogAc(
    BuildContext context, {
    required String folderName,
    required bool Function(String) doesFolderExist,
    required Future<void> Function(String newName) renameFolder,
  }) => showDialog(
    context: context,
    builder: (context) => _RenameFolderDialog(
      folderName: folderName,
      doesFolderExist: doesFolderExist,
      renameFolder: renameFolder,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: .zero,
      tooltip: t.home.renameFolder.renameFolder,
      onPressed: () => dialogAc(
        context,
        folderName: folderName,
        doesFolderExist: doesFolderExist,
        renameFolder: renameFolder,
      ),
      icon: const Icon(TarusIkon.yenidenAdlandir),
    );
  }
}

class _RenameFolderDialog extends StatefulWidget {
  const new({
    required this.folderName,
    required this.doesFolderExist,
    required this.renameFolder,
  });

  final String folderName;
  final bool Function(String) doesFolderExist;
  final Future<void> Function(String newName) renameFolder;

  @override
  State<_RenameFolderDialog> createState() => _RenameFolderDialogState();
}

class _RenameFolderDialogState extends State<_RenameFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  String? validateFolderName(String? folderName) {
    if (folderName == null || folderName.isEmpty) {
      return t.home.renameFolder.folderNameEmpty;
    }
    if (folderName.contains('/') || folderName.contains('\\')) {
      return t.home.renameFolder.folderNameContainsSlash;
    }
    if (folderName != widget.folderName && widget.doesFolderExist(folderName)) {
      return t.home.renameFolder.folderNameExists;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.folderName;
  }

  @override
  Widget build(BuildContext context) {
    return TarusDialog(
      title: Text(t.home.renameFolder.renameFolder),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: TarusMetinAlani(
          controller: _controller,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          focusOrder: const NumericFocusOrder(1),
          placeholder: t.home.renameFolder.folderName,
          prefixIcon: const Icon(TarusIkon.klasor),
          validator: validateFolderName,
        ),
      ),
      actions: [
        TarusDialogDugmesi(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(t.common.cancel),
        ),
        TarusDialogDugmesi(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            if (_controller.text != widget.folderName) {
              await widget.renameFolder(_controller.text);
            }
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: Text(t.home.renameFolder.rename),
        ),
      ],
    );
  }
}
