import 'package:flutter/material.dart';
import 'package:saber/tarus/tarus_renkler.dart';

/// tarus mobil ölçüleri: Pusula Mobil `app/theme/ui.ts` ile aynı değerler
/// (boşluk, köşe, kontrol boyutu, yazı ölçeği, seçili durum).
/// Ekranlar özel bir gereksinim taşımadıkça buradaki değerleri kullanır.
abstract final class TarusOlcu {
  // Köşe yuvarlaklığı (STANDARTLAR §12, ui.radius).
  /// Buton, form alanı, küçük kart (`--r-sm`).
  static const rSm = 8.0;

  /// Orta düğme, alt kart (`--r-md`).
  static const rMd = 10.0;

  /// İç kart (`--r-lg`).
  static const rLg = 12.0;

  /// Standart kart (`--r-xl`, ui.radius.card).
  static const rKart = 14.0;

  /// Hero / büyük kart (ui.radius.hero).
  static const rHero = 16.0;

  /// Pencere ve alt sayfa (ui.radius.modal).
  static const rModal = 22.0;

  /// Yüzen alt çubuk (Pusula Mobil AppNavigator).
  static const rAltCubuk = 28.0;

  // Boşluk (ui.spacing).
  /// Ana ekranların dış yatay boşluğu.
  static const sayfaYatay = 12.0;

  /// Başlıktan sonraki ilk içerik boşluğu.
  static const sayfaUst = 12.0;

  /// Aynı seviyedeki içerik blokları arası.
  static const blokArasi = 10.0;

  /// Kart iç boşluğu.
  static const kart = 14.0;

  /// Küçük aralık (`--gap-sm`).
  static const aralik = 8.0;

  /// İçerik ile alt çubuk yüzeyi arası.
  static const altCubukAralik = 6.0;

  /// Alt çubuk içeriğin üstüne bindiğinde ayrılan alan.
  static const altCubukPayi = 104.0;

  // Kontrol boyutları (ui.size).
  static const aracCubugu = 42.0;
  static const alan = 42.0;
  static const birincilDugme = 48.0;
  static const ikonDugme = 40.0;

  // İkon boyutları.
  static const ikon = 20.0;
  static const ikonKucuk = 16.0;

  // Yazı ölçeği (ui.type).
  static const yaziSayfaBasligi = 22.0;
  static const yaziBolumBasligi = 15.0;
  static const yaziKartBasligi = 14.0;
  static const yaziGovde = 13.0;
  static const yaziMeta = 11.0;

  // Seçili durum (ui.state, Pusula `selectionStyle`): vurgu rengi
  // `#RRGGBB14` zemin, `#RRGGBB45` kenarlık.
  static const seciliZeminAlfa = 0x14 / 0xFF;
  static const seciliKenarAlfa = 0x45 / 0xFF;
  static const basiliOpaklik = 0.72;
  static const pasifOpaklik = 0.55;

  /// Geniş ekran eşiği: altında alt çubuk, üstünde kenar rayı.
  static const genisEkran = 600.0;
}

/// Filtre, sekme ve seçeneklerde tek görsel seçili durum
/// (Pusula Mobil `selectionStyle`).
abstract final class TarusSecim {
  static Color zemin(TarusRenkler r, bool secili, {bool dolu = false}) {
    if (!secili) return Colors.transparent;
    return dolu
        ? r.accent
        : r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa);
  }

  static Color kenar(TarusRenkler r, bool secili, {bool dolu = false}) {
    if (!secili) return r.border;
    return dolu
        ? r.accent
        : r.accent.withValues(alpha: TarusOlcu.seciliKenarAlfa);
  }
}
