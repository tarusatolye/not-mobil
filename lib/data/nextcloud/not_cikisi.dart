import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:nextcloud/webdav.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/nextcloud/pusula_giris.dart';
import 'package:saber/data/nextcloud/saber_syncer.dart';
import 'package:saber/data/prefs.dart';

/// Çıkış öncesi eşitleme denetiminin sonucu.
class CikisDenetimi {
  const new({required this.esitlenmemis, required this.sunucuyaUlasildi});

  /// Sunucuda olmayan ya da sunucudakinden yeni yerel dosyalar (göreli yol).
  final List<String> esitlenmemis;

  /// Sunucu listesi alınamadıysa `false`: eşitleme durumu bilinmiyor.
  final bool sunucuyaUlasildi;

  /// Eşitlenmemiş değişikliği olan not sayısı (görsel ve önizleme dosyaları
  /// ait oldukları notla birlikte sayılır).
  int get notSayisi => esitlenmemis.map(NotCikisi.notYolu).toSet().length;

  /// Uyarı gerekmeden çıkılabilir mi.
  bool get temiz => sunucuyaUlasildi && esitlenmemis.isEmpty;
}

/// Çıkış (kullanıcı kararı 2026-10-19, seçenek a): eşitlenmiş notlar cihazdan
/// silinir; eşitlenmemiş değişiklik varsa arayüz önce uyarır. Notlar
/// not.tarus.tr'de kalır, yeniden girişte iner. Cihazda başka hesabın notu
/// kalmasın diye «yine de çık» denirse eşitlenmemişler de silinir.
abstract final class NotCikisi {
  static final log = Logger('NotCikisi');

  /// Yerel ve sunucu değiştirilme zamanları bu kadar yakınsa aynı sayılır
  /// ([SaberSyncInterface.getBestFile] ile aynı tolerans).
  static const tolerans = Duration(milliseconds: 500);

  /// Görsel (`.sbn2.0`) ve önizleme (`.sbn2.p`) dosyasını notun yoluna indirger.
  static String notYolu(String goreliYol) =>
      goreliYol.replaceFirstMapped(RegExp(r'(\.sbn2?)\.[\dp]+$'), (m) => m[1]!);

  /// [yerel]: göreli yol → değiştirilme zamanı; [uzak]: aynı göreli yol →
  /// sunucudaki değiştirilme zamanı. Sunucuda olmayan ya da yerelde daha yeni
  /// olan dosyalar eşitlenmemiştir.
  static List<String> esitlenmemisleriBul({
    required Map<String, DateTime> yerel,
    required Map<String, DateTime?> uzak,
  }) {
    final sonuc = <String>[];
    for (final MapEntry(key: yol, value: yerelZaman) in yerel.entries) {
      final uzakZaman = uzak[yol];
      // WebDAV getlastmodified saniyeye kesilir (X-OC-Mtime tamsayı saniye);
      // yerel zaman da kesilmezse yüklenmiş dosya 0–999 ms «yeni» görünür.
      final yerelSaniye = DateTime.fromMillisecondsSinceEpoch(
        yerelZaman.millisecondsSinceEpoch ~/ 1000 * 1000,
        isUtc: true,
      );
      if (uzakZaman == null || yerelSaniye.difference(uzakZaman) > tolerans) {
        sonuc.add(yol);
      }
    }
    return sonuc..sort();
  }

  /// Eşitleme kapsamındaki yerel dosyalar (eşitleyicinin yüklediklerinin
  /// aynısı: [SaberSyncInterface.yoksayilirMi] dışındakiler).
  static Future<List<File>> _yerelDosyalar() async {
    final kok = FileManager.getRootDirectory();
    if (!kok.existsSync()) return [];
    final dosyalar = <File>[];
    await for (final varlik in kok.list(recursive: true)) {
      if (varlik is! File) continue;
      if (SaberSyncInterface.yoksayilirMi(_goreli(varlik))) continue;
      dosyalar.add(varlik);
    }
    return dosyalar;
  }

  static String _goreli(FileSystemEntity varlik) => varlik.path
      .substring(FileManager.documentsDirectory.length)
      .replaceAll(Platform.pathSeparator, '/');

  /// Sunucu listesini tazeden alır (önbelleğe bakmadan) ve yerel dosyalarla
  /// karşılaştırır.
  static Future<CikisDenetimi> denetle() async {
    final yerel = <String, DateTime>{
      for (final dosya in await _yerelDosyalar())
        _goreli(dosya): dosya.lastModifiedSync(),
    };
    if (yerel.isEmpty) {
      return const CikisDenetimi(esitlenmemis: [], sunucuyaUlasildi: true);
    }

    final client = SaberSyncInterface.client;
    if (client == null) {
      return CikisDenetimi(
        esitlenmemis: yerel.keys.toList()..sort(),
        sunucuyaUlasildi: false,
      );
    }
    try {
      final liste = await client.webdav
          .propfind(
            PathUri.parse(FileManager.appRootDirectoryPrefix),
            prop: const WebDavPropWithoutValues.fromBools(
              davGetcontentlength: true,
              davGetlastmodified: true,
              davResourcetype: true,
            ),
            depth: WebDavDepth.infinity,
          )
          .timeout(const Duration(seconds: 20));
      final uzak = <String, DateTime?>{};
      for (final dosya in liste.toWebDavFiles()) {
        if (dosya.isDirectory) continue;
        final goreli = SaberSyncInterface.yerelGoreliYol(dosya.path.path);
        if (goreli != null) uzak[goreli] = dosya.lastModified;
      }
      return CikisDenetimi(
        esitlenmemis: esitlenmemisleriBul(yerel: yerel, uzak: uzak),
        sunucuyaUlasildi: true,
      );
    } catch (e) {
      log.warning('Çıkış denetimi: sunucu listesi alınamadı: $e');
      return CikisDenetimi(
        esitlenmemis: yerel.keys.toList()..sort(),
        sunucuyaUlasildi: false,
      );
    }
  }

  /// Oturumu kapatır ve notları cihazdan siler. Silme sunucuya yansımaz:
  /// önce kimlik ve eşitleme kuyrukları temizlenir, dosyalar doğrudan silinir.
  static Future<void> cikisYap() async {
    final belirtec = stows.ncPassword.value;
    final pusulaBelirteci = PusulaGiris.pusulaBelirteciyleMi;

    syncer.uploader.clearPending();
    syncer.downloader.clearPending();
    stows.url.value = '';
    stows.username.value = '';
    stows.ncPassword.value = '';
    stows.pfp.value = null;
    stows.gorunenAd.value = '';
    stows.eposta.value = '';
    stows.lastStorageQuota.value = null;
    SaberSyncInterface.remoteFiles = {};

    if (pusulaBelirteci) unawaited(PusulaGiris.birak(belirtec));

    await yerelNotlariSil();

    stows.recentFiles.value = [];
    stows.fileSyncAlreadyDeleted.value = {};
    stows.fileSyncCorruptFiles.value = {};
  }

  /// Eşitleme kapsamındaki dosyaları ve boşalan klasörleri siler.
  static Future<int> yerelNotlariSil() async {
    var silinen = 0;
    for (final dosya in await _yerelDosyalar()) {
      try {
        await dosya.delete();
        silinen++;
      } catch (e) {
        log.warning('Silinemedi: ${dosya.path}: $e');
      }
    }
    await _bosKlasorleriSil(FileManager.getRootDirectory());
    log.info('Çıkış: $silinen dosya cihazdan silindi');
    return silinen;
  }

  static Future<void> _bosKlasorleriSil(Directory kok) async {
    if (!kok.existsSync()) return;
    final klasorler = await kok
        .list(recursive: true)
        .where((v) => v is Directory)
        .cast<Directory>()
        .toList();
    // En derindekiler önce.
    klasorler.sort((a, b) => b.path.length.compareTo(a.path.length));
    for (final klasor in klasorler) {
      if (SaberSyncInterface.yoksayilirMi(_goreli(klasor))) continue;
      try {
        if (klasor.listSync().isEmpty) await klasor.delete();
      } catch (_) {}
    }
  }
}
