import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:stow_codecs/stow_codecs.dart';

class const BrowseSortButton({super.key}) extends HookWidget {
  void _openDialog(BuildContext context) async {
    final selection = await showDialog<SortMetric>(
      context: context,
      builder: (context) => _SortDialog(selected: stows.browseSortMetric.value),
    );
    if (selection == null) return;
    stows.browseSortMetric.value = selection;
  }

  @override
  Widget build(BuildContext context) {
    final sortMetric = useValueListenable(stows.browseSortMetric);
    return IconButton(
      padding: const .all(4),
      constraints: const BoxConstraints(
        minWidth: kMinInteractiveDimension,
        minHeight: kMinInteractiveDimension,
      ),
      onPressed: () => _openDialog(context),
      icon: sortMetric.icon,
    );
  }
}

class _SortDialog extends StatelessWidget {
  const new({required this.selected});

  final SortMetric selected;

  @override
  Widget build(BuildContext context) {
    return TarusDialog(
      title: Text(t.home.sort.sortBy),
      genislik: 340,
      content: Column(
        mainAxisSize: .min,
        children: [
          for (final option in SortMetric.values)
            _SortDialogOption(sortMetric: option, selected: option == selected),
        ],
      ),
    );
  }
}

class _SortDialogOption extends StatelessWidget {
  const new({required this.sortMetric, required this.selected});

  final SortMetric sortMetric;
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
            context.pop(sortMetric);
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
                  child: sortMetric.icon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    switch (sortMetric) {
                      .nameAToZ => t.home.sort.nameAToZ,
                      .nameZToA => t.home.sort.nameZToA,
                      .lastModifiedNewToOld => t.home.sort.lastModifiedNewToOld,
                      .lastModifiedOldToNew => t.home.sort.lastModifiedOldToNew,
                    },
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? r.accent : r.text,
                    ),
                  ),
                ),
                if (selected)
                  Icon(TarusIkon.tamam, size: 18, color: r.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum SortMetric {
  nameAToZ,
  nameZToA,
  lastModifiedNewToOld,
  lastModifiedOldToNew;

  static const codec = EnumCodec(values);

  Widget get icon => switch (this) {
    .nameAToZ => const Icon(TarusIkon.siralaAZ),
    .nameZToA => const Icon(TarusIkon.siralaZA),
    .lastModifiedNewToOld => const Icon(TarusIkon.siralaYeni),
    .lastModifiedOldToNew => const Icon(TarusIkon.siralaEski),
  };
}
