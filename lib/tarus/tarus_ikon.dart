import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// tarus Not'un tek ikon ailesi: Lucide (web `lucide-react` ile aynı çizim).
///
/// Uygulamada Material, Cupertino, Font Awesome ya da Material Symbols
/// ikonu kullanılmaz; ekranlar ikonu buradaki anlamlı adla alır. Bir ikon
/// değişecekse yalnız bu dosya değişir.
abstract final class TarusIkon {
  // Gezinme
  static const IconData hizliBakis = LucideIcons.house;
  static const IconData notlar = LucideIcons.notebookText;
  static const IconData beyazTahta = LucideIcons.penLine;
  static const IconData ayarlar = LucideIcons.settings;
  static const IconData ekle = LucideIcons.plus;
  static const IconData kapat = LucideIcons.x;
  static const IconData geri = LucideIcons.arrowLeft;
  static const IconData ileri = LucideIcons.chevronRight;
  static const IconData asagi = LucideIcons.chevronDown;
  static const IconData dahaFazla = LucideIcons.ellipsisVertical;
  static const IconData tamam = LucideIcons.check;
  static const IconData seciliDaire = LucideIcons.circleCheck;
  static const IconData disBaglanti = LucideIcons.externalLink;

  // Not ve klasör
  static const IconData not = LucideIcons.notebookText;
  static const IconData yeniNot = LucideIcons.squarePen;
  static const IconData notIceAktar = LucideIcons.fileInput;
  static const IconData klasor = LucideIcons.folder;
  static const IconData klasorAcik = LucideIcons.folderOpen;
  static const IconData yeniKlasor = LucideIcons.folderPlus;
  static const IconData ustKlasor = LucideIcons.folderUp;
  static const IconData tasi = LucideIcons.folderInput;
  static const IconData yenidenAdlandir = LucideIcons.pencilLine;
  static const IconData sil = LucideIcons.trash2;
  static const IconData disaAktar = LucideIcons.share2;
  static const IconData kopyala = LucideIcons.copy;

  // Liste düzeni ve sıralama
  static const IconData duzenDuvar = LucideIcons.layoutDashboard;
  static const IconData duzenIzgara = LucideIcons.layoutGrid;
  static const IconData siralaAZ = LucideIcons.arrowDownAZ;
  static const IconData siralaZA = LucideIcons.arrowUpAZ;
  static const IconData siralaYeni = LucideIcons.clockArrowDown;
  static const IconData siralaEski = LucideIcons.clockArrowUp;

  // Eşitleme ve hesap
  static const IconData esitle = LucideIcons.refreshCw;
  static const IconData yukle = LucideIcons.upload;
  static const IconData indir = LucideIcons.download;
  static const IconData buluttaYukle = LucideIcons.cloudUpload;
  static const IconData kullanici = LucideIcons.circleUser;
  static const IconData cikis = LucideIcons.logOut;
  static const IconData kilit = LucideIcons.lockKeyhole;
  static const IconData kilitAcik = LucideIcons.lockOpen;
  static const IconData guvenlik = LucideIcons.shieldCheck;
  static const IconData goster = LucideIcons.eye;
  static const IconData gizle = LucideIcons.eyeOff;

  // Editör araçları
  static const IconData dolmaKalem = LucideIcons.penTool;
  static const IconData tukenmezKalem = LucideIcons.pen;
  static const IconData kursunKalem = LucideIcons.pencil;
  static const IconData fosforluKalem = LucideIcons.highlighter;
  static const IconData sekilKalemi = LucideIcons.shapes;
  static const IconData silgi = LucideIcons.eraser;
  static const IconData sec = LucideIcons.lasso;
  static const IconData lazer = LucideIcons.crosshair;
  static const IconData renkler = LucideIcons.palette;
  static const IconData gorsel = LucideIcons.image;
  static const IconData gorselEkle = LucideIcons.imagePlus;
  static const IconData metin = LucideIcons.type;
  static const IconData parmakla = LucideIcons.hand;
  static const IconData tamEkran = LucideIcons.maximize;
  static const IconData tamEkrandanCik = LucideIcons.minimize;
  static const IconData geriAl = LucideIcons.undo2;
  static const IconData yinele = LucideIcons.redo2;
  static const IconData sayfaEkle = LucideIcons.filePlus;
  static const IconData sayfalar = LucideIcons.files;
  static const IconData kagit = LucideIcons.fileText;
  static const IconData kaydet = LucideIcons.save;
  static const IconData sabitle = LucideIcons.pin;
  static const IconData gecmis = LucideIcons.history;
  static const IconData damla = LucideIcons.droplet;
  static const IconData kenardanKaydir = LucideIcons.scaling;
  static const IconData tutamac = LucideIcons.gripHorizontal;
  static const IconData arkaPlanYap = LucideIcons.wallpaper;
  static const IconData duzenlemeKapali = LucideIcons.penOff;
  static const IconData tekParmakKaydir = LucideIcons.pointer;
  static const IconData ikiParmakKaydir = LucideIcons.move;
  static const IconData eksenKilidi = LucideIcons.moveVertical;
  static const IconData kaydir = LucideIcons.handGrab;
  static const IconData dosya = LucideIcons.file;

  // Ayarlar
  static const IconData dil = LucideIcons.languages;
  static const IconData tema = LucideIcons.sunMoon;
  static const IconData duzenBoyutu = LucideIcons.monitorSmartphone;
  static const IconData telefon = LucideIcons.smartphone;
  static const IconData tablet = LucideIcons.tablet;
  static const IconData otomatik = LucideIcons.scan;
  static const IconData yaziTipi = LucideIcons.caseSensitive;
  static const IconData griTon = LucideIcons.contrast;
  static const IconData temizle = LucideIcons.brushCleaning;
  static const IconData kalem = LucideIcons.pencil;
  static const IconData yukari = LucideIcons.arrowUpToLine;
  static const IconData saga = LucideIcons.arrowRightToLine;
  static const IconData asagiCizgi = LucideIcons.arrowDownToLine;
  static const IconData sola = LucideIcons.arrowLeftToLine;
  static const IconData renkCevir = LucideIcons.blend;
  static const IconData klavye = LucideIcons.keyboard;
  static const IconData klavyeKapali = LucideIcons.keyboardOff;
  static const IconData sayfaNumarasi = LucideIcons.hash;
  static const IconData gorselBoyutu = LucideIcons.imageDown;
  static const IconData cizgiDuzelt = LucideIcons.ruler;
  static const IconData baglanti = LucideIcons.link;
  static const IconData kayitlar = LucideIcons.scrollText;
  static const IconData hataBildir = LucideIcons.bug;
  static const IconData hakkinda = LucideIcons.info;
  static const IconData guncelleme = LucideIcons.download;
  static const IconData uyari = LucideIcons.triangleAlert;
  static const IconData gonder = LucideIcons.send;
  static const IconData oynat = LucideIcons.play;
  static const IconData duraklat = LucideIcons.pause;
}
