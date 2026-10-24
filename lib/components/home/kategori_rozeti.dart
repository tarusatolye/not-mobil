import 'package:flutter/material.dart';
import 'package:saber/tarus/kategori.dart';

/// Not kartlarında ve detaylarda kategoriyi gösteren standart rozet
/// (Web `KategoriRozeti.tsx` ve STANDARTLAR §9 «Kategorik renkler» karşılığı).
class KategoriRozeti extends StatelessWidget {
  const new({
    super.key,
    this.bilgi,
    this.filePath,
  }) : assert(bilgi != null || filePath != null, 'bilgi veya filePath sağlanmalıdır');

  final NotKategoriBilgisi? bilgi;
  final String? filePath;

  @override
  Widget build(BuildContext context) {
    final effectiveBilgi = bilgi ?? (filePath != null ? notKategorisiAl(filePath!) : const NotKategoriBilgisi(kategori: NotKategorisi.ozel));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final renk = KategoriRenkleri.renk(effectiveBilgi.kategori, isDark: isDark);
    final ikon = kategoriIkonu(effectiveBilgi.kategori);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: renk.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ikon,
            size: 11,
            color: renk,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              effectiveBilgi.etiket,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: renk,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
