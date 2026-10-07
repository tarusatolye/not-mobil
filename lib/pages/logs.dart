import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
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
                      icon: const Icon(TarusIkon.oynat),
                      onPressed: logsHistory.unfreeze,
                    )
                  else
                    IconButton(
                      icon: const Icon(TarusIkon.duraklat),
                      onPressed: logsHistory.freeze,
                    ),
                  IconButton(
                    icon: const Icon(TarusIkon.kopyala),
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

class _LogsItem extends StatelessWidget {
  const new({required this.record});

  final LogRecord record;

  @override
  Widget build(BuildContext context) {
    const hPadding = 16.0;
    const vPadding = 8.0;
    return Column(
      crossAxisAlignment: .start,
      children: [
        const SizedBox(height: vPadding),
        Padding(
          padding: const .symmetric(horizontal: hPadding),
          child: _LogLevel(level: record.level),
        ),
        Padding(
          padding: const .symmetric(horizontal: hPadding),
          child: Text(record.message),
        ),
        if (record.stackTrace != null)
          ColoredBox(
            color: const Color(0xCC000000),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                record.stackTrace.toString(),
                style: const TextStyle(
                  fontFamily: 'FiraMono',
                  fontFamilyFallback: saberMonoFontFallbacks,
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        const SizedBox(height: vPadding),
      ],
    );
  }
}

class _LogLevel extends StatelessWidget {
  const new({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: switch (level) {
          Level.SHOUT || Level.SEVERE => colorScheme.error,
          Level.WARNING => colorScheme.tertiary,
          _ => colorScheme.surfaceContainer,
        },
        borderRadius: const .all(.circular(2)),
      ),
      child: Text(
        level.name,
        style: TextStyle(
          color: switch (level) {
            Level.SHOUT || Level.SEVERE => colorScheme.onError,
            Level.WARNING => colorScheme.onTertiary,
            _ => colorScheme.onSurface,
          },
        ),
      ),
    );
  }
}
