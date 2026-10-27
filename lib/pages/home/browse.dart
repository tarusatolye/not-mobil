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
import 'package:saber/tarus/not_aramasi.dart';
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

  /// Arama: tüm notlar ve klasörler (web `notAramasi` / `notGenelAramasi` eşi).
  var aramaAcik = false;
  final aramaDenetleyici = TextEditingController();
  List<String> _tumNotlar = const [];
  List<String> _tumKlasorler = const [];

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
    aramaDenetleyici.dispose();
    fileWriteSubscription?.cancel();
    super.dispose();
  }

  StreamSubscription? fileWriteSubscription;
  void fileWriteListener(FileOperation event) {
    if (!event.filePath.startsWith(path ?? '/')) return;
    findChildrenOfPath(fromFileListener: true);
  }

  void _setState() => setState(() {});

  /// Kökten bütün klasör yolları (boş klasörler dahil) ve not yolları.
  Future<void> _aramaDizininiYukle() async {
    final notlar = <String>[];
    final klasorler = <String>[];
    final bekleyen = <String>['/'];
    while (bekleyen.isNotEmpty) {
      final dizin = bekleyen.removeLast();
      final cocuklar = await FileManager.getChildrenOfDirectory(dizin);
      if (cocuklar == null) continue;
      for (final dosya in cocuklar.files) {
        notlar.add('$dizin$dosya');
      }
      for (final klasor in cocuklar.directories) {
        klasorler.add('$dizin$klasor');
        bekleyen.add('$dizin$klasor/');
      }
    }
    if (!mounted) return;
    setState(() {
      _tumNotlar = notlar;
      _tumKlasorler = klasorler;
    });
  }

  void aramayiAcKapat() {
    setState(() {
      aramaAcik = !aramaAcik;
      aramaDenetleyici.clear();
      selectedFiles.value = [];
    });
    if (aramaAcik) _aramaDizininiYukle();
  }

  void aramadanKlasoreGit(String klasorYolu) {
    setState(() {
      aramaAcik = false;
      aramaDenetleyici.clear();
    });
    onPathComponentTap(klasorYolu);
  }

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

  List<Widget> _aramaSonuclari(int crossAxisCount) {
    final sorgu = aramaDenetleyici.text;
    if (sorgu.trim().isEmpty) return const [];
    final sonuclar = notAra(
      notlar: _tumNotlar,
      klasorler: _tumKlasorler,
      sorgu: sorgu,
    );
    final klasorler = [
      for (final s in sonuclar)
        if (s.tur == NotAramaTuru.klasor) s,
    ];
    final notlar = [
      for (final s in sonuclar)
        if (s.tur == NotAramaTuru.not) s.yol,
    ];

    if (sonuclar.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: TarusBosDurum(
            ikon: TarusIkon.ara,
            baslik: t.tarus.aramaSonucYok,
          ),
        ),
      ];
    }
    return [
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
        SliverList.builder(
          itemCount: klasorler.length,
          itemBuilder: (context, i) => ListTile(
            leading: const Icon(TarusIkon.klasor),
            title: Text(klasorler[i].ad),
            subtitle: Text(klasorler[i].ustKlasor),
            onTap: () => aramadanKlasoreGit(klasorler[i].yol),
          ),
        ),
      ],
      if (notlar.isNotEmpty) ...[
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
            files: notlar,
            selectedFiles: selectedFiles,
          ),
        ),
      ],
    ];
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
                tooltip: t.tarus.ara,
                onPressed: aramayiAcKapat,
                icon: Icon(aramaAcik ? TarusIkon.kapat : TarusIkon.ara),
              ),
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
          if (aramaAcik) ...[
            SliverPadding(
              padding: const .symmetric(
                horizontal: TarusOlcu.sayfaYatay,
                vertical: 4,
              ),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: aramaDenetleyici,
                  autofocus: true,
                  textInputAction: .search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: t.tarus.aramaYerTutucu,
                    prefixIcon: const Icon(TarusIkon.ara),
                  ),
                ),
              ),
            ),
            ..._aramaSonuclari(crossAxisCount),
          ] else ...[
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
          ], // aramaAcik değil
        ],
      ),
      bottomNavigationBar: selectedFiles.value.isEmpty
          ? null
          : SecimCubugu(selectedFiles: selectedFiles),
    );
  }
}
