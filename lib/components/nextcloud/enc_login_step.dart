import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:saber/components/misc/faq.dart';
import 'package:saber/data/nextcloud/errors.dart';
import 'package:saber/data/nextcloud/nextcloud_client_extension.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:sbn/font_fallbacks.dart';

class EncLoginStep extends HookWidget {
  const new({super.key, required this.recheckCurrentStep});

  final void Function() recheckCurrentStep;

  static const width = 400.0;

  static final log = Logger('EncLoginStep');

  @override
  Widget build(BuildContext context) {
    final encPasswordController = useTextEditingController();
    final errorMessage = useState('');
    final isChecking = useState(false);

    final colorScheme = ColorScheme.of(context);
    final r = TarusRenkler.of(context);
    final textTheme = TextTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    return ListView(
      padding: .symmetric(
        horizontal: screenWidth > width ? (screenWidth - width) / 2 : 16,
        vertical: 16,
      ),
      children: [
        const SizedBox(height: 16),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: r.accent.withValues(alpha: TarusOlcu.seciliZeminAlfa),
            borderRadius: const .all(.circular(TarusOlcu.rHero)),
          ),
          child: Icon(TarusIkon.kilit, color: r.accent, size: 24),
        ),
        const SizedBox(height: 16),
        Text(
          t.login.status.hi(u: stows.username.value),
          style: textTheme.headlineSmall,
        ),
        Text.rich(
          t.login.notYou(
            undoLogin: (text) => TextSpan(
              text: text,
              style: TextStyle(color: r.accent, fontWeight: FontWeight.w600),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  stows.url.value = '';
                  stows.username.value = '';
                  stows.ncPassword.value = '';
                  recheckCurrentStep();
                },
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          t.login.encLoginStep.enterEncPassword,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(t.login.encLoginStep.newToSaber),
        const SizedBox(height: 16),
        TextField(
          controller: encPasswordController,
          style: const TextStyle(
            fontFamily: 'FiraMono',
            fontFamilyFallback: saberMonoFontFallbacks,
          ),
          decoration: InputDecoration(
            labelText: t.login.encLoginStep.encPassword,
          ),
          autofillHints: const [AutofillHints.password],
          autofocus: true,
        ),
        ValueListenableBuilder(
          valueListenable: errorMessage,
          builder: (context, errorMessage, _) {
            if (errorMessage.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const .only(top: 4),
              child: Text(
                errorMessage,
                style: TextStyle(color: colorScheme.error),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        ListenableBuilder(
          listenable: encPasswordController,
          builder: (context, child) {
            final encPassword = encPasswordController.text;
            return FilledButton(
              onPressed: (encPassword.isEmpty || isChecking.value)
                  ? null
                  : () async {
                      isChecking.value = true;
                      try {
                        await _checkEncPassword(encPassword, errorMessage);
                      } finally {
                        isChecking.value = false;
                      }
                    },
              child: child,
            );
          },
          child: Text(t.common.continueBtn),
        ),
        const SizedBox(height: 32),
        Text(t.login.encLoginStep.encFaqTitle, style: textTheme.headlineSmall),
        FaqListView(
          shrinkWrap: true,
          items: [
            for (final item in t.login.encLoginStep.encFaq)
              FaqItem(item.q, item.a),
          ],
        ),
      ],
    );
  }

  Future<void> _checkEncPassword(
    String encPassword,
    ValueNotifier<String> errorMessage,
  ) async {
    errorMessage.value = '';
    if (encPassword.isEmpty) return;

    try {
      stows.encPassword.value = encPassword;
      final client = NextcloudClientExtension.withSavedDetails()!;
      await client.loadEncryptionKey();
      recheckCurrentStep();
    } on EncLoginFailure {
      stows.encPassword.value = '';
      errorMessage.value = t.login.encLoginStep.wrongEncPassword;
    } catch (e, st) {
      stows.encPassword.value = '';
      log.severe('Failed to load encryption key: $e', e, st);
      errorMessage.value = '${t.login.encLoginStep.connectionFailed}\n\n$e';
      if (kDebugMode) rethrow;
    }
  }
}
