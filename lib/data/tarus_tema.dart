import 'package:flutter/material.dart';

/// tarus 8 kanonik tema (STANDARTLAR §9 Seçenek 3).
///
/// Kimlik, ad ve sıra: `tarus-kabuk/components/TemaSecici.tsx` (`TEMALAR`);
/// renkler: `tarus-kabuk/css/tarus.css`. Değerler oradan birebir alınır,
/// burada elle seçilmez. Tema yalnız uygulama kabuğunu boyar; not sayfasının
/// kendisi Saber'in karanlık mod kuralıyla çizilir.
class TarusTema {
  const new({
    required this.id,
    required this.ad,
    required this.aciklama,
    required this.acik,
    required this.bg,
    required this.surface,
    required this.card,
    required this.text,
    required this.muted2,
    required this.muted,
    required this.accent,
    required this.border,
    required this.danger,
  });

  final String id;
  final String ad;
  final String aciklama;

  /// Açık (light) tema mı.
  final bool acik;
  final Color bg, surface, card, text, muted2, muted, accent, border, danger;

  Brightness get parlaklik => acik ? Brightness.light : Brightness.dark;

  /// Material 3 renk şeması: vurgu `--accent`, yüzeyler tarus token'ları.
  ColorScheme get renkSemasi {
    final temel = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: parlaklik,
    );
    return temel.copyWith(
      primary: accent,
      onPrimary: Colors.white,
      error: danger,
      surface: bg,
      onSurface: text,
      onSurfaceVariant: muted2,
      surfaceContainerLowest: bg,
      surfaceContainerLow: surface,
      surfaceContainer: card,
      surfaceContainerHigh: card,
      surfaceContainerHighest: Color.alphaBlend(border, card),
      surfaceTint: accent,
      outline: muted,
      outlineVariant: border,
    );
  }

  /// Kimliği bilinmiyorsa null (boş = sistem).
  static TarusTema? bul(String id) {
    for (final t in hepsi) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Varsayılan tema kimliği: kayıt yokken Modern (kullanıcı kararı
  /// 2026-10-04; web ve `tarus-kabuk/mobil` `VARSAYILAN_TEMA` ile aynı).
  static const varsayilanId = 'modern';

  /// Kayıt yokken ya da kimlik bilinmiyorsa kullanılan tema (Modern Işık).
  static TarusTema get varsayilan => bul(varsayilanId)!;

  /// Kayıtlı kimliği temaya çevirir; boş ya da bilinmeyen kimlik Modern olur.
  static TarusTema coz(String id) => bul(id) ?? varsayilan;

  static const hepsi = <TarusTema>[
    TarusTema(
      id: 'modern',
      ad: 'Modern Işık',
      aciklama: 'Açık slate zemin + beyaz kart.',
      acik: true,
      bg: Color(0xFFF1F5F9),
      surface: Color(0xFFE2E8F0),
      card: Color(0xFFFFFFFF),
      text: Color(0xFF0F172A),
      muted2: Color(0xFF475569),
      muted: Color(0xFF64748B),
      accent: Color(0xFF2563EB),
      border: Color(0x1A0F172A),
      danger: Color(0xFFEF4444),
    ),
    TarusTema(
      id: 'sage',
      ad: 'Adaçayı',
      aciklama: 'Sakin adaçayı yeşili açık yüzeyler.',
      acik: true,
      bg: Color(0xFFF3F7F4),
      surface: Color(0xFFE5EEE8),
      card: Color(0xFFFBFDFB),
      text: Color(0xFF17231B),
      muted2: Color(0xFF4D6355),
      muted: Color(0xFF687D6E),
      accent: Color(0xFF287B52),
      border: Color(0x1A1B432D),
      danger: Color(0xFFC2413C),
    ),
    TarusTema(
      id: 'karanlik',
      ad: 'Karanlık',
      aciklama: 'Nötr siyah zemin + mavi vurgu.',
      acik: false,
      bg: Color(0xFF050505),
      surface: Color(0xFF080808),
      card: Color(0xFF111111),
      text: Color(0xFFF3F4F6),
      muted2: Color(0xFFB8BCC4),
      muted: Color(0xFF8A8AAA),
      accent: Color(0xFF2563EB),
      border: Color(0x12FFFFFF),
      danger: Color(0xFFEF4444),
    ),
    TarusTema(
      id: 'ocean',
      ad: 'Okyanus',
      aciklama: 'Derin okyanus laciverti + gök mavisi.',
      acik: false,
      bg: Color(0xFF0F172A),
      surface: Color(0xFF080C16),
      card: Color(0xFF1E293B),
      text: Color(0xFFF1F5F9),
      muted2: Color(0xFFC5D2E0),
      muted: Color(0xFF94A3B8),
      accent: Color(0xFF3B82F6),
      border: Color(0x2E94A3B8),
      danger: Color(0xFFEF4444),
    ),
    TarusTema(
      id: 'sand',
      ad: 'Kahve',
      aciklama: 'Sıcak kağıt beji + terracotta.',
      acik: true,
      bg: Color(0xFFF4ECE0),
      surface: Color(0xFFE7DBC9),
      card: Color(0xFFFDF8F0),
      text: Color(0xFF2B221A),
      muted2: Color(0xFF6F5C46),
      muted: Color(0xFF97836A),
      accent: Color(0xFFB45309),
      border: Color(0x2E785537),
      danger: Color(0xFFB91C1C),
    ),
    TarusTema(
      id: 'sunset',
      ad: 'Günbatımı',
      aciklama: 'Kömür kızılı + alev turuncusu.',
      acik: false,
      bg: Color(0xFF16100D),
      surface: Color(0xFF1E1613),
      card: Color(0xFF261D18),
      text: Color(0xFFF3EBE5),
      muted2: Color(0xFFC6B4A9),
      muted: Color(0xFF9A887D),
      accent: Color(0xFFEA580C),
      border: Color(0x29D6C6BC),
      danger: Color(0xFFF43F5E),
    ),
    TarusTema(
      id: 'forest',
      ad: 'Orman',
      aciklama: 'Derin orman yeşili + zümrüt vurgu.',
      acik: false,
      bg: Color(0xFF0B1310),
      surface: Color(0xFF0F1A16),
      card: Color(0xFF16241E),
      text: Color(0xFFE9EFEC),
      muted2: Color(0xFFB0C2B8),
      muted: Color(0xFF859A8F),
      accent: Color(0xFF059669),
      border: Color(0x29B4C8BE),
      danger: Color(0xFFF87171),
    ),
    TarusTema(
      id: 'violet',
      ad: 'Menekşe',
      aciklama: 'Gece moru + fuşya ışıltısı.',
      acik: false,
      bg: Color(0xFF0F0518),
      surface: Color(0xFF1A0A2E),
      card: Color(0xFF2A1248),
      text: Color(0xFFFDF4FF),
      muted2: Color(0xFFE9D5FF),
      muted: Color(0xFFC084FC),
      accent: Color(0xFFD946EF),
      border: Color(0x4DE879F9),
      danger: Color(0xFFFB7185),
    ),
  ];
}
