import 'package:flutter/material.dart';
import 'package:saber/components/canvas/canvas_gesture_detector.dart';
import 'package:saber/components/canvas/canvas_preview.dart';
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';

class EditorPageManager extends StatefulWidget {
  const new({
    super.key,
    required this.coreInfo,
    required this.currentPageIndex,
    required this.redrawAndSave,
    required this.insertPageAfter,
    required this.duplicatePage,
    required this.clearPage,
    required this.deletePage,
    required this.transformationController,
  });

  final EditorCoreInfo coreInfo;
  final int? currentPageIndex;
  final VoidCallback redrawAndSave;

  final void Function(int) insertPageAfter;
  final void Function(int) duplicatePage;
  final void Function(int) clearPage;
  final void Function(int) deletePage;

  final TransformationController transformationController;

  @override
  State<EditorPageManager> createState() => _EditorPageManagerState();
}

class _EditorPageManagerState extends State<EditorPageManager> {
  void scrollToPage(int pageIndex) => CanvasGestureDetector.scrollToPage(
    pageIndex: pageIndex,
    pages: widget.coreInfo.pages,
    screenWidth: MediaQuery.sizeOf(context).width,
    transformationController: widget.transformationController,
  );

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final sayfaSayisi = widget.coreInfo.pages.length;
    return SizedBox(
      width: 320,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        buildDefaultDragHandles: false,
        itemCount: sayfaSayisi,
        // Sürüklenen kart gölgesiyle yükselir, köşesi kartla aynı.
        proxyDecorator: (child, _, _) => Material(
          type: MaterialType.transparency,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const .all(.circular(TarusOlcu.rKart)),
              boxShadow: r.elev2,
            ),
            child: child,
          ),
        ),
        itemBuilder: (context, pageIndex) {
          final isEmptyLastPage =
              pageIndex == sayfaSayisi - 1 &&
              widget.coreInfo.pages[pageIndex].isEmpty;
          return Padding(
            key: ValueKey(pageIndex),
            padding: const .only(bottom: TarusOlcu.aralik),
            child: TarusKart(
              secili: pageIndex == widget.currentPageIndex,
              icerigiBoya: false,
              golge: false,
              onTap: () => scrollToPage(pageIndex),
              padding: const .fromLTRB(12, 10, 4, 6),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        '${pageIndex + 1} / $sayfaSayisi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: r.muted2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 150,
                              maxHeight: 220,
                            ),
                            child: DecoratedBox(
                              position: DecorationPosition.foreground,
                              decoration: BoxDecoration(
                                border: Border.all(color: r.bdr2),
                                borderRadius: const .all(
                                  .circular(TarusOlcu.rSm),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: const .all(
                                  .circular(TarusOlcu.rSm),
                                ),
                                child: FittedBox(
                                  child: CanvasPreview(
                                    pageIndex: pageIndex,
                                    height: null,
                                    coreInfo: widget.coreInfo,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: ReorderableDragStartListener(
                          index: pageIndex,
                          child: Padding(
                            padding: const .all(8),
                            child: Icon(
                              TarusIkon.tutamac,
                              size: 18,
                              color: r.muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: .center,
                    children: [
                      TarusIkonDugmesi(
                        tooltip: t.editor.menu.insertPage,
                        ikon: TarusIkon.sayfaEkle,
                        boyut: 36,
                        ikonBoyutu: 18,
                        onPressed: () => setState(() {
                          widget.insertPageAfter(pageIndex);
                          scrollToPage(pageIndex + 1);
                        }),
                      ),
                      TarusIkonDugmesi(
                        tooltip: t.editor.menu.duplicatePage,
                        ikon: TarusIkon.kopyala,
                        boyut: 36,
                        ikonBoyutu: 18,
                        onPressed: () => setState(() {
                          widget.duplicatePage(pageIndex);
                          scrollToPage(pageIndex + 1);
                        }),
                      ),
                      TarusIkonDugmesi(
                        tooltip: t.editor.menu.clearPage(
                          page: pageIndex + 1,
                          totalPages: sayfaSayisi,
                        ),
                        ikon: TarusIkon.temizle,
                        boyut: 36,
                        ikonBoyutu: 18,
                        onPressed: isEmptyLastPage
                            ? null
                            : () => setState(() {
                                widget.clearPage(pageIndex);
                                scrollToPage(pageIndex);
                              }),
                      ),
                      TarusIkonDugmesi(
                        tooltip: t.editor.menu.deletePage,
                        ikon: TarusIkon.sil,
                        boyut: 36,
                        ikonBoyutu: 18,
                        renk: r.danger,
                        onPressed: isEmptyLastPage
                            ? null
                            : () => setState(() {
                                widget.deletePage(pageIndex);
                                scrollToPage(pageIndex);
                              }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        onReorderItem: (oldIndex, newIndex) {
          if (oldIndex == newIndex) return;
          widget.coreInfo.pages.insert(
            newIndex,
            widget.coreInfo.pages.removeAt(oldIndex),
          );

          // reassign pageIndex of pages' strokes and images
          for (int i = 0; i < widget.coreInfo.pages.length; i++) {
            final page = widget.coreInfo.pages[i];
            page.updatePageIndex(i);
          }

          widget.redrawAndSave();
        },
      ),
    );
  }
}
