import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/pages/editor/editor.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  testGoldens('Editor: undo/redo buttons interaction test', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    setupMockPathProvider();
    setupMockPrinting();

    FlavorConfig.setup();
    await tester.runAsync(FileManager.init);

    await tester.pumpWidget(
      TranslationProvider(
        child: ScreenshotApp(
          device: GoldenScreenshotDevices.androidPhone.device,
          home: Editor(),
        ),
      ),
    );

    final editorState = tester.state<EditorState>(find.byType(Editor));
    expect(
      editorState.coreInfo.readOnly,
      isFalse,
      reason: 'New file should not be read-only',
    );
    addTearDown(editorState.cancelAutosaveAndMarkSaved);

    TarusIkonDugmesi getUndoBtn() => tester.widget<TarusIkonDugmesi>(
      find.ancestor(
        of: find.byIcon(TarusIkon.geriAl),
        matching: find.byType(TarusIkonDugmesi),
      ),
    );
    TarusIkonDugmesi getRedoBtn() => tester.widget<TarusIkonDugmesi>(
      find.ancestor(
        of: find.byIcon(TarusIkon.yinele),
        matching: find.byType(TarusIkonDugmesi),
      ),
    );

    expect(
      [getUndoBtn().onPressed, getRedoBtn().onPressed],
      [isNull, isNull],
      reason: 'Undo/redo buttons should be disabled initially',
    );

    await drawOnEditor(tester);
    await tester.pump();
    expect(editorState.coreInfo.pages.first.strokes, hasLength(1));
    expect(
      [getUndoBtn().onPressed, getRedoBtn().onPressed],
      [isNotNull, isNull],
      reason: 'Undo button should be enabled after first draw',
    );

    // undo
    await tester.tap(find.byIcon(TarusIkon.geriAl));
    await tester.pump();
    expect(editorState.coreInfo.pages.first.strokes, hasLength(0));
    expect(
      [getUndoBtn().onPressed, getRedoBtn().onPressed],
      [isNull, isNotNull],
      reason: 'Undo button should be disabled after undo',
    );

    // redo
    await tester.tap(find.byIcon(TarusIkon.yinele));
    await tester.pump();
    expect(editorState.coreInfo.pages.first.strokes, hasLength(1));
    expect(
      [getUndoBtn().onPressed, getRedoBtn().onPressed],
      [isNotNull, isNull],
      reason: 'Undo button should be enabled after redo',
    );

    // undo, then draw again
    await tester.tap(find.byIcon(TarusIkon.geriAl));
    await tester.pump();
    expect(editorState.coreInfo.pages.first.strokes, hasLength(0));
    await drawOnEditor(tester);
    await tester.pump();
    expect(editorState.coreInfo.pages.first.strokes, hasLength(1));
    expect(
      [getUndoBtn().onPressed, getRedoBtn().onPressed],
      [isNotNull, isNull],
      reason: 'Undo button should be enabled after undo and draw',
    );
  });
}

Future drawOnEditor(WidgetTester tester) => tester.timedDrag(
  find.byType(Editor),
  const Offset(50, 0),
  const Duration(milliseconds: 100),
);
