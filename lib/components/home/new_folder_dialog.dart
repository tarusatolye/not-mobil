import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';

class NewFolderDialog extends StatefulWidget {
  const new({
    super.key,
    required this.createFolder,
    required this.doesFolderExist,
  });

  final void Function(String) createFolder;
  final bool Function(String) doesFolderExist;

  @override
  State<NewFolderDialog> createState() => _NewFolderDialogState();
}

class _NewFolderDialogState extends State<NewFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  String? validateFolderName(String? folderName) {
    if (folderName == null || folderName.isEmpty) {
      return t.home.newFolder.folderNameEmpty;
    }
    folderName = reformatFolderName(folderName);
    if (folderName.contains('/') || folderName.contains('\\')) {
      return t.home.newFolder.folderNameContainsSlash;
    }
    if (widget.doesFolderExist(folderName)) {
      return t.home.newFolder.folderNameExists;
    }
    return null;
  }

  String reformatFolderName(String folderName) => folderName.trim();

  @override
  Widget build(BuildContext context) {
    return TarusDialog(
      title: Text(t.home.newFolder.newFolder),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: TarusMetinAlani(
          controller: _controller,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          focusOrder: const NumericFocusOrder(1),
          placeholder: t.home.newFolder.folderName,
          prefixIcon: const Icon(TarusIkon.yeniKlasor),
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
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final folderName = reformatFolderName(_controller.text);
            widget.createFolder(folderName);
            Navigator.of(context).pop();
          },
          child: Text(t.home.newFolder.create),
        ),
      ],
    );
  }
}
