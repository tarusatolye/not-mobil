/// Hakkında → Sürüm notları: kullanıcıya dönük özet (STANDARTLAR §19).
///
/// Her not en fazla üç cümle; ne kodlandığını değil, kullanıcının neyi
/// farklı gördüğünü anlatır. En yeni kayıt üstte. Sürüm adı rakamla, `v`
/// öneki yok. Ayrıntılı tarihçe: `TARUS_NOT.md` → Sürüm notları.
class const SurumNotu(final String surum, final String tarih, final String not);

/// tarus Not'un ilk yayını (tarus sürüm şeması 1.0.0).
const ilkYayin = '2 Ekim 2026';

const surumNotlari = <SurumNotu>[
  SurumNotu(
    '1.1.5',
    '7 Ekim 2026',
    'Arayüz tarus tasarım diline geçti: Inter yazı tipi, tek ikon ailesi, '
        'yeni kartlar, pencereler ve Ayarlar; vurgu rengi seçtiğiniz temadan '
        'geliyor. Alt çubuk Pusula Mobil gibi yüzüyor, ortadaki + ile yeni not '
        'açılıyor ve ilk sekmenin adı artık Hızlı Bakış. Kağıt çizgileri temadan '
        'bağımsız, dışa aktarılan sayfayla aynı renkte; Karanlık temada not '
        'adları yeniden okunuyor.',
  ),
  SurumNotu(
    '1.1.4',
    '6 Ekim 2026',
    'Ana ekran ikonu tarus Not işareti oldu; telefonun renkli ikon '
        'temalarında da doğru görünüyor.',
  ),
  SurumNotu(
    '1.1.3',
    '6 Ekim 2026',
    'Gizlilik politikası ve hesap silme tarus.tr’ye taşındı; Ayarlar’dan '
        'eşitlemeyi ve cihazdaki notları silmenin yolları anlatılıyor.',
  ),
  SurumNotu(
    '1.1.2',
    '5 Ekim 2026',
    'Uygulamanın her yerinde ad tarus Not olarak görünüyor.',
  ),
  SurumNotu(
    '1.1.1',
    '4 Ekim 2026',
    'İlk açılışta tema Modern Işık. Boş bir yere basılı tutunca Hata bildir '
        'menüsü açılıyor.',
  ),
  SurumNotu(
    '1.1.0',
    '3 Ekim 2026',
    'tarus’un sekiz teması geldi; Ayarlar → Hata bildir ile sorunu ekran '
        'adıyla birlikte gönderebilirsiniz.',
  ),
  SurumNotu(
    '1.0.0',
    ilkYayin,
    'tarus Not ilk sürüm: el yazısı notlar, klasörler ve Pusula eşitleme '
        'belirteciyle not.tarus.tr’ye eşitleme.',
  ),
];
