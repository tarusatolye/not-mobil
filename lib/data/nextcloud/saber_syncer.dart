import 'dart:async';
import 'dart:io';

import 'package:abstract_sync/abstract_sync.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:nextcloud/webdav.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/nextcloud/esitleme_uyarisi.dart';
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/prefs.dart';

final syncer = Syncer<SaberSyncInterface, SaberSyncFile, File, WebDavFile>(
  const SaberSyncInterface(),
  failureTimeout: const Duration(seconds: 4),
);

class const SaberSyncInterface()
    extends AbstractSyncInterface<SaberSyncFile, File, WebDavFile> {
  static final log = Logger('SaberSyncInterface');

  @override
  bool areRemoteFilesEqual(WebDavFile a, WebDavFile b) => a.path == b.path;

  @override
  bool areLocalFilesEqual(File a, File b) => a.path == b.path;

  @override
  Future<List<SaberSyncFile>> findLocalChanges() async {
    for (var tries = 0; tries < 10 && remoteFiles.isEmpty; ++tries) {
      // Wait for [findRemoteChanges] to populate [remoteFiles]
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final syncFiles = <SaberSyncFile>[];
    await for (final localFile in FileManager.getRootDirectory().list(
      recursive: true,
    )) {
      if (localFile is! File) continue;
      if (yoksayilirMi(_yerelGoreli(localFile))) continue;

      final syncFile = await getSyncFileFromLocalFile(localFile);

      final bestFile = await getBestFile(
        syncFile,
        onLocalFileNotFound: .local,
        onEqualFiles: .remote,
      );
      switch (bestFile) {
        case .local:
          syncFiles.add(syncFile);
        case .remote:
          // Remote file is newer, do nothing
          break;
      }
    }
    return syncFiles;
  }

  @override
  Future<List<SaberSyncFile>> findRemoteChanges() async {
    final client = SaberSyncInterface.client;
    if (client == null) return const [];

    remoteFiles = await findRemoteFiles();
    if (remoteFiles.isEmpty) return const [];

    final List<SaberSyncFile> changedFiles = await Future.wait(
      remoteFiles.map((remoteFile) async {
        final SaberSyncFile syncFile;
        try {
          syncFile = await getSyncFileFromRemoteFile(remoteFile);
        } catch (e, st) {
          log.warning('Failed to get sync file from remote file: $e', e, st);
          return null;
        }

        final bestFile = await getBestFile(
          syncFile,
          onLocalFileNotFound: .remote,
          onEqualFiles: .local,
        );
        switch (bestFile) {
          case .local:
            // Local file is newer, do nothing
            return null;
          case .remote:
            // Remote file is newer or doesn't exist locally

            final remotelyDeleted = syncFile.remoteFile!.size! <= 0;
            final locallyDeleted = stows.fileSyncAlreadyDeleted.value.contains(
              syncFile.relativeLocalPath,
            );
            if (remotelyDeleted && locallyDeleted) break;

            return syncFile;
        }
      }),
    ).then((list) => list.nonNulls.toList());

    // Prioritize note.sbn2.p over note.sbn2 (so the preview is updated first)
    final previewSyncFiles = changedFiles
        .where((syncFile) => syncFile.localFile.path.endsWith('.p'))
        .toList(growable: false);
    for (final previewSyncFile in previewSyncFiles) {
      final previewSyncFileIndex = changedFiles.indexOf(previewSyncFile);
      final mainSyncFileIndex = changedFiles.indexWhere(
        (syncFile) =>
            syncFile.localFile.path ==
            previewSyncFile.localFile.path.substring(
              0,
              previewSyncFile.localFile.path.length - 2,
            ),
      );
      if (previewSyncFileIndex <= -1 || mainSyncFileIndex <= -1) continue;

      if (previewSyncFileIndex >= mainSyncFileIndex) {
        changedFiles
          ..removeAt(previewSyncFileIndex)
          ..insert(mainSyncFileIndex, previewSyncFile);
      } else {
        changedFiles
          ..removeAt(previewSyncFileIndex)
          ..insert(mainSyncFileIndex - 1, previewSyncFile);
      }
    }

    return changedFiles;
  }

  @override
  Future<SaberSyncFile> getSyncFileFromLocalFile(File localFile) async {
    final remotePath = uzakYol(_yerelGoreli(localFile));
    final remoteFile = await getWebDavFile(remotePath);

    return SaberSyncFile(
      remoteFile: remoteFile,
      remotePath: remotePath,
      localFile: localFile,
    );
  }

  @override
  Future<SaberSyncFile> getSyncFileFromRemoteFile(WebDavFile remoteFile) async {
    final relativeLocalPath = yerelGoreliYol(remoteFile.path.path);
    if (relativeLocalPath == null)
      throw Exception('Not a syncable note file: ${remoteFile.path.path}');
    final localFile = FileManager.getFile(relativeLocalPath);

    return SaberSyncFile(remoteFile: remoteFile, localFile: localFile);
  }

  @override
  Future<Uint8List> downloadRemoteFile(SaberSyncFile file) async {
    if (file.remoteFile?.size == 0) {
      // Deleted file, handle in [writeLocalFile]
      return Uint8List(0);
    }

    final client = SaberSyncInterface.client;
    if (client == null)
      throw Exception('Tried to download file without being logged in');

    try {
      final bytes = await client.webdav.get(PathUri.parse(file.remotePath));
      EsitlemeUyarisi.sunucuYanitVerdi();
      return bytes;
    } catch (e) {
      // 503: sunucu geçici olarak kapalı; hata yeniden denemeyi tetikler,
      // yerel dosyaya dokunulmaz.
      EsitlemeUyarisi.kaydet(e);
      rethrow;
    }
  }

  @override
  Future<void> writeLocalFile(
    SaberSyncFile file,
    Uint8List bytes, {
    @visibleForTesting bool awaitWrite = false,
  }) async {
    if (bytes.isEmpty) {
      // Remote file was deleted
      await FileManager.deleteFile(file.relativeLocalPath, alsoUpload: false);
      stows.fileSyncAlreadyDeleted.value.add(file.relativeLocalPath);
      stows.fileSyncAlreadyDeleted.notifyListeners();
      return;
    }

    // Notlar sunucuyla düz eşitlenir (sunucu diskte şifreli saklar).
    await FileManager.writeFile(
      file.relativeLocalPath,
      bytes,
      awaitWrite: awaitWrite,
      alsoUpload: false,
      // Local file should have the same last modified date as remote
      lastModified: file.remoteFile?.lastModified,
    );
  }

  @override
  Future<Uint8List> readLocalFile(SaberSyncFile file) async {
    // Boş dizi = silinmiş dosya; [uploadRemoteFile] 0 baytlık silme işareti yazar.
    return file.localFile.existsSync()
        ? await file.localFile.readAsBytes()
        : Uint8List(0);
  }

  @override
  Future<void> uploadRemoteFile(SaberSyncFile file, Uint8List bytes) async {
    DateTime lastModified;
    try {
      lastModified = file.localFile.lastModifiedSync();
    } on FileSystemException {
      lastModified = DateTime.now();
    }
    if (lastModified.isBefore(stows.fileSyncResyncEverythingDate.value)) {
      lastModified = stows.fileSyncResyncEverythingDate.value;
    }

    final client = SaberSyncInterface.client;
    if (client == null)
      throw Exception('Tried to upload file without being logged in');

    final Map<String, String> yanitBasliklari;
    try {
      final yanit = await client.webdav.put(
        bytes,
        PathUri.parse(file.remotePath),
        lastModified: lastModified,
      );
      yanitBasliklari = yanit.headers;
    } catch (e) {
      // 403 (sunucu reddetti, ör. eski şifreli dosya) ve 503 (geçici)
      // kullanıcıya gösterilir; hata yeniden denemeyi tetikler.
      EsitlemeUyarisi.kaydet(e);
      rethrow;
    }
    EsitlemeUyarisi.yuklemeBasarili();

    // Not sunucusu habersiz değişikliği "(çakışma - …)" kopyası olarak saklar;
    // kopyanın telefona da gelmesi için listeyi yenile.
    if (yanitBasliklari.containsKey(cakismaBasligi)) {
      log.info('Conflict copy created on server for ${file.remotePath}');
      unawaited(syncer.downloader.refresh());
    }
  }

  static NextcloudClient? _client;
  static NextcloudClient? get client {
    if (_client?.authentications?.isEmpty ?? true) {
      _client = NextcloudClientExtension.withSavedDetails();
    }
    return _client;
  }

  /// A list of remote files from server,
  /// used to speed up [getSyncFileFromLocalFile].
  ///
  /// This is set in [findRemoteFiles], and may be empty
  /// or incomplete if [findRemoteFiles] has not been called recently.
  static var remoteFiles = <WebDavFile>{};

  /// Sunucudaki notları tek PROPFIND (`Depth: infinity`) ile listeler;
  /// klasörler ve eşitlenmeyen dosyalar ([yoksayilirMi]) çıkarılır.
  static Future<Set<WebDavFile>> findRemoteFiles() async {
    final client = SaberSyncInterface.client;
    if (client == null) return {};

    try {
      final multistatus = await client.webdav.propfind(
        PathUri.parse(FileManager.appRootDirectoryPrefix),
        prop: const WebDavPropWithoutValues.fromBools(
          davGetcontentlength: true,
          davGetlastmodified: true,
          davResourcetype: true,
        ),
        depth: WebDavDepth.infinity,
      );
      EsitlemeUyarisi.sunucuYanitVerdi();
      return multistatus
          .toWebDavFiles()
          .where(
            (file) =>
                !file.isDirectory && yerelGoreliYol(file.path.path) != null,
          )
          .toSet();
    } on DynamiteStatusCodeException catch (e, st) {
      if (e.statusCode == HttpStatus.notFound) {
        log.info('findRemoteFiles: Creating app directory', e, st);
        await client.webdav.mkcol(
          PathUri.parse(FileManager.appRootDirectoryPrefix),
        );
        return {};
      } else {
        // 503 dahil: boş liste döner, yerel dosyalar silinmez.
        EsitlemeUyarisi.kaydet(e);
        log.severe('Failed to get list of remote files: $e', e, st);
        if (kDebugMode && e.statusCode != HttpStatus.serviceUnavailable)
          rethrow;
        return {};
      }
    } on SocketException catch (e, st) {
      log.warning('findRemoteFiles: Network error: $e', e, st);
      return {};
    } catch (e, st) {
      log.severe('findRemoteFiles: Unknown error: $e', e, st);
      if (kDebugMode) rethrow;
      return {};
    }
  }

  /// Yerel göreli yol (`/klasör/ad.sbn2`) → sunucu yolu
  /// (`Saber/klasör/ad.sbn2`). Notlar düz yolla eşitlenir.
  static String uzakYol(String goreliYerelYol) {
    assert(goreliYerelYol.startsWith('/'), goreliYerelYol);
    return '${FileManager.appRootDirectoryPrefix}$goreliYerelYol';
  }

  /// Sunucu yolu (`Saber/klasör/ad.sbn2`) → yerel göreli yol
  /// (`/klasör/ad.sbn2`). Saber klasörü dışındaki yollarda, klasörlerde ve
  /// eşitlenmeyen dosyalarda ([yoksayilirMi]) `null`.
  static String? yerelGoreliYol(String uzakYol) {
    const onek = '${FileManager.appRootDirectoryPrefix}/';
    final yol = uzakYol.startsWith('/') ? uzakYol.substring(1) : uzakYol;
    if (!yol.startsWith(onek)) return null;
    if (yol.endsWith('/')) return null;
    final goreli = yol.substring(onek.length - 1);
    if (yoksayilirMi(goreli)) return null;
    return goreli;
  }

  /// Eşitlenmeyen dosyalar: eski uçtan uca şifreli biçim (`.sbe`,
  /// `.sbe.cakisma`, `config.sbc` — sunucu 403 ile reddeder), noktayla
  /// başlayan dosya/klasörler (sunucunun `.not` meta klasörü vb.) ve Readme.
  static bool yoksayilirMi(String goreliYol) {
    final parcalar = goreliYol.split('/').where((p) => p.isNotEmpty).toList();
    if (parcalar.isEmpty) return true;
    if (parcalar.any((p) => p.startsWith('.'))) return true;
    final ad = parcalar.last.toLowerCase();
    if (ad == configDosyasi) return true;
    if (ad.endsWith(eskiSifreliUzanti)) return true;
    if (ad.endsWith('$eskiSifreliUzanti.cakisma')) return true;
    if (ad == 'readme.md') return true;
    return false;
  }

  static String _yerelGoreli(File localFile) => localFile.path
      .substring(FileManager.documentsDirectory.length)
      // Compensate for Windows using backslashes
      .replaceAll(Platform.pathSeparator, '/');

  /// Returns the best file to keep, local or remote.
  ///
  /// If the local file doesn't exist, [onLocalFileNotFound] is returned.
  ///
  /// If the remote and local files have the same last modified date,
  /// [onEqualFiles] is returned.
  static Future<BestFile> getBestFile(
    SaberSyncFile file, {
    required BestFile onLocalFileNotFound,
    required BestFile onEqualFiles,
    bool preferCache = true,
  }) async {
    if (!file.localFile.existsSync()) {
      // We either have a new remote file or a deleted local file
      return onLocalFileNotFound;
    }

    // get remote file
    file.remoteFile = await _getWebDavFileStatic(
      file.remotePath,
      preferCache: preferCache,
    );
    if (file.remoteFile == null) {
      // Remote file doesn't exist, keep local
      return .local;
    }

    final lastModifiedRemote = file.remoteFile!.lastModified;
    if (lastModifiedRemote == null) {
      // Remote file doesn't exist, keep local
      return .local;
    } else if (lastModifiedRemote.isBefore(
      stows.fileSyncResyncEverythingDate.value,
    )) {
      // If we've prompted a full resync at [resyncEverythingDate],
      // keep the local file if it was modified before [resyncEverythingDate]
      return .local;
    }

    // File exists locally, check if it's newer than the remote file
    final lastModifiedLocal = file.localFile.lastModifiedSync();
    if (lastModifiedRemote.difference(lastModifiedLocal).abs() <
        const Duration(milliseconds: 500)) {
      return onEqualFiles;
    } else if (lastModifiedRemote.isAfter(lastModifiedLocal)) {
      return .remote;
    } else {
      return .local;
    }
  }

  Future<WebDavFile?> getWebDavFile(
    String remotePath, {
    bool preferCache = true,
  }) => _getWebDavFileStatic(remotePath, preferCache: preferCache);

  static Future<WebDavFile?> _getWebDavFileStatic(
    String remotePath, {
    bool preferCache = true,
  }) async {
    final cachedWebDavFile = remoteFiles.firstWhereOrNull(
      (remoteFile) => remoteFile.path.path == remotePath,
    );
    if (preferCache && cachedWebDavFile != null) return cachedWebDavFile;

    final webDavFile = await _getWebDavFileUncached(remotePath);
    if (webDavFile != null) {
      remoteFiles
        ..remove(cachedWebDavFile)
        ..add(webDavFile);
    }
    return webDavFile ?? cachedWebDavFile;
  }

  static Future<WebDavFile?> _getWebDavFileUncached(String remotePath) async {
    final client = SaberSyncInterface.client;
    if (client == null) return null;

    try {
      return await client.webdav
          .propfind(
            PathUri.parse(remotePath),
            prop: const WebDavPropWithoutValues.fromBools(
              davGetcontentlength: true,
              davGetlastmodified: true,
            ),
          )
          .then((multistatus) => multistatus.toWebDavFiles().first);
    } catch (e, st) {
      log.fine('Remote file not found for $remotePath: $e', e, st);
    }

    return null;
  }

  /// Eski (1.1.5 ve öncesi) uçtan uca şifreli notun uzantısı; artık eşitlenmez.
  static const eskiSifreliUzanti = '.sbe';

  /// Eski şifreleme anahtarı dosyası; artık eşitlenmez.
  static const configDosyasi = 'config.sbc';

  /// Not sunucusu habersiz değişikliğin kopyasını saklayınca bu başlığı döner.
  static const cakismaBasligi = 'x-not-cakisma';
}

class SaberSyncFile extends AbstractSyncFile<File, WebDavFile> {
  late final relativeLocalPath = localFile.path.substring(
    FileManager.documentsDirectory.length,
  );

  late String remotePath;

  new({required super.remoteFile, String? remotePath, required super.localFile})
    : assert(
        remotePath != null || remoteFile != null,
        'At least one of remotePath or remoteFile must be provided',
      ) {
    this.remotePath = remotePath ?? remoteFile!.path.path;
  }

  static Future<SaberSyncFile> relative(String relativeFilePath) {
    final localFile = FileManager.getFile(relativeFilePath);
    return const SaberSyncInterface().getSyncFileFromLocalFile(localFile);
  }

  @override
  String toString() =>
      'SaberSyncFile(local: $relativeLocalPath, remote: $remotePath)';

  @override
  bool operator ==(Object other) =>
      other is SaberSyncFile && other.localFile.path == localFile.path;

  @override
  int get hashCode => localFile.path.hashCode;
}

extension SaberSyncerComponent on SyncerComponent {
  Future<bool> enqueueRel(String relativeFilePath) async {
    if (!stows.loggedIn) return false;

    final syncFile = await SaberSyncFile.relative(relativeFilePath);
    return enqueue(syncFile: syncFile);
  }
}

enum BestFile { local, remote }
