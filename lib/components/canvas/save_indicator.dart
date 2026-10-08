import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saber/data/is_this_a_test.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Replaces the back button as the
/// [AppBar.leading] widget in the [AppBar]
/// to indicate the state of saving in the editor.
class SaveIndicator extends StatelessWidget {
  const new({super.key, required this.savingState, required this.triggerSave});

  final ValueNotifier<SavingState> savingState;
  final VoidCallback triggerSave;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final yerel = MaterialLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: savingState,
      builder: (context, isSaving, _) {
        return AnimatedSwitcher(
          duration: isThisATest
              ? Duration.zero
              : const Duration(milliseconds: 300),
          child: IconButton(
            key: ValueKey(savingState.value),
            onPressed: () => _onPressed(context),
            // Kaydedilmemiş değişiklik vurgu renginde kaydet ikonu,
            // kaydedilirken ikon boyunda çark, kaydedilince geri oku.
            tooltip: switch (savingState.value) {
              .waitingToSave => yerel.saveButtonLabel,
              .saving => null,
              .saved => yerel.backButtonTooltip,
            },
            icon: switch (savingState.value) {
              .waitingToSave => Icon(TarusIkon.kaydet, color: r.accent),
              .saving => SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: r.accent,
                ),
              ),
              .saved => const Icon(TarusIkon.geri),
            },
          ),
        );
      },
    );
  }

  void _onPressed(BuildContext context) {
    switch (savingState.value) {
      case .waitingToSave:
        triggerSave();
      case .saving:
        break;
      case .saved:
        _back(context);
    }
  }

  void _back(BuildContext context) {
    final navigator = Navigator.of(context);
    final isWhiteboard = !navigator.canPop();
    if (isWhiteboard) {
      // if on whiteboard, go to "recents" tab of home screen
      context.go(HomeRoutes.routes[0].path);
    } else {
      navigator.pop();
    }
  }
}

enum SavingState { waitingToSave, saving, saved }
