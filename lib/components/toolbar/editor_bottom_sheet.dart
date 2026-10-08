import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:saber/components/canvas/canvas_background_preview.dart';
import 'package:saber/components/canvas/canvas_image_dialog.dart';
import 'package:saber/components/canvas/inner_canvas.dart';
import 'package:saber/data/editor/editor_core_info.dart';
import 'package:saber/data/editor/page.dart';
import 'package:saber/data/extensions/list_extensions.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/i18n/extensions/box_fit_localized.dart';
import 'package:saber/i18n/extensions/canvas_background_pattern_localized.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:sbn/canvas_background_pattern.dart';

class EditorBottomSheet extends StatefulWidget {
  const new({
    super.key,
    required this.invert,
    required this.coreInfo,
    required this.currentPageIndex,
    required this.setBackgroundPattern,
    required this.setLineHeight,
    required this.setLineThickness,
    required this.removeBackgroundImage,
    required this.redrawImage,
    required this.clearPage,
    required this.clearAllPages,
    required this.redrawAndSave,
    required this.pickPhotos,
    required this.importPdf,
    required this.canRasterPdf,
    required this.getIsWatchingServer,
    required this.setIsWatchingServer,
  });

  final bool invert;
  final EditorCoreInfo coreInfo;
  final int? currentPageIndex;
  final void Function(CanvasBackgroundPattern) setBackgroundPattern;
  final void Function(int) setLineHeight;
  final void Function(int) setLineThickness;
  final VoidCallback removeBackgroundImage;
  final VoidCallback redrawImage;
  final VoidCallback clearPage;
  final VoidCallback clearAllPages;
  final VoidCallback redrawAndSave;
  final Future<int> Function() pickPhotos;
  final Future<bool> Function() importPdf;
  final bool canRasterPdf;
  final bool Function() getIsWatchingServer;
  final void Function(bool) setIsWatchingServer;

  @override
  State<EditorBottomSheet> createState() => _EditorBottomSheetState();
}

class _EditorBottomSheetState extends State<EditorBottomSheet> {
  static const imageBoxFits = <BoxFit>[.fill, .cover, .contain];

  @override
  Widget build(BuildContext context) {
    final page = widget.coreInfo.pages.getOrNull(widget.currentPageIndex ?? -1);
    final pageSize = page?.size ?? EditorPage.defaultSize;
    final backgroundImage = page?.backgroundImage;

    final previewSize = Size(
      CanvasBackgroundPreview.fixedWidth,
      pageSize.height / pageSize.width * CanvasBackgroundPreview.fixedWidth,
    );

    final r = TarusRenkler.of(context);

    Widget onizlemeSecenegi({
      required bool secili,
      required VoidCallback onTap,
      required Widget onizleme,
      required String ad,
    }) => Semantics(
      button: true,
      selected: secili,
      label: ad,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: const .all(.circular(TarusOlcu.rSm)),
          onTap: onTap,
          child: Stack(
            children: [
              onizleme,
              Positioned(
                bottom: previewSize.height * 0.1,
                left: 0,
                right: 0,
                child: Center(child: _PermanentTooltip(text: ad)),
              ),
            ],
          ),
        ),
      ),
    );

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        // Enable drag scrolling on all devices (including mouse)
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const .fromLTRB(16, 0, 16, 16),
        children: [
          Wrap(
            spacing: TarusOlcu.aralik,
            runSpacing: TarusOlcu.aralik,
            children: [
              OutlinedButton.icon(
                onPressed: widget.coreInfo.isNotEmpty
                    ? () {
                        widget.clearPage();
                        Navigator.pop(context);
                      }
                    : null,
                icon: const Icon(TarusIkon.temizle, size: 18),
                label: Text(
                  t.editor.menu.clearPage(
                    page: widget.currentPageIndex == null
                        ? '?'
                        : widget.currentPageIndex! + 1,
                    totalPages: widget.coreInfo.pages.length,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: widget.coreInfo.isNotEmpty
                    ? () {
                        widget.clearAllPages();
                        Navigator.pop(context);
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: r.danger,
                  side: BorderSide(color: r.danger.withValues(alpha: 0.45)),
                ),
                icon: const Icon(TarusIkon.sil, size: 18),
                label: Text(t.editor.menu.clearAllPages),
              ),
            ],
          ),
          if (backgroundImage != null) ...[
            TarusBolumEtiketi(t.editor.menu.backgroundImageFit),
            SizedBox(
              height: previewSize.height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageBoxFits.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: TarusOlcu.aralik),
                itemBuilder: (context, index) {
                  final boxFit = imageBoxFits[index];
                  return onizlemeSecenegi(
                    secili: backgroundImage.backgroundFit == boxFit,
                    ad: boxFit.localizedName,
                    onTap: () => setState(() {
                      backgroundImage.backgroundFit = boxFit;
                      widget.redrawAndSave();
                    }),
                    onizleme: CanvasBackgroundPreview(
                      selected: backgroundImage.backgroundFit == boxFit,
                      invert: widget.invert,
                      backgroundColor:
                          widget.coreInfo.backgroundColor ??
                          InnerCanvas.defaultBackgroundColor,
                      backgroundPattern: widget.coreInfo.backgroundPattern,
                      backgroundImage: backgroundImage,
                      overrideBoxFit: boxFit,
                      pageSize: pageSize,
                      lineHeight: widget.coreInfo.lineHeight,
                      lineThickness: widget.coreInfo.lineThickness,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: TarusOlcu.blokArasi),
            CanvasImageDialog(
              filePath: widget.coreInfo.filePath,
              image: backgroundImage,
              redrawImage: () => setState(() {
                widget.redrawImage();
              }),
              isBackground: true,
              toggleAsBackground: widget.removeBackgroundImage,
              singleRow: true,
            ),
          ],
          TarusBolumEtiketi(t.editor.menu.backgroundPattern),
          SizedBox(
            height: previewSize.height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: CanvasBackgroundPattern.values.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: TarusOlcu.aralik),
              itemBuilder: (context, index) {
                final backgroundPattern = CanvasBackgroundPattern.values[index];
                final secili =
                    widget.coreInfo.backgroundPattern == backgroundPattern;
                return onizlemeSecenegi(
                  secili: secili,
                  ad: backgroundPattern.localizedName,
                  onTap: () => setState(() {
                    widget.setBackgroundPattern(backgroundPattern);
                  }),
                  onizleme: CanvasBackgroundPreview(
                    selected: secili,
                    invert: widget.invert,
                    backgroundColor:
                        widget.coreInfo.backgroundColor ??
                        InnerCanvas.defaultBackgroundColor,
                    backgroundPattern: backgroundPattern,
                    backgroundImage: null, // focus on background pattern
                    pageSize: pageSize,
                    lineHeight: widget.coreInfo.lineHeight,
                    lineThickness: widget.coreInfo.lineThickness,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: TarusOlcu.blokArasi + 6),
          _KaydiriciKart(
            baslik: t.editor.menu.lineHeight,
            aciklama: t.editor.menu.lineHeightDescription,
            deger: widget.coreInfo.lineHeight,
            min: 20,
            max: 100,
            adim: 8,
            onChanged: (value) => setState(() {
              widget.setLineHeight(value);
            }),
          ),
          const SizedBox(height: TarusOlcu.aralik),
          _KaydiriciKart(
            baslik: t.editor.menu.lineThickness,
            aciklama: t.editor.menu.lineThicknessDescription,
            deger: widget.coreInfo.lineThickness,
            min: 1,
            max: 5,
            adim: 4,
            onChanged: (value) => setState(() {
              widget.setLineThickness(value);
            }),
          ),
          TarusBolumEtiketi(t.editor.menu.import),
          Wrap(
            spacing: TarusOlcu.aralik,
            runSpacing: TarusOlcu.aralik,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final photosPicked = await widget.pickPhotos();
                  if (photosPicked > 0) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(TarusIkon.gorselEkle, size: 18),
                label: Text(t.editor.toolbar.photo),
              ),
              if (widget.canRasterPdf)
                OutlinedButton.icon(
                  onPressed: () async {
                    final pdfImported = await widget.importPdf();
                    if (pdfImported) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(TarusIkon.notIceAktar, size: 18),
                  label: const Text('PDF'),
                ),
            ],
          ),
          if (stows.loggedIn) ...[
            const SizedBox(height: TarusOlcu.blokArasi + 6),
            StatefulBuilder(
              builder: (context, setState) {
                final isWatchingServer = widget.getIsWatchingServer();
                return TarusKart(
                  golge: false,
                  onTap: () => setState(() {
                    widget.setIsWatchingServer(!isWatchingServer);
                  }),
                  padding: const .fromLTRB(TarusOlcu.kart, 10, 8, 10),
                  child: MergeSemantics(
                    child: Row(
                      children: [
                        Icon(TarusIkon.goster, size: 18, color: r.muted2),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: .start,
                            children: [
                              Text(
                                t.editor.menu.watchServer,
                                style: TextStyle(
                                  fontSize: TarusOlcu.yaziKartBasligi,
                                  fontWeight: FontWeight.w600,
                                  color: r.text,
                                ),
                              ),
                              if (isWatchingServer)
                                Text(
                                  t.editor.menu.watchServerReadOnly,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: r.muted2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isWatchingServer,
                          onChanged: (value) => setState(() {
                            widget.setIsWatchingServer(value);
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Kaydırıcılı ayar kartı (satır aralığı, çizgi kalınlığı): başlık, sağda
/// değer rozeti, açıklama ve kaydırıcı.
class const _KaydiriciKart({
  required final String baslik,
  required final String aciklama,
  required final int deger,
  required final int min,
  required final int max,
  required final int adim,
  required final ValueChanged<int> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return TarusKart(
      golge: false,
      padding: const .fromLTRB(TarusOlcu.kart, 12, TarusOlcu.kart, 4),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  baslik,
                  style: TextStyle(
                    fontSize: TarusOlcu.yaziKartBasligi,
                    fontWeight: FontWeight.w600,
                    color: r.text,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 36),
                padding: const .symmetric(horizontal: 8, vertical: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa),
                  borderRadius: const .all(.circular(999)),
                  border: Border.all(
                    color: r.accent.withValues(
                      alpha: TarusOlcu.seciliKenarAlfa,
                    ),
                  ),
                ),
                child: Text(
                  '$deger',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: r.accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            aciklama,
            style: TextStyle(fontSize: 12, color: r.muted2, height: 1.4),
          ),
          Slider(
            value: deger.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: adim,
            label: '$deger',
            onChanged: (value) => onChanged(value.toInt()),
          ),
        ],
      ),
    );
  }
}

class _PermanentTooltip extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const .all(.circular(6)),
        color: r.card.withValues(alpha: 0.92),
        border: Border.all(color: r.bdr1),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          textAlign: .center,
          textWidthBasis: TextWidthBasis.longestLine,
          style: TextStyle(
            color: r.text,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
