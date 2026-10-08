import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// tarus Not marka işareti (plaka `#AC865A`, beyaz defter sayfası glifi;
/// `ozluk/tarus-kabuk/marka/marka.json`, `assets/icon/icon.svg`).
class const TarusNotIsareti({super.key, final double boyut = 40})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icon/icon.svg',
    width: boyut,
    height: boyut,
    excludeFromSemantics: true,
  );
}

/// tarus şirket işareti (kabuk `TarusIsareti`, metin rengini alır).
class const TarusIsareti({
  super.key,
  final double boyut = 20,
  final Color? renk,
}) extends StatelessWidget {
  static const _svg =
      '<svg viewBox="0 0 1080 1080" xmlns="http://www.w3.org/2000/svg">'
      '<polygon points="26,334 1054,129 1054,849 972,849 972,237 45,417"/>'
      '<polygon points="292,26 375,26 375,238 292,254"/>'
      '<polygon points="375,377 375,1053 292,1053 292,393"/>'
      '<polygon points="715,311 715,849 632,849 632,329"/></svg>';

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    _svg,
    width: boyut,
    height: boyut,
    colorFilter: ColorFilter.mode(
      renk ?? TarusRenkler.of(context).text,
      BlendMode.srcIn,
    ),
    excludeFromSemantics: true,
  );
}

/// Standart kart (STANDARTLAR §Kart): `--card`, 1 px `--border`, köşe 14,
/// `--elev-1`. Seçiliyken Pusula `selectionStyle` (vurgu %14 zemin
/// katmanı + %45 kenarlık).
class TarusKart extends StatelessWidget {
  const new({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.secili = false,
    this.padding = EdgeInsets.zero,
    this.golge = true,
    this.renk,
    this.kose = TarusOlcu.rKart,
    this.icerigiBoya = true,
  });

  final Widget child;
  final VoidCallback? onTap, onLongPress, onSecondaryTap;
  final bool secili;

  /// Seçiliyken vurgu katmanı içeriğin üstüne de düşer. Not önizlemesi
  /// taşıyan kartlarda false: vurgu zemine karışır, önizleme renkleri
  /// (mürekkep, kağıt) değişmez.
  final bool icerigiBoya;
  final EdgeInsetsGeometry padding;
  final bool golge;
  final Color? renk;
  final double kose;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final radius = BorderRadius.circular(kose);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: secili && !icerigiBoya
            ? Color.alphaBlend(
                r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa),
                renk ?? r.card,
              )
            : renk ?? r.card,
        borderRadius: radius,
        border: Border.all(
          color: secili
              ? r.accent.withValues(alpha: TarusOlcu.seciliKenarAlfa)
              : r.border,
        ),
        boxShadow: golge ? r.elev1 : null,
      ),
      foregroundDecoration: secili && icerigiBoya
          ? BoxDecoration(
              color: r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa),
              borderRadius: radius,
            )
          : null,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          onSecondaryTap: onSecondaryTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Bölüm etiketi (Ayarlar grupları, liste bölümleri): 12 px / 700,
/// `--muted2`; büyük harf kullanılmaz (Türkçe İ/I dönüşümü).
class const TarusBolumEtiketi(
  final String metin, {
  super.key,
  final Widget? eylem,
  final EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(4, 16, 4, 8),
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                metin,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: r.muted2,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          ?eylem,
        ],
      ),
    );
  }
}

/// Boş durum (STANDARTLAR §tarusEmptyState): ikon ya da Not işareti,
/// 15 px / 600 başlık, 13 px `--muted2` açıklama, isteğe bağlı eylem.
class TarusBosDurum extends StatelessWidget {
  const new({
    super.key,
    this.ikon,
    this.isaret = false,
    required this.baslik,
    this.aciklama,
    this.eylem,
  });

  final IconData? ikon;

  /// İkon yerine tarus Not marka işareti.
  final bool isaret;
  final String baslik;
  final String? aciklama;
  final Widget? eylem;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, minHeight: 220),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isaret)
                const TarusNotIsareti(boyut: 56)
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: r.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(TarusOlcu.rHero),
                  ),
                  child: Icon(
                    ikon ?? TarusIkon.notlar,
                    size: 26,
                    color: r.accent,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                baslik,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: r.text,
                ),
              ),
              if (aciklama != null) ...[
                const SizedBox(height: 6),
                Text(
                  aciklama!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: r.muted2, height: 1.45),
                ),
              ],
              if (eylem != null) ...[const SizedBox(height: 16), eylem!],
            ],
          ),
        ),
      ),
    );
  }
}

/// 40 px ikon düğmesi; seçiliyken vurgu %14 zemin + %45 kenarlık
/// (Pusula Mobil `selectionStyle`), değilken şeffaf.
class TarusIkonDugmesi extends StatelessWidget {
  const new({
    super.key,
    required this.ikon,
    required this.onPressed,
    this.tooltip,
    this.secili = false,
    this.boyut = TarusOlcu.ikonDugme,
    this.ikonBoyutu = TarusOlcu.ikon,
    this.renk,
    this.child,
  });

  final IconData? ikon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool secili;
  final double boyut, ikonBoyutu;

  /// Seçili değilken ikon rengi (varsayılan `--muted2`).
  final Color? renk;

  /// İkon yerine özel içerik (ör. renk örneği).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final etkin = onPressed != null;
    final on = !etkin
        ? r.muted.withValues(alpha: TarusOlcu.pasifOpaklik)
        : secili
        ? r.accent
        : (renk ?? r.muted2);
    final radius = BorderRadius.circular(TarusOlcu.rMd);
    final dugme = Semantics(
      button: true,
      selected: secili,
      enabled: etkin,
      label: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: boyut,
        height: boyut,
        decoration: BoxDecoration(
          color: TarusSecim.zemin(r, secili),
          borderRadius: radius,
          border: Border.all(
            color: secili
                ? r.accent.withValues(alpha: TarusOlcu.seciliKenarAlfa)
                : Colors.transparent,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: Center(
              child: IconTheme.merge(
                data: IconThemeData(color: on, size: ikonBoyutu),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: on),
                  child: child ?? Icon(ikon),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return dugme;
    return Tooltip(message: tooltip, excludeFromSemantics: true, child: dugme);
  }
}

/// Ana sekmelerin üst başlığı (sliver): 22 px / 700 sayfa başlığı ve
/// sağda 40 px ikon düğmeleri. Kaydırınca sabit kalır.
class TarusSayfaUstu extends StatelessWidget {
  const new({
    super.key,
    required this.baslik,
    this.altBaslik,
    this.eylemler = const [],
    this.alt,
  });

  final String baslik;
  final String? altBaslik;
  final List<Widget> eylemler;
  final PreferredSizeWidget? alt;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      backgroundColor: r.bg,
      shape: const Border(),
      titleSpacing: TarusOlcu.sayfaYatay + 4,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              baslik,
              style: TextStyle(
                fontSize: TarusOlcu.yaziSayfaBasligi,
                fontWeight: FontWeight.w700,
                color: r.text,
                height: 1.2,
              ),
            ),
          ),
          if (altBaslik != null)
            Text(
              altBaslik!,
              style: TextStyle(fontSize: 12, color: r.muted2, height: 1.3),
            ),
        ],
      ),
      actions: [
        ...eylemler,
        const SizedBox(width: TarusOlcu.sayfaYatay - 4),
      ],
      bottom: alt,
    );
  }
}

/// Pencere düğmesi (Saber'in `CupertinoDialogAction` yerine).
/// [isDestructiveAction] tehlike rengi, [isDefaultAction] ya da birden çok
/// düğmede sonuncusu birincil (dolu vurgu) çizilir.
class TarusDialogDugmesi {
  const new({
    required this.child,
    required this.onPressed,
    this.isDestructiveAction = false,
    this.isDefaultAction = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isDestructiveAction, isDefaultAction;
}

/// tarus penceresi (STANDARTLAR §tarusDialog, köşe 22 Pusula Mobil modal):
/// başlık 16 px / 700 ve kapat düğmesi, gövde, sağa hizalı düğmeler.
class TarusDialog extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.kaydir = true,
    this.genislik = 440,
  });

  final Widget title;
  final Widget content;
  final List<TarusDialogDugmesi> actions;

  /// Gövde kendi kaydırmasını yapmıyorsa true (liste içeren gövdede false).
  final bool kaydir;
  final double genislik;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final theme = Theme.of(context);
    final govde = DefaultTextStyle.merge(
      style: TextStyle(fontSize: 13, color: r.muted2, height: 1.45),
      child: content,
    );
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: genislik),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: r.bdr1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: theme.dialogTheme.titleTextStyle?.copyWith(
                        color: r.text,
                      ),
                      child: Semantics(header: true, child: title),
                    ),
                  ),
                  TarusIkonDugmesi(
                    ikon: TarusIkon.kapat,
                    ikonBoyutu: 18,
                    boyut: 36,
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: kaydir
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: govde,
                    )
                  : Padding(padding: const EdgeInsets.all(18), child: govde),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: TarusOlcu.aralik,
                  runSpacing: TarusOlcu.aralik,
                  children: [
                    for (var i = 0; i < actions.length; i++)
                      _dugme(context, r, actions[i], i == actions.length - 1),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dugme(
    BuildContext context,
    TarusRenkler r,
    TarusDialogDugmesi d,
    bool sonuncu,
  ) {
    if (d.isDestructiveAction) {
      return FilledButton(
        onPressed: d.onPressed,
        style: FilledButton.styleFrom(backgroundColor: r.danger),
        child: d.child,
      );
    }
    if (d.isDefaultAction || (sonuncu && actions.length > 1)) {
      return FilledButton(onPressed: d.onPressed, child: d.child);
    }
    return OutlinedButton(onPressed: d.onPressed, child: d.child);
  }
}

/// Form alanı (Saber'in `AdaptiveTextField` yerine): üstte etiket,
/// köşe 8, `--input-bg` zemin; parola alanında göster/gizle.
class TarusMetinAlani extends StatefulWidget {
  const new({
    super.key,
    this.controller,
    this.autofillHints,
    this.placeholder,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    required this.focusOrder,
    this.validator,
    this.autofocus = true,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final NumericFocusOrder focusOrder;
  final String? placeholder;
  final Widget? prefixIcon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<TarusMetinAlani> createState() => _TarusMetinAlaniState();
}

class _TarusMetinAlaniState extends State<TarusMetinAlani> {
  late var gizli = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    var keyboardType = widget.keyboardType;
    if (widget.isPassword) {
      keyboardType = gizli ? null : TextInputType.visiblePassword;
    }
    return FocusTraversalOrder(
      order: widget.focusOrder,
      child: TextFormField(
        controller: widget.controller,
        autofillHints: widget.autofillHints,
        keyboardType: keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: gizli,
        validator: widget.validator,
        autofocus: widget.autofocus,
        inputFormatters: widget.inputFormatters,
        decoration: InputDecoration(
          labelText: widget.placeholder,
          prefixIcon: widget.prefixIcon == null
              ? null
              : IconTheme.merge(
                  data: const IconThemeData(size: 18),
                  child: widget.prefixIcon!,
                ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(gizli ? TarusIkon.gizle : TarusIkon.goster),
                  iconSize: 18,
                  onPressed: () => setState(() => gizli = !gizli),
                )
              : null,
        ),
      ),
    );
  }
}

/// Seçenek (Saber'in `ToggleButtonsOption`): değer ve görünen içerik.
class ToggleButtonsOption<T> {
  final T value;
  final Widget widget;

  const new(this.value, this.widget);
}

/// Bölümlü seçici (Ayarlar): seçili parça `selectionStyle`.
class TarusSecmeli<T extends Object> extends StatelessWidget {
  const new({
    super.key,
    required this.value,
    required this.options,
    required this.onChange,
    this.optionsWidth = 52,
    this.optionsHeight = 34,
  });

  final T value;
  final List<ToggleButtonsOption<T>> options;
  final ValueChanged<T?> onChange;
  final double optionsWidth, optionsHeight;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: r.inputBg,
        borderRadius: BorderRadius.circular(TarusOlcu.rMd),
        border: Border.all(color: r.bdr1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            _Parca(
              secili: o.value == value,
              genislik: optionsWidth,
              yukseklik: optionsHeight,
              onTap: () => onChange(o.value),
              child: o.widget,
            ),
        ],
      ),
    );
  }
}

class const _Parca({
  required final bool secili,
  required final double genislik,
  required final double yukseklik,
  required final VoidCallback onTap,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final on = secili ? r.accent : r.muted2;
    final radius = BorderRadius.circular(TarusOlcu.rSm);
    return Semantics(
      selected: secili,
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            constraints: BoxConstraints(
              minWidth: genislik,
              minHeight: yukseklik,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: secili ? r.card : Colors.transparent,
              borderRadius: radius,
              border: Border.all(
                color: secili
                    ? r.accent.withValues(alpha: TarusOlcu.seciliKenarAlfa)
                    : Colors.transparent,
              ),
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: on, size: 18),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: on,
                  fontSize: 12.5,
                  fontWeight: secili ? FontWeight.w600 : FontWeight.w500,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yazıyla aynı boyda ve renkte dönen gösterge (düğme içi yükleniyor).
class const TarusMetinCarki({super.key, final double alfa = 1})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stil = DefaultTextStyle.of(context).style;
    final boyut = stil.fontSize ?? 14;
    final renk = stil.color ?? TarusRenkler.of(context).text;
    return SizedBox.square(
      dimension: boyut,
      child: CircularProgressIndicator(
        strokeWidth: boyut / 6,
        color: renk.withValues(alpha: alfa),
      ),
    );
  }
}

/// Ekranın altında kısa bildirim (tarusToast benzeri, SnackBar teması).
void tarusBildir(BuildContext context, String metin) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(metin)));
}
