import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:saber/components/home/home_layout_button.dart';
import 'package:saber/components/home/masonry_files.dart';
import 'package:saber/components/home/secim_cubugu.dart';
import 'package:saber/components/home/syncing_button.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_olcu.dart';

class const RecentPage({super.key}) extends StatefulHookWidget {
  @override
  State<RecentPage> createState() => _RecentPageState();
}

class _RecentPageState extends State<RecentPage> {
  final List<String> filePaths = [];
  var failed = false;

  final ValueNotifier<List<String>> selectedFiles = ValueNotifier([]);

  final log = Logger('RecentPage');

  /// Mitigates a bug where files got imported starting with `null/` instead of `/`.
  ///
  /// This caused them to be written to `Documents/Sabernull/...` instead of `Documents/Saber/...`.
  ///
  /// See https://github.com/saber-notes/saber/issues/996
  /// and https://github.com/saber-notes/saber/pull/977.
  void moveIncorrectlyImportedFiles() async {
    for (final filePath in stows.recentFiles.value) {
      if (filePath.startsWith('/')) continue;

      final String newFilePath;
      if (filePath.startsWith('null/')) {
        newFilePath = await FileManager.suffixFilePathToMakeItUnique(
          filePath.substring('null'.length),
        );
      } else {
        newFilePath = await FileManager.suffixFilePathToMakeItUnique(
          '/$filePath',
        );
      }

      log.warning(
        'Found incorrectly imported file at `$filePath`; moving to `$newFilePath`',
      );
      await FileManager.moveFile(filePath, newFilePath);
    }
  }

  @override
  void initState() {
    findRecentlyAccessedNotes();
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );
    selectedFiles.addListener(_setState);

    super.initState();
    moveIncorrectlyImportedFiles();
  }

  @override
  void dispose() {
    selectedFiles.removeListener(_setState);
    fileWriteSubscription?.cancel();
    super.dispose();
  }

  StreamSubscription? fileWriteSubscription;
  void fileWriteListener(FileOperation event) {
    findRecentlyAccessedNotes(fromFileListener: true);
  }

  void _setState() => setState(() {});

  Future findRecentlyAccessedNotes({bool fromFileListener = false}) async {
    if (!mounted) return;

    if (fromFileListener) {
      // don't refresh if we're not on the home page
      final location = GoRouterState.of(context).uri.toString();
      if (!location.startsWith(RoutePaths.prefixOfHome)) return;
    }

    final children = await FileManager.getRecentlyAccessed();
    filePaths.clear();
    if (children.isEmpty) {
      failed = true;
    } else {
      failed = false;
      filePaths.addAll(children);
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = MediaQuery.sizeOf(context).width ~/ 300 + 1;
    useListenable(stows.homeLayout);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          TarusSayfaUstu(
            baslik: t.home.titles.home,
            eylemler: const [HomeLayoutButton(), SyncingButton()],
          ),
          if (failed) ...[
            SliverSafeArea(
              top: false,
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: TarusBosDurum(
                  isaret: true,
                  baslik: t.tarus.bos.hicNotYok,
                  aciklama: t.tarus.bos.yeniNotIcinArti,
                ),
              ),
            ),
          ] else ...[
            SliverPadding(
              padding: const .symmetric(horizontal: TarusOlcu.sayfaYatay),
              sliver: SliverToBoxAdapter(
                child: TarusBolumEtiketi(
                  t.tarus.sonNotlar,
                  padding: const .fromLTRB(4, 4, 4, 4),
                ),
              ),
            ),
            SliverSafeArea(
              top: false,
              minimum: const .only(bottom: TarusOlcu.aralik),
              sliver: MasonryFiles(
                crossAxisCount: crossAxisCount,
                files: [for (final filePath in filePaths) filePath],
                selectedFiles: selectedFiles,
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: selectedFiles.value.isEmpty
          ? null
          : SecimCubugu(selectedFiles: selectedFiles),
    );
  }
}
