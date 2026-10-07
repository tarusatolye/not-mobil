import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:nextcloud/webdav.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/nextcloud/pusula_belirteci.dart';
import 'package:saber/data/nextcloud/saber_syncer.dart';
import 'package:saber/data/prefs.dart';

import 'utils/test_mock_channel_handlers.dart';
import 'utils/test_random.dart';

/// Gerçek tarus Not sunucusuyla (not deposu) uçtan uca eşitleme.
///
/// Not sunucusunu yerel kimlikle başlatıp adresini verin:
///   (not) NOT_YEREL_GELISTIRME=1 KMS_SAGLAYICI=yerel PORT=3999 node server/server.js
///   NOT_SUNUCU_URL=http://127.0.0.1:3999 NOT_ESITLEME_BELIRTECI=yerel-esitleme \
///     flutter test test/not_sunucu_esitleme_test.dart
/// Ortam değişkeni yoksa test atlanır (CI'da sunucu yok).
void main() {
  final adres = Platform.environment['NOT_SUNUCU_URL'];
  final belirtec =
      Platform.environment['NOT_ESITLEME_BELIRTECI'] ?? 'yerel-esitleme';

  test('Pusula belirteciyle bağlan, yükle, listele, indir', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null;
    setupMockPathProvider();
    setupMockFlutterSecureStorage();

    FileManager.documentsDirectory =
        '$tmpDir/not_sunucu_esitleme_test/${FileManager.appRootDirectoryPrefix}';
    FlavorConfig.setup();
    await FileManager.init();

    final sunucu = Uri.parse(adres!);
    final kullanici = await PusulaBelirteci.dogrula(
      sunucu: sunucu,
      belirtec: belirtec,
    );
    expect(kullanici, isNotEmpty);
    PusulaBelirteci.kaydet(
      sunucu: sunucu,
      kullaniciAdi: kullanici,
      belirtec: belirtec,
    );
    // 1.1.6: şifreleme parolası yok; belirteç yeter.
    expect(stows.loggedIn, isTrue);
    final client = SaberSyncInterface.client!;
    // Saber klasörü yoksa listeleme onu kurar (MKCOL).
    await SaberSyncInterface.findRemoteFiles();

    final yerel = FileManager.getFile('/saha/kolon${randomString(8)}.sbn2');
    final syncFile = await syncer.interface.getSyncFileFromLocalFile(yerel);
    const icerik = 'tarus not eşitleme denemesi';
    await yerel.create(recursive: true);
    await yerel.writeAsString(icerik);

    expect(syncFile.remotePath, startsWith('Saber/saha/kolon'));
    expect(syncFile.remotePath, endsWith('.sbn2'));

    final yukle = await syncer.interface.readLocalFile(syncFile);
    // Düz: dosya baytları olduğu gibi gider.
    expect(yukle, equals(await yerel.readAsBytes()));
    await syncer.interface.uploadRemoteFile(syncFile, yukle);

    // PROPFIND: sunucunun listesi Nextcloud istemcisince çözülebilmeli.
    final uzaktakiler = await SaberSyncInterface.findRemoteFiles();
    expect(uzaktakiler.map((f) => f.path.path), contains(syncFile.remotePath));
    final uzak = uzaktakiler.firstWhere(
      (f) => f.path.path == syncFile.remotePath,
    );
    expect(uzak.size, yukle.length);
    expect(
      uzak.lastModified!.difference(yerel.lastModifiedSync()).inSeconds.abs(),
      lessThanOrEqualTo(1),
      reason:
          'X-OC-Mtime korunmalı; yoksa her eşitlemede dosya yeniden indirilir',
    );

    final indir = await syncer.interface.downloadRemoteFile(syncFile);
    expect(indir, equals(yukle));
    await yerel.delete();
    await syncer.interface.writeLocalFile(syncFile, indir, awaitWrite: true);
    expect(await yerel.readAsString(), icerik);

    // Eski şifreli biçim sunucuda reddedilir (403, Türkçe mesaj).
    await expectLater(
      client.webdav.put(
        Uint8List.fromList([1, 2, 3]),
        PathUri.parse('Saber/eski.sbe'),
      ),
      throwsA(
        isA<DynamiteStatusCodeException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.response.body, 'body', contains('güncelleyin')),
      ),
    );

    // Var olan klasöre MKCOL: Saber 405 bekler.
    await expectLater(
      client.webdav.mkcol(PathUri.parse(FileManager.appRootDirectoryPrefix)),
      throwsA(anything),
    );
  }, skip: adres == null ? 'NOT_SUNUCU_URL tanımlı değil' : false);
}
