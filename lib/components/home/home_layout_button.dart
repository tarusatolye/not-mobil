import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:stow_codecs/stow_codecs.dart';

class const HomeLayoutButton({super.key}) extends HookWidget {
  void _openDialog(BuildContext context) async {
    final selection = await showDialog<HomeLayout>(
      context: context,
      builder: (context) => _HomeLayoutDialog(selected: stows.homeLayout.value),
    );
    if (selection == null) return;
    stows.homeLayout.value = selection;
  }

  @override
  Widget build(BuildContext context) {
    final homeLayout = useValueListenable(stows.homeLayout);
    return IconButton(
      padding: const .all(4),
      constraints: const BoxConstraints(
        minWidth: kMinInteractiveDimension,
        minHeight: kMinInteractiveDimension,
      ),
      onPressed: () => _openDialog(context),
      icon: homeLayout.icon,
    );
  }
}

class _HomeLayoutDialog extends StatelessWidget {
  const new({required this.selected});

  final HomeLayout selected;

  @override
  Widget build(BuildContext context) {
    return TarusDialog(
      title: Text(t.home.layout.layout),
      genislik: 340,
      content: Column(
        mainAxisSize: .min,
        children: [
          for (final option in HomeLayout.values)
            _HomeLayoutDialogOption(
              homeLayout: option,
              selected: option == selected,
            ),
        ],
      ),
    );
  }
}

class _HomeLayoutDialogOption extends StatelessWidget {
  const new({required this.homeLayout, required this.selected});

  final HomeLayout homeLayout;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(TarusOlcu.rMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(TarusOlcu.rMd),
          onTap: () {
            context.pop(homeLayout);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: selected ? r.accent : r.muted2,
                    size: 20,
                  ),
                  child: homeLayout.icon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    switch (homeLayout) {
                      .masonryGrid => t.home.layout.masonryGrid,
                      .simpleGrid => t.home.layout.simpleGrid,
                    },
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? r.accent : r.text,
                    ),
                  ),
                ),
                if (selected) Icon(TarusIkon.tamam, size: 18, color: r.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum HomeLayout({
  /// Whether the preview card should fill its available vertical space
  required final bool fillVertical,
}) {
  masonryGrid(fillVertical: false),
  simpleGrid(fillVertical: true);

  static const codec = EnumCodec(values);

  Widget get icon => switch (this) {
    .masonryGrid => const Icon(TarusIkon.duzenDuvar),
    .simpleGrid => const Icon(TarusIkon.duzenIzgara),
  };
}
