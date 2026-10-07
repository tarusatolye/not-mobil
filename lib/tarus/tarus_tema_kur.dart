import 'package:flutter/material.dart';
import 'package:saber/data/tarus_tema.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:sbn/font_fallbacks.dart';

/// Arayüz yazı tipi: Inter (STANDARTLAR §10); okunaklı yazı tipi seçiliyse
/// Atkinson Hyperlegible Next.
const tarusYaziTipi = 'Inter';
const okunakliYaziTipi = 'AtkinsonHyperlegibleNext';

/// tarus Not'un tek ThemeData kaynağı (Saber'in `SaberTheme`, Yaru ve
/// Cupertino dallarının yerine). Bütün platformlarda aynı Material/tarus
/// görünümü; renkler seçili temanın kabuk token'larından gelir.
abstract final class TarusTemaKur {
  static ThemeData kur(TarusTema tema, {bool okunakli = false}) {
    final r = TarusRenkler.tema(tema.id);
    final renk = tema.renkSemasi.copyWith(
      secondary: r.accent,
      onSecondary: Colors.white,
      primaryContainer: Color.alphaBlend(
        r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa),
        r.card,
      ),
      onPrimaryContainer: r.accent,
      secondaryContainer: Color.alphaBlend(
        r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa),
        r.card,
      ),
      onSecondaryContainer: r.accent,
      surfaceContainer: r.card,
      shadow: Colors.black,
    );
    final aile = okunakli ? okunakliYaziTipi : tarusYaziTipi;
    final yazi = _yaziTemasi(r, aile);
    final acik = tema.acik;

    final kartKenari = BorderSide(color: r.border);
    const kucukKose = BorderRadius.all(Radius.circular(TarusOlcu.rSm));
    const dugmeKose = RoundedRectangleBorder(borderRadius: kucukKose);
    final dugmeYazisi = yazi.labelLarge;

    OutlineInputBorder alanKenari(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: kucukKose,
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: tema.parlaklik,
      colorScheme: renk,
      fontFamily: aile,
      fontFamilyFallback: saberSansSerifFontFallbacks,
      textTheme: yazi,
      primaryTextTheme: yazi,
      scaffoldBackgroundColor: r.bg,
      canvasColor: r.bg,
      cardColor: r.card,
      dividerColor: r.bdr1,
      hintColor: r.muted,
      disabledColor: r.muted.withValues(alpha: TarusOlcu.pasifOpaklik),
      splashFactory: InkRipple.splashFactory,
      highlightColor: r.ovl3,
      hoverColor: r.ovl2,
      focusColor: r.ovl3,
      splashColor: r.ovl3,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [r],
      iconTheme: IconThemeData(color: r.muted2, size: TarusOlcu.ikon),
      appBarTheme: AppBarTheme(
        backgroundColor: r.bg,
        foregroundColor: r.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: TarusOlcu.sayfaYatay,
        toolbarHeight: 56,
        iconTheme: IconThemeData(color: r.muted2, size: TarusOlcu.ikon),
        actionsIconTheme: IconThemeData(color: r.muted2, size: TarusOlcu.ikon),
        titleTextStyle: yazi.titleMedium!.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        shape: Border(bottom: BorderSide(color: r.bdr1)),
      ),
      cardTheme: CardThemeData(
        color: r.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: acik ? 0.10 : 0.45),
        elevation: 1,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(TarusOlcu.rKart),
          ),
          side: kartKenari,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: r.modalBg,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: acik ? 0.18 : 0.6),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(TarusOlcu.rModal),
          ),
          side: BorderSide(color: r.bdr2),
        ),
        titleTextStyle: yazi.titleMedium!.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: yazi.bodyMedium!.copyWith(color: r.muted2),
        barrierColor: Colors.black.withValues(alpha: 0.6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: r.modalBg,
        modalBackgroundColor: r.modalBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 8,
        showDragHandle: true,
        dragHandleColor: r.bdr3,
        dragHandleSize: const Size(36, 4),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(TarusOlcu.rModal),
          ),
          side: BorderSide(color: r.bdr2),
        ),
        modalBarrierColor: Colors.black.withValues(alpha: 0.6),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: r.inputBg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelStyle: yazi.bodyMedium!.copyWith(color: r.muted2),
        floatingLabelStyle: yazi.bodySmall!.copyWith(color: r.accent),
        hintStyle: yazi.bodyMedium!.copyWith(color: r.muted),
        helperStyle: yazi.bodySmall,
        errorStyle: yazi.bodySmall!.copyWith(color: r.danger),
        prefixIconColor: r.muted2,
        suffixIconColor: r.muted2,
        border: alanKenari(r.bdr2),
        enabledBorder: alanKenari(r.bdr2),
        disabledBorder: alanKenari(r.bdr1),
        focusedBorder: alanKenari(r.accent, 1.5),
        errorBorder: alanKenari(r.danger),
        focusedErrorBorder: alanKenari(r.danger, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: r.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: r.ovl4,
          disabledForegroundColor: r.muted,
          minimumSize: const Size(64, TarusOlcu.alan),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: dugmeKose,
          textStyle: dugmeYazisi,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: r.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: r.ovl4,
          disabledForegroundColor: r.muted,
          minimumSize: const Size(64, TarusOlcu.alan),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: dugmeKose,
          textStyle: dugmeYazisi,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: r.text,
          backgroundColor: r.card,
          disabledForegroundColor: r.muted,
          minimumSize: const Size(64, TarusOlcu.alan),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: BorderSide(color: r.bdr2),
          shape: dugmeKose,
          textStyle: dugmeYazisi,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: r.accent,
          disabledForegroundColor: r.muted,
          minimumSize: const Size(48, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: dugmeKose,
          textStyle: dugmeYazisi,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: r.muted2,
          disabledForegroundColor: r.muted.withValues(
            alpha: TarusOlcu.pasifOpaklik,
          ),
          iconSize: TarusOlcu.ikon,
          minimumSize: const Size.square(TarusOlcu.ikonDugme),
          fixedSize: const Size.square(TarusOlcu.ikonDugme),
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(TarusOlcu.rMd)),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: r.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: r.modalBg,
        contentTextStyle: yazi.bodyMedium,
        actionTextColor: r.accent,
        elevation: 6,
        insetPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(TarusOlcu.rLg)),
          side: BorderSide(color: r.bdr2),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: r.modalBg,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        textStyle: yazi.bodyMedium,
        labelTextStyle: WidgetStatePropertyAll(yazi.bodyMedium),
        iconColor: r.muted2,
        iconSize: TarusOlcu.ikonKucuk + 2,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(TarusOlcu.rLg)),
          side: BorderSide(color: r.bdr2),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(r.modalBg),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(TarusOlcu.rLg),
              ),
              side: BorderSide(color: r.bdr2),
            ),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: acik ? r.text : r.modalBg,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          border: acik ? null : Border.all(color: r.bdr2),
        ),
        textStyle: yazi.bodySmall!.copyWith(color: acik ? r.card : r.text),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        waitDuration: const Duration(milliseconds: 400),
      ),
      dividerTheme: DividerThemeData(color: r.bdr1, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: r.muted2,
        textColor: r.text,
        titleTextStyle: yazi.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: yazi.bodySmall!.copyWith(color: r.muted2),
        leadingAndTrailingTextStyle: yazi.bodySmall!.copyWith(color: r.muted2),
        contentPadding: const EdgeInsets.symmetric(horizontal: TarusOlcu.kart),
        minLeadingWidth: 24,
        horizontalTitleGap: 12,
        selectedColor: r.accent,
        selectedTileColor: r.accent.withValues(
          alpha: TarusOlcu.seciliZeminAlfa,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? r.muted : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? r.accent : r.ovl5,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbIcon: const WidgetStatePropertyAll(null),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? r.accent : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: r.bdr3, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? r.accent : r.bdr3,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: r.accent,
        linearTrackColor: r.ovl4,
        circularTrackColor: Colors.transparent,
        // ignore: deprecated_member_use
        year2023: false,
        stopIndicatorColor: Colors.transparent,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: r.accent,
        inactiveTrackColor: r.ovl4,
        thumbColor: r.accent,
        overlayColor: r.accent.withValues(alpha: 0.12),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: r.accent,
        selectionColor: r.accent.withValues(alpha: 0.28),
        selectionHandleColor: r.accent,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(r.bdr3),
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(4),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: r.surface,
        indicatorColor: r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa),
        selectedIconTheme: IconThemeData(color: r.accent),
        unselectedIconTheme: IconThemeData(color: r.muted),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: r.muted2,
        collapsedIconColor: r.muted2,
        textColor: r.text,
        collapsedTextColor: r.text,
        shape: const Border(),
        collapsedShape: const Border(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: r.card,
        selectedColor: r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa),
        side: BorderSide(color: r.bdr2),
        labelStyle: yazi.labelMedium,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(TarusOlcu.rSm)),
        ),
      ),
      badgeTheme: BadgeThemeData(backgroundColor: r.danger),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: r.bdr2)),
          shape: const WidgetStatePropertyAll(dugmeKose),
          textStyle: WidgetStatePropertyAll(yazi.labelMedium),
        ),
      ),
      bannerTheme: MaterialBannerThemeData(backgroundColor: r.card),
    );
  }

  /// tarus yazı ölçeği (Pusula Mobil `ui.type`, STANDARTLAR §10).
  static TextTheme _yaziTemasi(TarusRenkler r, String aile) {
    TextStyle s(double boyut, FontWeight agirlik, Color renk, [double? h]) =>
        TextStyle(
          fontFamily: aile,
          fontFamilyFallback: saberSansSerifFontFallbacks,
          fontSize: boyut,
          fontWeight: agirlik,
          color: renk,
          height: h,
          letterSpacing: 0,
        );
    const normal = FontWeight.w400;
    const orta = FontWeight.w500;
    const yari = FontWeight.w600;
    const kalin = FontWeight.w700;
    return TextTheme(
      displayLarge: s(40, kalin, r.text, 1.15),
      displayMedium: s(34, kalin, r.text, 1.15),
      displaySmall: s(28, kalin, r.text, 1.2),
      headlineLarge: s(26, kalin, r.text, 1.25),
      headlineMedium: s(TarusOlcu.yaziSayfaBasligi, kalin, r.text, 1.25),
      headlineSmall: s(19, kalin, r.text, 1.3),
      titleLarge: s(TarusOlcu.yaziSayfaBasligi, kalin, r.text, 1.25),
      titleMedium: s(TarusOlcu.yaziBolumBasligi, yari, r.text, 1.35),
      titleSmall: s(TarusOlcu.yaziKartBasligi, yari, r.text, 1.35),
      bodyLarge: s(14, normal, r.text, 1.45),
      bodyMedium: s(TarusOlcu.yaziGovde, normal, r.text, 1.45),
      bodySmall: s(12, normal, r.muted2, 1.4),
      labelLarge: s(14, yari, r.text, 1.2),
      labelMedium: s(12, orta, r.text, 1.2),
      labelSmall: s(TarusOlcu.yaziMeta, orta, r.muted2, 1.2),
    );
  }
}
