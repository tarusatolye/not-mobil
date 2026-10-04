import 'package:flutter/material.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tarus_tema.dart';

/// Ayarlar → Tema: tarus 8 kanonik tema. Web'deki ortak `TemaSecici` ve
/// `tarus-kabuk/mobil` `TEMALAR` ile aynı kimlik, ad ve sıra; kayıt yokken
/// Modern seçili (kullanıcı kararı 2026-10-04).
class TarusTemaSecici extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: stows.tarusTema,
      builder: (context, kayit, _) {
        final secili = TarusTema.coz(kayit).id;
        return Padding(
          padding: const .symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text('Tema', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in TarusTema.hepsi)
                    _TemaKarti(
                      ad: t.ad,
                      aciklama: t.aciklama,
                      tema: t,
                      secili: secili == t.id,
                      onSec: () => stows.tarusTema.value = t.id,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TemaKarti extends StatelessWidget {
  const new({
    required this.ad,
    required this.aciklama,
    required this.tema,
    required this.secili,
    required this.onSec,
  });

  final String ad, aciklama;
  final TarusTema tema;
  final bool secili;
  final VoidCallback onSec;

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    return Tooltip(
      message: aciklama,
      child: InkWell(
        onTap: onSec,
        borderRadius: .circular(12),
        child: Container(
          width: 104,
          padding: const .all(8),
          decoration: BoxDecoration(
            borderRadius: .circular(12),
            border: Border.all(
              color: secili ? renk.primary : renk.outlineVariant,
              width: secili ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              ClipRRect(
                borderRadius: .circular(6),
                child: SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: _Onizleme(tema),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ad,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: .w600),
                    ),
                  ),
                  if (secili)
                    Icon(Icons.check_circle, size: 14, color: renk.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Onizleme extends StatelessWidget {
  const new(this.tema);
  final TarusTema tema;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: tema.bg,
      child: Padding(
        padding: const .all(6),
        child: Container(
          decoration: BoxDecoration(
            color: tema.card,
            borderRadius: .circular(4),
          ),
          alignment: .bottomRight,
          padding: const .all(4),
          child: CircleAvatar(radius: 4, backgroundColor: tema.accent),
        ),
      ),
    );
  }
}
