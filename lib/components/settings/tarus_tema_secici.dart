import 'package:flutter/material.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tarus_tema.dart';

/// Ayarlar → Tema: tarus 8 kanonik tema + sistem (Modern Işık / Karanlık).
/// Web'deki ortak `TemaSecici` ile aynı ad ve sıra.
class TarusTemaSecici extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: stows.tarusTema,
      builder: (context, secili, _) {
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
                  _TemaKarti(
                    ad: 'Sistem',
                    aciklama: 'Cihaz moduna göre Modern Işık / Karanlık',
                    ust: TarusTema.sistemAcik,
                    alt: TarusTema.sistemKoyu,
                    secili: secili.isEmpty || TarusTema.bul(secili) == null,
                    onSec: () => stows.tarusTema.value = '',
                  ),
                  for (final t in TarusTema.hepsi)
                    _TemaKarti(
                      ad: t.ad,
                      aciklama: t.aciklama,
                      ust: t,
                      alt: t,
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
    required this.ust,
    required this.alt,
    required this.secili,
    required this.onSec,
  });

  final String ad, aciklama;

  /// Önizlemenin sol (ust) ve sağ (alt) yarısı; sistem kartında iki tema.
  final TarusTema ust, alt;
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
                  child: Row(
                    children: [
                      Expanded(child: _Onizleme(ust)),
                      if (!identical(ust, alt)) Expanded(child: _Onizleme(alt)),
                    ],
                  ),
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
