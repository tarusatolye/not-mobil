/// tarus Not'un uygulama dışına açtığı adresler (gizlilik, hesap silme,
/// kaynak kodu, Pusula).
///
/// Her biri derlemede değiştirilebilir; sayfa taşınırsa kod değişmeden
/// `--dart-define` ile yeni adres verilir:
///
/// ```bash
/// flutter build appbundle --release \
///   --dart-define=TARUS_GIZLILIK_URL=https://tarus.tr/gizlilik/
/// ```
///
/// Varsayılanlar (2026-10-05): kurumsal sitede gizlilik sayfası yok
/// (`kurumsal.tarus.tr/gizlilik` SPA ana sayfasına düşüyor); canlı tarus
/// gizlilik politikası `yazilim.tarus.tr/gizlilik/`. Ayrı bir hesap silme
/// sayfası da yok: o politikadaki "veri silme istekleri" bölümü kullanılır.
abstract final class TarusBaglantilar {
  /// Gizlilik politikası (Hakkında, giriş adımı). Play Console'daki
  /// "Gizlilik politikası" alanına da aynı adres yazılır.
  static final Uri gizlilik = Uri.parse(
    const String.fromEnvironment(
      'TARUS_GIZLILIK_URL',
      defaultValue: 'https://yazilim.tarus.tr/gizlilik/',
    ),
  );

  /// Hesap ve veri silme talebinin web adresi (Play "hesap silme" şartı:
  /// uygulamayı kurmadan da ulaşılabilen bir sayfa). Play Console'daki
  /// "Hesap silme URL'si" alanına da aynı adres yazılır.
  static final Uri hesapSilme = Uri.parse(
    const String.fromEnvironment(
      'TARUS_HESAP_SILME_URL',
      defaultValue: 'https://yazilim.tarus.tr/gizlilik/',
    ),
  );

  /// Veri ve hesap silme talepleri için e-posta (gizlilik politikasındaki adres).
  static const iletisimEposta = String.fromEnvironment(
    'TARUS_ILETISIM_EPOSTA',
    defaultValue: 'yazilim@tarus.tr',
  );

  /// Pusula › Ayarlar (Not eşitleme belirteçleri burada iptal edilir).
  static final Uri pusulaAyarlar = Uri.parse(
    const String.fromEnvironment(
      'TARUS_PUSULA_AYARLAR_URL',
      defaultValue: 'https://pusula.tarus.tr/ayarlar',
    ),
  );

  /// Pusula hesabı oluşturma (Not'un ayrı hesabı yok, kimlik Pusula'dır).
  static final Uri pusulaHesapOlustur = Uri.parse(
    const String.fromEnvironment(
      'TARUS_PUSULA_HESAP_URL',
      defaultValue: 'https://pusula.tarus.tr/hesap-olustur',
    ),
  );

  /// tarus Not'un kaynak kodu (GPL-3.0 §6: ikili dağıtımla birlikte kaynak).
  /// Depo herkese açık olmalı ya da bu adres herkese açık bir aynaya/kaynak
  /// arşivine çevrilmeli (TARUS_NOT.md → Lisans).
  static final Uri kaynakKodu = Uri.parse(
    const String.fromEnvironment(
      'TARUS_KAYNAK_URL',
      defaultValue: 'https://github.com/tarusatolye/not-mobil',
    ),
  );
}
