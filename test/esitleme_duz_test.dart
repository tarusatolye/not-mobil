import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nextcloud/nextcloud.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/nextcloud/esitleme_uyarisi.dart';
import 'package:saber/data/nextcloud/saber_syncer.dart';
import 'package:saber/data/prefs.dart';

import 'utils/test_mock_channel_handlers.dart';
import 'utils/test_random.dart';

/// 1.1.6: notlar sunucuyla düz eşitlenir (`Saber/<klasör>/<ad>.sbn2`);
/// sunucu diskte şifreli saklar. Yol eşlemesi, yok sayılan dosyalar,
/// 403/503 davranışı ve eski şifreleme kayıtlarının silinmesi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPathProvider();
  setupMockFlutterSecureStorage();
  FlavorConfig.setup();

  group('Yol eşlemesi', () {
    test('yerel → sunucu', () {
      expect(SaberSyncInterface.uzakYol('/a.sbn2'), 'Saber/a.sbn2');
      expect(
        SaberSyncInterface.uzakYol('/Saha/Kat 1/kolon.sbn2'),
        'Saber/Saha/Kat 1/kolon.sbn2',
      );
      expect(
        SaberSyncInterface.uzakYol('/Şantiye/İç cephe.sbn2.0'),
        'Saber/Şantiye/İç cephe.sbn2.0',
      );
    });

    test('sunucu → yerel', () {
      expect(SaberSyncInterface.yerelGoreliYol('Saber/a.sbn2'), '/a.sbn2');
      expect(SaberSyncInterface.yerelGoreliYol('/Saber/a.sbn2'), '/a.sbn2');
      expect(
        SaberSyncInterface.yerelGoreliYol('Saber/Saha/Kat 1/kolon.sbn2'),
        '/Saha/Kat 1/kolon.sbn2',
      );
      // Yan dosyalar: önizleme ve görseller
      expect(
        SaberSyncInterface.yerelGoreliYol('Saber/Saha/kolon.sbn2.p'),
        '/Saha/kolon.sbn2.p',
      );
      expect(
        SaberSyncInterface.yerelGoreliYol('Saber/Saha/kolon.sbn2.12'),
        '/Saha/kolon.sbn2.12',
      );
      // Sunucunun çakışma kopyası sıradan bir nottur
      expect(
        SaberSyncInterface.yerelGoreliYol(
          'Saber/a (çakışma - Tablet - 2026-10-02 14.05).sbn2',
        ),
        '/a (çakışma - Tablet - 2026-10-02 14.05).sbn2',
      );
    });

    test('gidiş-dönüş aynı yolu verir', () {
      for (final yol in [
        '/a.sbn2',
        '/a.sbn2.p',
        '/a.sbn2.0',
        '/Saha/Kat 1/kolon.sbn2',
        '/x/y/z/w/derin.sbn2',
        '/Şantiye/Öğle ğüşiöç.sbn2',
      ]) {
        final uzak = SaberSyncInterface.uzakYol(yol);
        expect(SaberSyncInterface.yerelGoreliYol(uzak), yol, reason: uzak);
      }
    });

    test('Saber dışı yollar ve klasörler eşlenmez', () {
      expect(SaberSyncInterface.yerelGoreliYol('Saber/'), isNull);
      expect(SaberSyncInterface.yerelGoreliYol('Saber/Saha/'), isNull);
      expect(SaberSyncInterface.yerelGoreliYol('Saber'), isNull);
      expect(SaberSyncInterface.yerelGoreliYol('Baska/a.sbn2'), isNull);
      expect(SaberSyncInterface.yerelGoreliYol('SaberX/a.sbn2'), isNull);
    });

    test('yerel dosyadan SyncFile: düz uzak yol', () async {
      FileManager.documentsDirectory =
          '$tmpDir/esitleme_duz_test/${FileManager.appRootDirectoryPrefix}';
      stows.username.value = '';
      stows.ncPassword.value = '';
      final yerel = FileManager.getFile('/Saha/Kat 1/kolon.sbn2');
      final syncFile = await syncer.interface.getSyncFileFromLocalFile(yerel);
      expect(syncFile.remotePath, 'Saber/Saha/Kat 1/kolon.sbn2');
      expect(
        syncFile.relativeLocalPath.replaceAll('\\', '/'),
        endsWith('/Saha/Kat 1/kolon.sbn2'),
      );
    });
  });

  group('Yok sayılan dosyalar', () {
    test('eski şifreli biçim', () {
      for (final yol in [
        'Saber/4F2A9C.sbe',
        'Saber/klasor/4F2A9C.SBE',
        'Saber/4F2A9C.sbe.cakisma',
        'Saber/config.sbc',
        'Saber/klasor/config.sbc',
      ]) {
        expect(SaberSyncInterface.yerelGoreliYol(yol), isNull, reason: yol);
      }
    });

    test('noktalı dosya ve klasörler, Readme', () {
      for (final yol in [
        'Saber/.not/meta.json',
        'Saber/.gizli',
        'Saber/Saha/.DS_Store',
        'Saber/.cop/a.sbn2',
        'Saber/Readme.md',
      ]) {
        expect(SaberSyncInterface.yerelGoreliYol(yol), isNull, reason: yol);
      }
      expect(SaberSyncInterface.yoksayilirMi('/a.sbn2'), isFalse);
      expect(SaberSyncInterface.yoksayilirMi('/'), isTrue);
    });
  });

  group('Sunucu yanıtları', () {
    late HttpServer sunucu;
    late List<HttpRequest> istekler;
    int durum = 200;
    String govde = '';

    setUpAll(() async {
      HttpOverrides.global = null;
      FileManager.documentsDirectory =
          '$tmpDir/esitleme_duz_test_${randomString(6)}/'
          '${FileManager.appRootDirectoryPrefix}';
      await Directory(FileManager.documentsDirectory).create(recursive: true);
      sunucu = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      istekler = [];
      sunucu.listen((istek) async {
        istekler.add(istek);
        await istek.drain<void>();
        istek.response.statusCode = durum;
        if (durum == 207) {
          istek.response.headers.contentType = ContentType(
            'application',
            'xml',
            charset: 'utf-8',
          );
        } else {
          istek.response.headers.contentType = ContentType.text;
        }
        istek.response.add(utf8.encode(govde));
        await istek.response.close();
      });
      stows.url.value = 'http://127.0.0.1:${sunucu.port}';
      stows.username.value = 'deneme';
      stows.ncPassword.value = 'nes_${'x' * 24}';
      expect(stows.loggedIn, isTrue, reason: 'şifreleme parolası gerekmez');
    });

    tearDownAll(() => sunucu.close(force: true));

    setUp(() {
      istekler.clear();
      EsitlemeUyarisi.son.value = null;
    });

    test('PROPFIND Depth: infinity; klasörler ve eski dosyalar çıkar', () async {
      durum = 207;
      String yanit(String href, {bool klasor = false}) =>
          '<d:response><d:href>/remote.php/webdav/$href</d:href>'
          '<d:propstat><d:prop>'
          '<d:getlastmodified>Wed, 07 Oct 2026 10:00:00 GMT</d:getlastmodified>'
          '${klasor ? '<d:resourcetype><d:collection/></d:resourcetype>' : '<d:resourcetype/><d:getcontentlength>12</d:getcontentlength>'}'
          '</d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>'
          '</d:response>';
      govde =
          '<?xml version="1.0" encoding="utf-8"?>'
          '<d:multistatus xmlns:d="DAV:">'
          '${yanit('Saber/', klasor: true)}'
          '${yanit('Saber/a.sbn2')}'
          '${yanit('Saber/a.sbn2.p')}'
          '${yanit('Saber/Saha/', klasor: true)}'
          '${yanit('Saber/Saha/Kat%201/', klasor: true)}'
          '${yanit('Saber/Saha/Kat%201/kolon.sbn2')}'
          '${yanit('Saber/Saha/Kat%201/kolon.sbn2.0')}'
          '${yanit('Saber/%C5%9Eantiye.sbn2')}'
          '${yanit('Saber/4F2A.sbe')}'
          '${yanit('Saber/config.sbc')}'
          '</d:multistatus>';

      final dosyalar = await SaberSyncInterface.findRemoteFiles();
      expect(istekler, hasLength(1));
      expect(istekler.single.method, 'PROPFIND');
      expect(istekler.single.headers.value('depth'), 'infinity');
      expect(istekler.single.uri.path, '/remote.php/webdav/Saber');
      expect(dosyalar.map((f) => f.path.path).toSet(), {
        'Saber/a.sbn2',
        'Saber/a.sbn2.p',
        'Saber/Saha/Kat 1/kolon.sbn2',
        'Saber/Saha/Kat 1/kolon.sbn2.0',
        'Saber/Şantiye.sbn2',
      });

      final syncFile = await syncer.interface.getSyncFileFromRemoteFile(
        dosyalar.firstWhere((f) => f.path.path.endsWith('kolon.sbn2')),
      );
      expect(syncFile.remotePath, 'Saber/Saha/Kat 1/kolon.sbn2');
      expect(
        syncFile.relativeLocalPath.replaceAll('\\', '/'),
        '/Saha/Kat 1/kolon.sbn2',
      );
    });

    test('yükleme düz bayt gönderir, indirme düz bayt yazar', () async {
      final yerel = FileManager.getFile('/Saha/duz.sbn2');
      await yerel.create(recursive: true);
      final icerik = Uint8List.fromList(utf8.encode('düz içerik'));
      await yerel.writeAsBytes(icerik);
      final syncFile = SaberSyncFile(
        remoteFile: null,
        remotePath: 'Saber/Saha/duz.sbn2',
        localFile: yerel,
      );

      final okunan = await syncer.interface.readLocalFile(syncFile);
      expect(okunan, icerik);

      durum = 201;
      govde = '';
      await syncer.interface.uploadRemoteFile(syncFile, okunan);
      expect(istekler.single.method, 'PUT');
      expect(
        istekler.single.uri.path,
        '/remote.php/webdav/Saber/Saha/duz.sbn2',
      );
      expect(istekler.single.headers.value('x-oc-mtime'), isNotNull);

      await yerel.delete();
      await syncer.interface.writeLocalFile(
        syncFile,
        Uint8List.fromList(utf8.encode('sunucudan')),
        awaitWrite: true,
      );
      expect(await yerel.readAsString(), 'sunucudan');
    });

    test('403: sunucunun Türkçe mesajı gösterilir', () async {
      const mesaj =
          'Bu tarus Not sürümü şifreli eşitleme kullanıyor ve artık '
          "desteklenmiyor. tarus Not'u güncelleyin.";
      durum = 403;
      govde = mesaj;
      final yerel = FileManager.getFile('/ret.sbn2');
      await yerel.writeAsString('x');
      final syncFile = SaberSyncFile(
        remoteFile: null,
        remotePath: 'Saber/ret.sbn2',
        localFile: yerel,
      );
      await expectLater(
        syncer.interface.uploadRemoteFile(syncFile, Uint8List.fromList([1])),
        throwsA(isA<DynamiteStatusCodeException>()),
      );
      expect(
        EsitlemeUyarisi.son.value,
        const EsitlemeUyarisi(.reddedildi, mesaj),
      );

      // Başarılı yükleme uyarıyı siler.
      durum = 204;
      govde = '';
      await syncer.interface.uploadRemoteFile(
        syncFile,
        Uint8List.fromList([1]),
      );
      expect(EsitlemeUyarisi.son.value, isNull);
    });

    test('503: geçici uyarı, liste boş, yerel dosya silinmez', () async {
      durum = 503;
      govde = 'Anahtar servisine ulaşılamıyor';
      final yerel = FileManager.getFile('/korunan.sbn2');
      await yerel.writeAsString('yerel not');

      expect(await SaberSyncInterface.findRemoteFiles(), isEmpty);
      expect(EsitlemeUyarisi.son.value?.tur, EsitlemeUyariTuru.gecici);

      final syncFile = SaberSyncFile(
        remoteFile: null,
        remotePath: 'Saber/korunan.sbn2',
        localFile: yerel,
      );
      await expectLater(
        syncer.interface.downloadRemoteFile(syncFile),
        throwsA(isA<DynamiteStatusCodeException>()),
      );
      await expectLater(
        syncer.interface.uploadRemoteFile(syncFile, Uint8List.fromList([1])),
        throwsA(isA<DynamiteStatusCodeException>()),
      );
      expect(await yerel.readAsString(), 'yerel not');

      // Sunucu geri gelince geçici uyarı kalkar.
      durum = 207;
      govde =
          '<?xml version="1.0" encoding="utf-8"?><d:multistatus xmlns:d="DAV:">'
          '<d:response><d:href>/remote.php/webdav/Saber/</d:href>'
          '<d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype>'
          '</d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>'
          '</d:multistatus>';
      await SaberSyncInterface.findRemoteFiles();
      expect(EsitlemeUyarisi.son.value, isNull);
    });
  });

  group('EsitlemeUyarisi.hatadan', () {
    DynamiteStatusCodeException hata(int kod, String govde) =>
        DynamiteStatusCodeException(http.Response(govde, kod));

    test('403 ve 503 dışı hatalar uyarı değildir', () {
      expect(EsitlemeUyarisi.hatadan(hata(404, 'yok')), isNull);
      expect(EsitlemeUyarisi.hatadan(hata(500, 'x')), isNull);
      expect(EsitlemeUyarisi.hatadan(Exception('ağ')), isNull);
    });

    test('403 boş gövdede genel metne düşer', () {
      expect(
        EsitlemeUyarisi.hatadan(hata(403, '  ')),
        const EsitlemeUyarisi(.reddedildi),
      );
    });

    test('503 geçicidir', () {
      expect(
        EsitlemeUyarisi.hatadan(hata(503, 'x')),
        const EsitlemeUyarisi(.gecici),
      );
    });
  });

  group('Eski şifreleme kayıtları', () {
    test('ilk açılışta bir kez silinir', () async {
      stows.eskiSifrelemeSilindi.value = false;
      stows.eskiEncPassword.value = 'eski-parola';
      stows.eskiKey.value = 'anahtar';
      stows.eskiIv.value = 'iv';

      expect(await stows.eskiSifrelemeKayitlariniSil(), isTrue);
      expect(stows.eskiEncPassword.value, isEmpty);
      expect(stows.eskiKey.value, isEmpty);
      expect(stows.eskiIv.value, isEmpty);
      expect(stows.eskiSifrelemeSilindi.value, isTrue);

      // İkinci açılışta bir şey yapmaz.
      expect(await stows.eskiSifrelemeKayitlariniSil(), isFalse);
    });

    test('oturum yalnız belirteçle açık sayılır', () {
      stows.username.value = 'deneme';
      stows.ncPassword.value = 'nes_belirtec';
      expect(stows.loggedIn, isTrue);
      stows.ncPassword.value = '';
      expect(stows.loggedIn, isFalse);
    });
  });
}
