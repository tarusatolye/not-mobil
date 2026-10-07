import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:saber/components/home/grid_folders.dart';
import 'package:saber/components/home/home_layout_button.dart';
import 'package:saber/components/home/masonry_files.dart';
import 'package:saber/components/home/new_folder_dialog.dart';
import 'package:saber/components/home/path_components.dart';
import 'package:saber/components/home/secim_cubugu.dart';
import 'package:saber/components/home/sort_button.dart';
import 'package:saber/components/home/syncing_button.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';

class BrowsePage extends StatefulHookWidget {
  const new({super.key, String? path}) : initialPath = path;

  final String? initialPath;

  @visibleForTesting
  static DirectoryChildren? overrideChildren;

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  DirectoryChildren? children;

  String? path;

  final ValueNotifier<List<String>> selectedFiles = ValueNotifier([]);

  @override
  void initState() {
    path = widget.initialPath;

    findChildrenOfPath();
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );
    selectedFiles.addListener(_setState);

    super.initState();
  }

  @override
  void dispose() {
    selectedFiles.removeListener(_setState);
    fileWriteSubscription?.cancel();
    super.dispose();
  }

  StreamSubscription? fileWriteSubscription;
  void fileWriteListener(FileOperation event) {
    if (!event.filePath.startsWith(path ?? '/')) return;
    findChildrenOfPath(fromFileListener: true);
  }

  void _setState() => setState(() {});

  Future findChildrenOfPath({bool fromFileListener = false}) async {
    if (!mounted) return;

    if (fromFileListener) {
      // don't refresh if we're not on the home page
      final location = GoRouterState.of(context).uri.toString();
      if (!location.startsWith(RoutePaths.prefixOfHome)) return;
    }

    children =
        BrowsePage.overrideChildren ??
        await FileManager.getChildrenOfDirectory(
          path ?? '/',
          sortMetric: stows.browseSortMetric.value,
        );

    if (mounted) setState(() {});
  }

  void onDirectoryTap(String folder) {
    selectedFiles.value = [];
    if (folder == '..') {
      path = p.dirname(path ?? '/');
      if (path == '/') path = null;
    } else {
      path = p.join(path ?? '/', folder);
    }
    context.go(HomeRoutes.browseFilePath(path ?? '/'));
    findChildrenOfPath();
  }

  void onPathComponentTap(String? newPath) {
    selectedFiles.value = [];
    if (newPath == null || newPath.isEmpty || newPath == '/') {
      newPath = null;
    }
    path = newPath;
    context.go(HomeRoutes.browseFilePath(path ?? '/'));
    findChildrenOfPath();
  }

  Future<void> createFolder(String folderName) async {
    final folderPath = '${path ?? ''}/$folderName';
    await FileManager.createFolder(folderPath);
    findChildrenOfPath();
  }

  void yeniKlasor() {
    showDialog(
      context: context,
      builder: (context) => NewFolderDialog(
        createFolder: createFolder,
        doesFolderExist: (String folderName) =>
            children?.directories.contains(folderName) ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genislik = MediaQuery.sizeOf(context).width;
    final crossAxisCount = genislik ~/ 300 + 1;
    final klasorSutun = (genislik ~/ 220).clamp(2, 6);
    useListenable(stows.homeLayout);
    useOnListenableChange(stows.browseSortMetric, findChildrenOfPath);

    final klasorler = children?.directories ?? const <String>[];
    final dosyalar = children?.files ?? const <String>[];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          TarusSayfaUstu(
            baslik: t.home.titles.browse,
            eylemler: [
              IconButton(
                tooltip: t.home.newFolder.newFolder,
                onPressed: yeniKlasor,
                icon: const Icon(TarusIkon.yeniKlasor),
              ),
              const BrowseSortButton(),
              const HomeLayoutButton(),
              const SyncingButton(),
            ],
          ),
          SliverPadding(
            padding: const .symmetric(horizontal: TarusOlcu.sayfaYatay - 4),
            sliver: SliverToBoxAdapter(
              child: PathComponents(
                path,
                onPathComponentTap: onPathComponentTap,
                onBack: () => onDirectoryTap('..'),
              ),
            ),
          ),
          if (klasorler.isNotEmpty) ...[
            SliverPadding(
              padding: const .symmetric(horizontal: TarusOlcu.sayfaYatay),
              sliver: SliverToBoxAdapter(
                child: TarusBolumEtiketi(
                  t.tarus.klasorler,
                  padding: const .fromLTRB(4, 8, 4, 8),
                ),
              ),
            ),
            GridFolders(
              crossAxisCount: klasorSutun,
              onTap: onDirectoryTap,
              doesFolderExist: (String folderName) {
                return children?.directories.contains(folderName) ?? false;
              },
              renameFolder: (String oldName, String newName) async {
                final oldPath = '${path ?? ''}/$oldName';
                await FileManager.renameDirectory(oldPath, newName);
                findChildrenOfPath();
              },
              isFolderEmpty: (String folderName) async {
                final folderPath = '${path ?? ''}/$folderName';
                final children = await FileManager.getChildrenOfDirectory(
                  folderPath,
                );
                return children?.isEmpty ?? true;
              },
              deleteFolder: (String folderName) async {
                final folderPath = '${path ?? ''}/$folderName';
                await FileManager.deleteDirectory(folderPath);
                findChildrenOfPath();
              },
              folders: klasorler,
            ),
          ],
          if (children == null) ...[
            // yükleniyor
          ] else if (dosyalar.isEmpty) ...[
            SliverSafeArea(
              top: false,
              sliver: SliverToBoxAdapter(
                child: TarusBosDurum(
                  ikon: TarusIkon.notlar,
                  baslik: path == null
                      ? t.tarus.bos.hicNotYok
                      : t.tarus.bos.klasordeNotYok,
                  aciklama: t.tarus.bos.yeniNotIcinArti,
                ),
              ),
            ),
          ] else ...[
            SliverPadding(
              padding: const .symmetric(horizontal: TarusOlcu.sayfaYatay),
              sliver: SliverToBoxAdapter(
                child: TarusBolumEtiketi(
                  t.tarus.notlar,
                  padding: const .fromLTRB(4, 14, 4, 4),
                ),
              ),
            ),
            SliverSafeArea(
              top: false,
              minimum: const .only(bottom: TarusOlcu.aralik),
              sliver: MasonryFiles(
                crossAxisCount: crossAxisCount,
                files: [
                  for (final filePath in dosyalar) "${path ?? ""}/$filePath",
                ],
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
