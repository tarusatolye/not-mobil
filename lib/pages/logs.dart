import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:sbn/font_fallbacks.dart';

final logsHistory = _LogsHistory();

class _LogsHistory extends ChangeNotifier {
  final _history = <LogRecord>[];

  /// A frozen copy of the history.
  List<LogRecord>? _frozenHistory;

  /// The history of log records. Do not modify this list directly.
  List<LogRecord> get history => _frozenHistory ?? _history;

  bool get isFrozen => _frozenHistory != null;

  void freeze() {
    _frozenHistory = List.unmodifiable(_history);
  }

  void unfreeze() {
    _frozenHistory = null;
  }

  void add(LogRecord record) {
    _history.add(record);
    notifyListeners();
  }

  void clear() {
    _history.clear();
    _frozenHistory = null;
    notifyListeners();
  }
}

class const LogsPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: logsHistory,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(t.logs.logs),
                actions: [
                  if (logsHistory.isFrozen)
                    IconButton(
                      icon: Icon(TarusIkon.oynat, color: r.accent),
                      onPressed: logsHistory.unfreeze,
                    )
                  else
                    IconButton(
                      icon: const Icon(TarusIkon.duraklat),
                      onPressed: logsHistory.freeze,
                    ),
                  IconButton(
                    icon: const Icon(TarusIkon.kopyala),
                    tooltip: MaterialLocalizations.of(context).copyButtonLabel,
                    onPressed: logsHistory.history.isEmpty
                        ? null
                        : () {
                            final buffer = StringBuffer();
                            for (final record in logsHistory.history) {
                              buffer.write(record.level.name);
                              buffer.write(' at ');
                              buffer.writeln(record.time);
                              buffer.writeln(record.message);
                              if (record.error != null)
                                buffer.writeln(record.error);
                              if (record.stackTrace != null)
                                buffer.writeln(record.stackTrace);
                              buffer.writeln();
                            }
                            Clipboard.setData(
                              ClipboardData(text: buffer.toString()),
                            );
                          },
                  ),
                ],
              ),
              if (logsHistory.history.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: TarusBosDurum(
                    ikon: TarusIkon.kayitlar,
                    baslik: t.logs.noLogs,
                    aciklama: t.logs.useTheApp,
                  ),
                )
              else
                SliverList.builder(
                  itemCount: logsHistory.history.length,
                  itemBuilder: (context, index) {
                    if (index < 0 || index >= logsHistory.history.length) {
                      return const SizedBox();
                    }
                    return _LogsItem(
                      record: logsHistory
                          .history[logsHistory.history.length - 1 - index],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Kayıt satırı: düzey rozeti ve saat, ileti; yığın izi `--card2` zeminde
/// eş aralıklı yazıyla (sabit siyah/beyaz yerine tema token'ları).
class _LogsItem extends StatelessWidget {
  const new({required this.record});

  final LogRecord record;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    const hPadding = TarusOlcu.sayfaYatay + 4;
    final saat = record.time.toIso8601String().substring(11, 19);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: r.bdr1)),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: hPadding, vertical: 10),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                _LogLevel(level: record.level),
                const SizedBox(width: 8),
                Text(
                  saat,
                  style: TextStyle(
                    fontSize: TarusOlcu.yaziMeta,
                    color: r.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(
              record.message,
              style: TextStyle(fontSize: 13, color: r.text, height: 1.4),
            ),
            if (record.error != null) ...[
              const SizedBox(height: 2),
              Text(
                record.error.toString(),
                style: TextStyle(fontSize: 12, color: r.danger, height: 1.4),
              ),
            ],
            if (record.stackTrace != null) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: r.card2,
                  borderRadius: const .all(.circular(TarusOlcu.rSm)),
                  border: Border.all(color: r.bdr1),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const .all(8),
                  child: Text(
                    record.stackTrace.toString(),
                    style: TextStyle(
                      fontFamily: 'FiraMono',
                      fontFamilyFallback: saberMonoFontFallbacks,
                      fontSize: 11,
                      height: 1.45,
                      color: r.muted2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Düzey rozeti: hata `--danger`, uyarı `--warning`, diğerleri nötr
/// (rengin %14 zemini, %45 kenarlığı).
class _LogLevel extends StatelessWidget {
  const new({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final r = TarusRenkler.of(context);
    final Color? renk = switch (level) {
      Level.SHOUT || Level.SEVERE => r.danger,
      Level.WARNING => r.warning,
      _ => null,
    };
    return Container(
      padding: const .symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: renk?.withValues(alpha: TarusOlcu.seciliZeminAlfa) ?? r.ovl2,
        borderRadius: const .all(.circular(6)),
        border: Border.all(
          color: renk?.withValues(alpha: TarusOlcu.seciliKenarAlfa) ?? r.bdr1,
        ),
      ),
      child: Text(
        level.name,
        style: TextStyle(
          fontSize: TarusOlcu.yaziMeta,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: renk ?? r.muted2,
        ),
      ),
    );
  }
}
