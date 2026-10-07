import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:saber/components/nextcloud/done_login_step.dart';
import 'package:saber/components/nextcloud/nc_login_step.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/tarus_baglantilar.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/tarus/tarus_ikon.dart';

class NcLoginPage extends StatefulWidget {
  const new({
    super.key,
    @visibleForTesting this.forceAppBarLeading = false,
    @visibleForTesting this.forceCurrentStep,
  });

  /// Whether to force the AppBar to have a leading back button
  final bool forceAppBarLeading;

  /// If provided, forces the current step to this value (for testing)
  final LoginStep? forceCurrentStep;

  /// Hesap oluşturma: Not'un ayrı hesabı yok, kimlik Pusula'dır (Saber'in
  /// Nextcloud kayıt sayfası değil). Şu an arayüzde kullanılmıyor.
  static Uri get signupUrl => TarusBaglantilar.pusulaHesapOlustur;

  @override
  State<NcLoginPage> createState() => _NcLoginPageState();

  static LoginStep getCurrentStep() {
    if (!stows.url.loaded ||
        !stows.username.loaded ||
        !stows.ncPassword.loaded) {
      return .waitingForPrefs;
    }

    // Şifreleme parolası adımı yok (1.1.6): notlar düz eşitlenir,
    // sunucu diskte şifreli saklar.
    if (stows.username.value.isEmpty || stows.ncPassword.value.isEmpty) {
      return .nc;
    }
    return .done;
  }
}

class _NcLoginPageState extends State<NcLoginPage> {
  final log = Logger('_NcLoginPageState');

  late LoginStep step = .waitingForPrefs;

  @override
  void initState() {
    waitForPrefs();
    super.initState();
  }

  Future<void> waitForPrefs() async {
    if (widget.forceCurrentStep != null) {
      step = widget.forceCurrentStep!;
      return;
    }

    step = .waitingForPrefs;

    if (!stows.url.loaded || !stows.username.loaded || !stows.ncPassword.loaded)
      await Future.wait([
        stows.url.waitUntilRead(),
        stows.username.waitUntilRead(),
        stows.ncPassword.waitUntilRead(),
      ]);

    recheckCurrentStep();
  }

  void recheckCurrentStep() {
    if (widget.forceCurrentStep != null) {
      step = widget.forceCurrentStep!;
      return;
    }

    final prevStep = step;
    step = NcLoginPage.getCurrentStep();

    if (prevStep != step) if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight,
        title: Text(switch (step) {
          .waitingForPrefs => '',
          .done => t.profile.title,
          _ => t.login.title,
        }),
        leading: widget.forceAppBarLeading
            ? IconButton(
                icon: const Icon(TarusIkon.geri),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const .fromHeight(4),
          child: LinearProgressIndicator(value: step.progress, minHeight: 4),
        ),
      ),
      body: switch (step) {
        .waitingForPrefs => const Center(child: CircularProgressIndicator()),
        .nc => NcLoginStep(recheckCurrentStep: recheckCurrentStep),
        .done => DoneLoginStep(recheckCurrentStep: recheckCurrentStep),
      },
    );
  }
}

enum LoginStep(
  /// The value used for the LinearProgressIndicator on this step
  final double progress,
) {
  /// We're waiting for the Prefs to be loaded
  waitingForPrefs(0),

  /// The user needs to authenticate with the Nextcloud server
  nc(0.2),

  /// The user is fully logged in
  done(1),
}
