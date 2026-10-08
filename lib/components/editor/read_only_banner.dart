import 'package:collapsible/collapsible.dart';
import 'package:flutter/material.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:sbn/read_only_reason.dart';

/// A banner that tells the user why the note is read-only.
/// If [reason] is null, an empty widget is returned.
/// If [action] is provided, a trailing icon button will be shown.
class ReadOnlyBanner extends StatefulWidget {
  const new(this.reason, {super.key, this.action});

  final ReadOnlyReason? reason;
  final VoidCallback? action;

  @override
  State<ReadOnlyBanner> createState() => _ReadOnlyBannerState();
}

class _ReadOnlyBannerState extends State<ReadOnlyBanner> {
  bool get needsBanner => switch (widget.reason) {
    null => false,
    .placeholder => false,
    _ => true,
  };
  late var hasShownBanner = needsBanner;

  var _lastSubtitle = '';
  String get subtitle => _lastSubtitle = switch (widget.reason) {
    null => _lastSubtitle,
    .placeholder => _lastSubtitle,
    .versionTooNew => t.editor.versionTooNew.title,
    .watchingServer => t.editor.readOnlyBanner.watchingServer,
    .corrupted => t.editor.readOnlyBanner.corrupted,
  };

  @override
  Widget build(BuildContext context) {
    hasShownBanner |= needsBanner;
    if (!hasShownBanner) return const SizedBox.shrink();

    return Collapsible(
      collapsed: !needsBanner,
      axis: CollapsibleAxis.vertical,
      child: _Serit(
        baslik: t.editor.readOnlyBanner.title,
        aciklama: subtitle,
        action: widget.action,
      ),
    );
  }
}

/// Uyarı şeridi (STANDARTLAR uyarı rengi): `--warning` %12 zemin, üst ve
/// alt kenarlık %35 (araç çubuğu üstte ya da altta olabilir), solda kalem-kapalı ikonu, sağda isteğe bağlı eylem.
class const _Serit({
  required final String baslik,
  required final String aciklama,
  required final VoidCallback? action,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return Material(
      color: Color.alphaBlend(r.warning.withValues(alpha: 0.12), r.bg),
      child: InkWell(
        onTap: action,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: r.warning.withValues(alpha: 0.35)),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const .fromLTRB(TarusOlcu.sayfaYatay + 4, 10, 8, 10),
              child: Row(
                children: [
                  Icon(TarusIkon.duzenlemeKapali, size: 18, color: r.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      mainAxisSize: .min,
                      children: [
                        Text(
                          baslik,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: r.text,
                          ),
                        ),
                        Text(
                          aciklama,
                          style: TextStyle(fontSize: 12, color: r.muted2),
                        ),
                      ],
                    ),
                  ),
                  if (action != null)
                    TarusIkonDugmesi(
                      ikon: TarusIkon.disBaglanti,
                      ikonBoyutu: 18,
                      boyut: 36,
                      onPressed: action,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
