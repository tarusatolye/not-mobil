import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:saber/components/files/file_tree.dart';
import 'package:saber/components/home/new_note_button.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Tablette kenar rayı: Not işareti, «+», dört sekme; alttaki düğme
/// klasör ağacını açar (yüzen panel, `--surface` + 1 px kenarlık).
class const VerticalNavbar({
  super.key,
  final int selectedIndex = 0,
  final ValueChanged<int>? onDestinationSelected,
  final String? klasor,
}) extends HookWidget {
  static const genislik = 84.0;
  static const agacGenisligi = 280.0;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final agacAcik = useState(false);
    final routes = HomeRoutes.routes;

    return Padding(
      padding: const EdgeInsets.all(TarusOlcu.aralik),
      child: Container(
        decoration: BoxDecoration(
          color: r.surface,
          borderRadius: BorderRadius.circular(TarusOlcu.rKart),
          border: Border.all(color: r.bdr2),
          boxShadow: r.elev1,
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          right: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: genislik,
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    const TarusNotIsareti(boyut: 36),
                    const SizedBox(height: 16),
                    YeniNotDugmesi(klasor: klasor, cap: 46),
                    const SizedBox(height: 16),
                    for (var i = 0; i < routes.length; i++)
                      _RaySekmesi(
                        route: routes[i],
                        secili: i == selectedIndex,
                        onTap: () => onDestinationSelected?.call(i),
                      ),
                    const Spacer(),
                    TarusIkonDugmesi(
                      ikon: agacAcik.value
                          ? TarusIkon.klasorAcik
                          : TarusIkon.klasor,
                      secili: agacAcik.value,
                      tooltip: 'Klasör ağacı',
                      onPressed: () => agacAcik.value = !agacAcik.value,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: AlignmentDirectional.centerStart,
                child: agacAcik.value
                    ? Container(
                        width: agacGenisligi,
                        decoration: BoxDecoration(
                          border: BorderDirectional(
                            start: BorderSide(color: r.bdr1),
                          ),
                        ),
                        child: const FileTree(),
                      )
                    : const SizedBox(width: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _RaySekmesi({
  required final HomeRoute route,
  required final bool secili,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final renk = secili ? r.accent : r.muted;
    final radius = BorderRadius.circular(TarusOlcu.rLg);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Semantics(
        selected: secili,
        button: true,
        label: route.label,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: secili ? null : onTap,
            borderRadius: radius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: TarusSecim.zemin(r, secili),
                borderRadius: radius,
                border: Border.all(
                  color: secili
                      ? r.accent.withValues(alpha: TarusOlcu.seciliKenarAlfa)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                children: [
                  Icon(route.ikon, size: 21, color: renk),
                  const SizedBox(height: 4),
                  Text(
                    route.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                      color: renk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
