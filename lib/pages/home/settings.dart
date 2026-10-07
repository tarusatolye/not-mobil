import 'dart:io';

import 'package:collapsible/collapsible.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saber/components/navbar/responsive_navbar.dart';
import 'package:saber/components/settings/app_info.dart';
import 'package:saber/components/settings/nextcloud_profile.dart';
import 'package:saber/components/settings/settings_button.dart';
import 'package:saber/components/settings/settings_directory_selector.dart';
import 'package:saber/components/settings/settings_dropdown.dart';
import 'package:saber/components/settings/settings_selection.dart';
import 'package:saber/components/settings/settings_sentry.dart';
import 'package:saber/components/settings/settings_subtitle.dart';
import 'package:saber/components/settings/settings_switch.dart';
import 'package:saber/components/settings/tarus_tema_secici.dart';
import 'package:saber/components/settings/update_manager.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/flavor_config.dart';
import 'package:saber/data/locales.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/routes.dart';
import 'package:saber/data/sentry/sentry_init.dart';
import 'package:saber/data/tools/shape_pen.dart';
import 'package:saber/i18n/strings.g.dart';
import 'package:saber/pages/user/hata_bildir_sayfasi.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:stow/stow.dart';

class const SettingsPage({super.key}) extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();

  static Future<bool?> showResetDialog({
    required BuildContext context,
    required Stow pref,
    required String prefTitle,
  }) async {
    if (pref.value == pref.defaultValue) return null;
    return await showDialog(
      context: context,
      builder: (context) => TarusDialog(
        title: Text(t.settings.reset.title),
        content: Text(prefTitle),
        actions: [
          TarusDialogDugmesi(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TarusDialogDugmesi(
            isDestructiveAction: true,
            onPressed: () {
              pref.value = pref.defaultValue;
              Navigator.of(context).pop(true);
            },
            child: Text(t.settings.reset.button),
          ),
        ],
      ),
    );
  }
}

abstract class _SettingsStows {
  static final layoutSize = TransformedStow(
    stows.layoutSize,
    (LayoutSize value) => value.index,
    (int value) => LayoutSize.values[value],
  );

  static final editorToolbarAlignment = TransformedStow(
    stows.editorToolbarAlignment,
    (AxisDirection value) => value.index,
    (int value) => AxisDirection.values[value],
  );
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    stows.locale.addListener(onChanged);
    UpdateManager.status.addListener(onChanged);
    super.initState();
  }

  void onChanged() {
    setState(() {});
  }

  /// Araç çubuğu konumu: yukarı, sağ, aşağı, sol.
  static const yonIkonlari = [
    TarusIkon.yukari,
    TarusIkon.saga,
    TarusIkon.asagiCizgi,
    TarusIkon.sola,
  ];

  @override
  Widget build(BuildContext context) {
    final requiresManualUpdates = FlavorConfig.appStore.isEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          TarusSayfaUstu(
            baslik: t.home.titles.settings,
            eylemler: [
              if (UpdateManager.status.value != .upToDate)
                IconButton(
                  tooltip: t.home.tooltips.showUpdateDialog,
                  icon: const Icon(TarusIkon.guncelleme),
                  onPressed: () {
                    UpdateManager.showUpdateDialog(
                      context,
                      userTriggered: true,
                    );
                  },
                ),
            ],
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const .fromLTRB(
                TarusOlcu.sayfaYatay,
                0,
                TarusOlcu.sayfaYatay,
                TarusOlcu.aralik,
              ),
              sliver: SliverList.list(
                children: [
                  TarusBolumEtiketi(
                    t.tarus.ayar.esitleme,
                    padding: const .fromLTRB(4, 4, 4, 8),
                  ),
                  const NextcloudProfile(),

                  TarusBolumEtiketi(t.tarus.ayar.gorunum),
                  AyarGrubu(
                    children: [
                      SettingsDropdown(
                        title: t.settings.prefLabels.locale,
                        icon: TarusIkon.dil,
                        pref: stows.locale,
                        options: [
                          ToggleButtonsOption(
                            '',
                            Text(t.settings.systemLanguage),
                          ),
                          ...AppLocaleUtils.supportedLocales.map((locale) {
                            final localeCode = locale.toLanguageTag();
                            final localeName = localeNames[localeCode];
                            assert(
                              localeName != null,
                              'Missing locale name for $localeCode',
                            );
                            return ToggleButtonsOption(
                              localeCode,
                              Text(localeName ?? localeCode),
                            );
                          }),
                        ],
                      ),
                      SettingsSelection(
                        title: t.settings.prefLabels.layoutSize,
                        subtitle: switch (stows.layoutSize.value) {
                          .auto => t.settings.layoutSizes.auto,
                          .phone => t.settings.layoutSizes.phone,
                          .tablet => t.settings.layoutSizes.tablet,
                        },
                        afterChange: (_) => setState(() {}),
                        icon: TarusIkon.duzenBoyutu,
                        pref: _SettingsStows.layoutSize,
                        options: [
                          ToggleButtonsOption(
                            LayoutSize.auto.index,
                            Icon(
                              TarusIkon.otomatik,
                              semanticLabel: t.settings.layoutSizes.auto,
                            ),
                          ),
                          ToggleButtonsOption(
                            LayoutSize.phone.index,
                            Icon(
                              TarusIkon.telefon,
                              semanticLabel: t.settings.layoutSizes.phone,
                            ),
                          ),
                          ToggleButtonsOption(
                            LayoutSize.tablet.index,
                            Icon(
                              TarusIkon.tablet,
                              semanticLabel: t.settings.layoutSizes.tablet,
                            ),
                          ),
                        ],
                      ),
                      SettingsSwitch(
                        title: t.settings.prefLabels.hyperlegibleFont,
                        subtitle: t.settings.prefDescriptions.hyperlegibleFont,
                        icon: TarusIkon.yaziTipi,
                        pref: stows.hyperlegibleFont,
                      ),
                    ],
                  ),

                  TarusBolumEtiketi(t.tarus.ayar.tema),
                  const TarusTemaSecici(),

                  TarusBolumEtiketi(t.settings.prefCategories.writing),
                  AyarGrubu(
                    children: [
                      SettingsSwitch(
                        title: t.settings.prefLabels.preferGreyscale,
                        subtitle: t.settings.prefDescriptions.preferGreyscale,
                        icon: TarusIkon.griTon,
                        pref: stows.preferGreyscale,
                      ),
                      SettingsSwitch(
                        title: t.settings.prefLabels.autoClearWhiteboardOnExit,
                        subtitle: t
                            .settings
                            .prefDescriptions
                            .autoClearWhiteboardOnExit,
                        icon: TarusIkon.temizle,
                        pref: stows.autoClearWhiteboardOnExit,
                      ),
                      SettingsSwitch(
                        title: t.settings.prefLabels.disableEraserAfterUse,
                        subtitle:
                            t.settings.prefDescriptions.disableEraserAfterUse,
                        icon: TarusIkon.silgi,
                        pref: stows.disableEraserAfterUse,
                      ),
                      ValueListenableBuilder(
                        valueListenable: stows.hideFingerDrawingToggle,
                        builder: (context, _, _) {
                          return SettingsSwitch(
                            title:
                                t.settings.prefLabels.hideFingerDrawingToggle,
                            subtitle: () {
                              final d =
                                  t.settings.prefDescriptions.hideFingerDrawing;
                              if (!stows.hideFingerDrawingToggle.value) {
                                return d.shown;
                              } else if (stows.editorFingerDrawing.value) {
                                return d.fixedOn;
                              } else {
                                return d.fixedOff;
                              }
                            }(),
                            icon: TarusIkon.parmakla,
                            pref: stows.hideFingerDrawingToggle,
                          );
                        },
                      ),
                      ValueListenableBuilder(
                        valueListenable: stows.hideFingerDrawingToggle,
                        builder: (context, hideFingerDrawing, _) {
                          return Collapsible(
                            collapsed: hideFingerDrawing,
                            axis: CollapsibleAxis.vertical,
                            child: SettingsSwitch(
                              title: t
                                  .settings
                                  .prefLabels
                                  .autoDisableFingerDrawingWhenStylusDetected,
                              subtitle: t
                                  .settings
                                  .prefDescriptions
                                  .autoDisableFingerDrawingWhenStylusDetected,
                              icon: TarusIkon.kalem,
                              pref: stows
                                  .autoDisableFingerDrawingWhenStylusDetected,
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  TarusBolumEtiketi(t.settings.prefCategories.editor),
                  AyarGrubu(
                    children: [
                      SettingsSelection(
                        title: t.settings.prefLabels.editorToolbarAlignment,
                        subtitle:
                            t.settings.axisDirections[_SettingsStows
                                .editorToolbarAlignment
                                .value],
                        iconBuilder: (num i) {
                          if (i is! int || i >= yonIkonlari.length) return null;
                          return yonIkonlari[i];
                        },
                        pref: _SettingsStows.editorToolbarAlignment,
                        optionsWidth: 40,
                        options: [
                          for (final AxisDirection direction
                              in AxisDirection.values)
                            ToggleButtonsOption(
                              direction.index,
                              Icon(
                                yonIkonlari[direction.index],
                                semanticLabel:
                                    t.settings.axisDirections[direction.index],
                              ),
                            ),
                        ],
                        afterChange: (_) => setState(() {}),
                      ),
                      SettingsSwitch(
                        title:
                            t.settings.prefLabels.editorToolbarShowInFullscreen,
                        icon: TarusIkon.tamEkran,
                        pref: stows.editorToolbarShowInFullscreen,
                      ),
                      SettingsSwitch(
                        title: t.settings.prefLabels.editorAutoInvert,
                        icon: TarusIkon.renkCevir,
                        pref: stows.editorAutoInvert,
                      ),
                      SettingsSwitch(
                        title: t.settings.prefLabels.editorPromptRename,
                        subtitle:
                            t.settings.prefDescriptions.editorPromptRename,
                        iconBuilder: (b) =>
                            b ? TarusIkon.klavye : TarusIkon.klavyeKapali,
                        pref: stows.editorPromptRename,
                      ),
                      SettingsSwitch(
                        title:
                            t.settings.prefLabels.recentColorsDontSavePresets,
                        icon: TarusIkon.renkler,
                        pref: stows.recentColorsDontSavePresets,
                      ),
                      SettingsSelection(
                        title: t.settings.prefLabels.recentColorsLength,
                        icon: TarusIkon.gecmis,
                        pref: stows.recentColorsLength,
                        options: const [
                          ToggleButtonsOption(5, Text('5')),
                          ToggleButtonsOption(10, Text('10')),
                        ],
                      ),
                      SettingsSwitch(
                        title: t.settings.prefLabels.printPageIndicators,
                        subtitle:
                            t.settings.prefDescriptions.printPageIndicators,
                        icon: TarusIkon.sayfaNumarasi,
                        pref: stows.printPageIndicators,
                      ),
                    ],
                  ),

                  TarusBolumEtiketi(t.settings.prefCategories.performance),
                  AyarGrubu(
                    children: [
                      SettingsSelection(
                        title: t.settings.prefLabels.maxImageSize,
                        subtitle: t.settings.prefDescriptions.maxImageSize,
                        icon: TarusIkon.gorselBoyutu,
                        pref: stows.maxImageSize,
                        options: const <ToggleButtonsOption<double>>[
                          ToggleButtonsOption(500, Text('500')),
                          ToggleButtonsOption(1000, Text('1000')),
                          ToggleButtonsOption(2000, Text('2000')),
                        ],
                      ),
                      SettingsSelection(
                        title: t.settings.prefLabels.autosave,
                        subtitle: t.settings.prefDescriptions.autosave,
                        icon: TarusIkon.kaydet,
                        pref: stows.autosaveDelay,
                        options: [
                          const ToggleButtonsOption(5000, Text('5s')),
                          const ToggleButtonsOption(10000, Text('10s')),
                          ToggleButtonsOption(
                            -1,
                            Text(t.settings.autosaveDisabled),
                          ),
                        ],
                      ),
                      SettingsSelection(
                        title: t.settings.prefLabels.shapeRecognitionDelay,
                        subtitle:
                            t.settings.prefDescriptions.shapeRecognitionDelay,
                        icon: TarusIkon.sekilKalemi,
                        pref: stows.shapeRecognitionDelay,
                        options: [
                          const ToggleButtonsOption(500, Text('0.5s')),
                          const ToggleButtonsOption(1000, Text('1s')),
                          ToggleButtonsOption(
                            -1,
                            Text(t.settings.shapeRecognitionDisabled),
                          ),
                        ],
                        afterChange: (ms) {
                          ShapePen.debounceDuration =
                              ShapePen.getDebounceFromPref();
                        },
                      ),
                      SettingsSwitch(
                        title: t.settings.prefLabels.autoStraightenLines,
                        subtitle:
                            t.settings.prefDescriptions.autoStraightenLines,
                        icon: TarusIkon.cizgiDuzelt,
                        pref: stows.autoStraightenLines,
                      ),
                    ],
                  ),

                  TarusBolumEtiketi(t.settings.prefCategories.advanced),
                  AyarGrubu(
                    children: [
                      if (isSentryAvailable) const SettingsSentryConsent(),
                      if (Platform.isAndroid)
                        SettingsDirectorySelector(
                          title: t.settings.prefLabels.customDataDir,
                          icon: TarusIkon.klasor,
                        ),
                      if (Platform.isWindows ||
                          Platform.isLinux ||
                          Platform.isMacOS)
                        SettingsButton(
                          title: t.settings.openDataDir,
                          icon: TarusIkon.klasorAcik,
                          onPressed: () {
                            if (Platform.isWindows) {
                              Process.run('explorer', [
                                FileManager.documentsDirectory,
                              ]);
                            } else if (Platform.isLinux) {
                              Process.run('xdg-open', [
                                FileManager.documentsDirectory,
                              ]);
                            } else if (Platform.isMacOS) {
                              Process.run('open', [
                                FileManager.documentsDirectory,
                              ]);
                            }
                          },
                        ),
                      if (UpdateManager.etkin &&
                          (requiresManualUpdates ||
                              stows.shouldCheckForUpdates.value !=
                                  stows
                                      .shouldCheckForUpdates
                                      .defaultValue)) ...[
                        SettingsSwitch(
                          title: t.settings.prefLabels.shouldCheckForUpdates,
                          icon: TarusIkon.guncelleme,
                          pref: stows.shouldCheckForUpdates,
                          afterChange: (_) => setState(() {}),
                        ),
                        Collapsible(
                          collapsed: !stows.shouldCheckForUpdates.value,
                          axis: CollapsibleAxis.vertical,
                          child: SettingsSwitch(
                            title: t
                                .settings
                                .prefLabels
                                .shouldAlwaysAlertForUpdates,
                            subtitle: t
                                .settings
                                .prefDescriptions
                                .shouldAlwaysAlertForUpdates,
                            icon: TarusIkon.uyari,
                            pref: stows.shouldAlwaysAlertForUpdates,
                          ),
                        ),
                      ],
                      SettingsSwitch(
                        title: t.settings.prefLabels.allowInsecureConnections,
                        subtitle: t
                            .settings
                            .prefDescriptions
                            .allowInsecureConnections,
                        icon: TarusIkon.guvenlik,
                        pref: stows.allowInsecureConnections,
                      ),
                    ],
                  ),

                  TarusBolumEtiketi(t.tarus.ayar.destek),
                  AyarGrubu(
                    children: [
                      SettingsButton(
                        title: t.tarus.hataBildir,
                        subtitle: t.tarus.hataBildirAciklama,
                        icon: TarusIkon.hataBildir,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const HataBildirSayfasi(modul: 'Ayarlar'),
                          ),
                        ),
                      ),
                      SettingsButton(
                        title: t.logs.viewLogs,
                        subtitle: t.logs.debuggingInfo,
                        icon: TarusIkon.kayitlar,
                        onPressed: () => context.push(RoutePaths.logs),
                      ),
                      SettingsButton(
                        title: t.tarus.hakkinda,
                        subtitle: t.tarus.hakkindaAciklama,
                        icon: TarusIkon.hakkinda,
                        onPressed: () => AppInfo.hakkindaAc(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const AppInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    stows.locale.removeListener(onChanged);
    UpdateManager.status.removeListener(onChanged);
    super.dispose();
  }
}
