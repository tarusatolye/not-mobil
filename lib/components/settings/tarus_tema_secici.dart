import 'package:flutter/material.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tarus_tema.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// Ayarlar → Tema: tarus 8 kanonik tema, 3 sütunlu ızgara (STANDARTLAR
/// §9 «Ayarlar Tema Kartları Standart Düzeni»). Web'deki ortak `TemaSecici`
/// ve `tarus-kabuk/mobil` `TEMALAR` ile aynı kimlik, ad ve sıra; kayıt
/// yokken Modern seçili (kullanıcı kararı 2026-10-04).
class TarusTemaSecici extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: stows.tarusTema,
      builder: (context, kayit, _) {
        final secili = TarusTema.coz(kayit).id;
        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: TarusOlcu.aralik,
          crossAxisSpacing: TarusOlcu.aralik,
          childAspectRatio: 1.12,
          children: [
            for (final t in TarusTema.hepsi)
              _TemaKarti(
                tema: t,
                secili: secili == t.id,
                onSec: () => stows.tarusTema.value = t.id,
              ),
          ],
        );
      },
    );
  }
}

class const _TemaKarti({
  required final TarusTema tema,
  required final bool secili,
  required final VoidCallback onSec,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final radius = BorderRadius.circular(TarusOlcu.rLg);
    return Tooltip(
      message: tema.aciklama,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: secili,
        label: tema.ad,
        excludeSemantics: true,
        child: Material(
          color: r.card,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: secili
                  ? r.accent.withValues(alpha: TarusOlcu.seciliKenarAlfa)
                  : r.border,
              width: secili ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onSec,
            child: Ink(
              color: secili
                  ? r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa)
                  : null,
              padding: const EdgeInsets.all(7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(TarusOlcu.rSm),
                      child: _Onizleme(tema),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tema.ad,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secili ? r.accent : r.text,
                          ),
                        ),
                      ),
                      if (secili)
                        Icon(TarusIkon.seciliDaire, size: 14, color: r.accent),
                    ],
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

/// Küçük önizleme: tema zemini, kart ve vurgu çizgisi (renkler token'dan).
class _Onizleme extends StatelessWidget {
  const new(this.tema);
  final TarusTema tema;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.tema(tema.id);
    return ColoredBox(
      color: r.bg,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: r.card,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: r.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.7,
                  child: Container(
                    height: 3,
                    color: r.text.withValues(alpha: 0.7),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.45,
                  child: Container(height: 3, color: r.muted),
                ),
                Container(
                  height: 6,
                  width: 22,
                  decoration: BoxDecoration(
                    color: r.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
