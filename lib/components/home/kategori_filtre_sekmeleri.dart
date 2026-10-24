import 'package:flutter/material.dart';
import 'package:saber/tarus/kategori.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Notlar listesinde kategorilere göre süzme yapan sekme çubuğu
/// (STANDARTLAR-MOBIL.md §7 «Sayfa Sekmeleri / Segmented Control»).
class KategoriFiltreSekmeleri extends StatelessWidget {
  const new({
    super.key,
    required this.seciliKategori,
    required this.onKategoriDegisti,
    required this.toplamSayi,
    required this.ozelSayisi,
    required this.sirketSayisi,
    required this.projeSayisi,
  });

  final NotKategorisi? seciliKategori;
  final ValueChanged<NotKategorisi?> onKategoriDegisti;
  final int toplamSayi;
  final int ozelSayisi;
  final int sirketSayisi;
  final int projeSayisi;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sekmeler = <(NotKategorisi?, String, int, Color?)>[
      (null, 'Tümü', toplamSayi, null),
      (NotKategorisi.ozel, 'Özel', ozelSayisi, KategoriRenkleri.renk(NotKategorisi.ozel, isDark: isDark)),
      (NotKategorisi.sirket, 'Şirket İçi', sirketSayisi, KategoriRenkleri.renk(NotKategorisi.sirket, isDark: isDark)),
      (NotKategorisi.proje, 'Proje', projeSayisi, KategoriRenkleri.renk(NotKategorisi.proje, isDark: isDark)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: TarusOlcu.sayfaYatay, vertical: 6),
      child: Row(
        children: [
          for (final (kategori, baslik, sayi, katRenk) in sekmeler)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _SekmePill(
                baslik: baslik,
                sayi: sayi,
                secili: seciliKategori == kategori,
                renk: katRenk,
                onTap: () => onKategoriDegisti(kategori),
                r: r,
              ),
            ),
        ],
      ),
    );
  }
}

class _SekmePill extends StatelessWidget {
  const new({
    required this.baslik,
    required this.sayi,
    required this.secili,
    required this.renk,
    required this.onTap,
    required this.r,
  });

  final String baslik;
  final int sayi;
  final bool secili;
  final Color? renk;
  final VoidCallback onTap;
  final TarusRenkler r;

  @override
  Widget build(BuildContext context) {
    final vurgu = renk ?? r.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TarusOlcu.rHap),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: secili
                ? vurgu.withValues(alpha: TarusOlcu.seciliZeminAlfa)
                : r.card,
            borderRadius: BorderRadius.circular(TarusOlcu.rHap),
            border: Border.all(
              color: secili
                  ? vurgu.withValues(alpha: TarusOlcu.seciliKenarAlfa)
                  : r.bdr1,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                baslik,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                  color: secili ? (renk ?? r.accent) : r.text,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: secili
                      ? vurgu.withValues(alpha: 0.20)
                      : r.ovl2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$sayi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: secili ? (renk ?? r.accent) : r.muted2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
