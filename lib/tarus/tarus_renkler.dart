import 'package:flutter/material.dart';

part 'tarus_renkler_veri.dart';

/// tarus kabuk renk token'ları (`ozluk/tarus-kabuk/css/tarus.css`).
///
/// Alan adları kabuktaki CSS değişkenlerinin Dart karşılığıdır:
/// `--card-2` → [card2], `--accent-lt` → [accentLt], `--ovl-3` → [ovl3],
/// `--bdr-2` → [bdr2], `--elev-1` → [elev1]. Değerler
/// `tarus_renkler_veri.dart`'ta CSS'ten üretilir, elle seçilmez.
///
/// Widget'lar renkleri `TarusRenkler.of(context)` ile okur; Material
/// `ColorScheme` yalnız hazır Material bileşenleri içindir.
@immutable
class TarusRenkler extends ThemeExtension<TarusRenkler> {
  const new({
    required this.bg,
    required this.surface,
    required this.card,
    required this.card2,
    required this.border,
    required this.border2,
    required this.text,
    required this.muted2,
    required this.muted,
    required this.accent,
    required this.accentLt,
    required this.success,
    required this.warning,
    required this.danger,
    required this.modalBg,
    required this.inputBg,
    required this.ovl1,
    required this.ovl2,
    required this.ovl3,
    required this.ovl4,
    required this.ovl5,
    required this.bdr1,
    required this.bdr2,
    required this.bdr3,
    required this.elev1,
    required this.elev2,
  });

  /// `--bg`: sayfa zemini.
  final Color bg;

  /// `--surface`: kenar çubuğu ve ikincil yüzey.
  final Color surface;

  /// `--card`: kart yüzeyi.
  final Color card;

  /// `--card-2`: kart içi hafif katman.
  final Color card2;

  /// `--border`, `--border-2`: kart ve ayırıcı kenarlığı.
  final Color border, border2;

  /// `--text`: ana metin.
  final Color text;

  /// `--muted2`: ikincil metin (açıklama, pasif sekme).
  final Color muted2;

  /// `--muted`: soluk metin (meta, ipucu).
  final Color muted;

  /// `--accent`: temanın vurgu rengi.
  final Color accent;

  /// `--accent-lt`: açık vurgu (bağlantı, koyu zeminde vurgu metni).
  final Color accentLt;

  /// `--success`, `--warning`, `--danger`.
  final Color success, warning, danger;

  /// `--modal-bg`: pencere ve alt sayfa yüzeyi.
  final Color modalBg;

  /// `--input-bg`: form alanı zemini.
  final Color inputBg;

  /// `--ovl-1..5`: üst üste binen saydam katmanlar (hover, basılı, iskelet).
  final Color ovl1, ovl2, ovl3, ovl4, ovl5;

  /// `--bdr-1..3`: kademeli kenarlıklar.
  final Color bdr1, bdr2, bdr3;

  /// `--elev-1`, `--elev-2`: yükselti gölgeleri.
  final List<BoxShadow> elev1, elev2;

  /// Pusula Mobil `barBg`: yüzen alt çubuğun zemini (kart rengi, %97 opak).
  Color get barBg => card.withValues(alpha: 0.97);

  /// Kimliği bilinen temanın token'ları; bilinmiyorsa Modern.
  static TarusRenkler tema(String id) =>
      _temaRenkleri[id] ?? _temaRenkleri['modern']!;

  /// Temadaki token'lar; tema uzantısı yoksa (testte çıplak ThemeData)
  /// parlaklığa göre Modern ya da Karanlık.
  static TarusRenkler of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TarusRenkler>() ??
        tema(theme.brightness == Brightness.dark ? 'karanlik' : 'modern');
  }

  @override
  TarusRenkler copyWith({Color? accent}) => TarusRenkler(
    bg: bg,
    surface: surface,
    card: card,
    card2: card2,
    border: border,
    border2: border2,
    text: text,
    muted2: muted2,
    muted: muted,
    accent: accent ?? this.accent,
    accentLt: accentLt,
    success: success,
    warning: warning,
    danger: danger,
    modalBg: modalBg,
    inputBg: inputBg,
    ovl1: ovl1,
    ovl2: ovl2,
    ovl3: ovl3,
    ovl4: ovl4,
    ovl5: ovl5,
    bdr1: bdr1,
    bdr2: bdr2,
    bdr3: bdr3,
    elev1: elev1,
    elev2: elev2,
  );

  @override
  TarusRenkler lerp(TarusRenkler? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return TarusRenkler(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      card: l(card, other.card),
      card2: l(card2, other.card2),
      border: l(border, other.border),
      border2: l(border2, other.border2),
      text: l(text, other.text),
      muted2: l(muted2, other.muted2),
      muted: l(muted, other.muted),
      accent: l(accent, other.accent),
      accentLt: l(accentLt, other.accentLt),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      modalBg: l(modalBg, other.modalBg),
      inputBg: l(inputBg, other.inputBg),
      ovl1: l(ovl1, other.ovl1),
      ovl2: l(ovl2, other.ovl2),
      ovl3: l(ovl3, other.ovl3),
      ovl4: l(ovl4, other.ovl4),
      ovl5: l(ovl5, other.ovl5),
      bdr1: l(bdr1, other.bdr1),
      bdr2: l(bdr2, other.bdr2),
      bdr3: l(bdr3, other.bdr3),
      elev1: BoxShadow.lerpList(elev1, other.elev1, t) ?? other.elev1,
      elev2: BoxShadow.lerpList(elev2, other.elev2, t) ?? other.elev2,
    );
  }
}

/// Kağıt (not sayfası) renkleri: temadan bağımsız, dışa aktarmayla aynı
/// (kullanıcı kararı 2026-10-07). Satır/ızgara çizgisi ve Quill başlıkları
/// hangi tema seçili olursa olsun bu renklerle çizilir; not dosyası değişmez.
abstract final class TarusKagit {
  /// Satır, ızgara ve nokta deseni (`EditorExporterTheme` primary).
  static const cizgi = Colors.blue;

  /// Kenar çizgisi ve Quill başlık rengi (`EditorExporterTheme` secondary).
  static const kenar = Colors.red;
}
