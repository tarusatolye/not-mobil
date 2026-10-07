import 'package:flutter/material.dart';
import 'package:saber/components/home/new_note_button.dart';
import 'package:saber/components/navbar/responsive_navbar.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Telefonda yüzen alt çubuk (Pusula Mobil `AppNavigator` alt çubuğu):
/// Hızlı Bakış, Notlar, ortada «+» (yeni not), Beyaz tahta, Ayarlar.
class const HorizontalNavbar({
  super.key,
  final int selectedIndex = 0,
  final ValueChanged<int>? onDestinationSelected,

  /// «+» ile oluşturulan notun klasörü (Notlar sekmesindeki konum).
  final String? klasor,
}) extends StatelessWidget {
  /// Çubuğun kendi yüksekliği (iç boşluk dahil, dış boşluk hariç).
  static const yukseklik = 62.0;

  /// Ortadaki «+» düğmesinin çapı.
  static const ekleCapi = 52.0;

  /// İçeriğin alt çubuğun altında kalmaması için ekranın altında
  /// (güvenli alan hariç) bırakılacak yükseklik.
  static double clearanceHeightOf(BuildContext context) {
    if (ResponsiveNavbar.isLargeScreen) return 0;
    MediaQuery.sizeOf(context); // boyut değişince yeniden hesapla
    return yukseklik + TarusOlcu.altCubukAralik + 10;
  }

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final routes = HomeRoutes.routes;
    final acik = Theme.brightnessOf(context) == Brightness.light;
    final altBosluk = MediaQuery.paddingOf(context).bottom;

    Widget sekme(int i) => Expanded(
      child: _Sekme(
        route: routes[i],
        secili: i == selectedIndex,
        onTap: () => onDestinationSelected?.call(i),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        TarusOlcu.sayfaYatay,
        TarusOlcu.altCubukAralik,
        TarusOlcu.sayfaYatay,
        (altBosluk > 0 ? altBosluk : 10) + 4,
      ),
      child: Container(
        height: yukseklik,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: r.barBg,
          borderRadius: BorderRadius.circular(TarusOlcu.rAltCubuk),
          border: Border.all(color: r.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: acik ? 0.10 : 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Semantics(
          explicitChildNodes: true,
          container: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sekme(0),
              sekme(1),
              Expanded(
                child: OverflowBox(
                  maxHeight: yukseklik + 40,
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(0, -14),
                    child: YeniNotDugmesi(klasor: klasor),
                  ),
                ),
              ),
              sekme(2),
              sekme(3),
            ],
          ),
        ),
      ),
    );
  }
}

class const _Sekme({
  required final HomeRoute route,
  required final bool secili,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final renk = secili ? r.accent : r.muted;
    final radius = BorderRadius.circular(22);
    return MergeSemantics(
      child: Semantics(
        selected: secili,
        button: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: secili ? null : onTap,
            borderRadius: radius,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                // Pusula Mobil: `${accent}18`
                color: secili
                    ? r.accent.withValues(alpha: 0x18 / 0xFF)
                    : Colors.transparent,
                borderRadius: radius,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(route.ikon, size: 21, color: renk),
                  const SizedBox(height: 3),
                  Text(
                    route.label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.1,
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
