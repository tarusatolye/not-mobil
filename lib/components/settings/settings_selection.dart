import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saber/components/settings/settings_dropdown.dart';
import 'package:saber/components/settings/settings_subtitle.dart';
import 'package:saber/pages/home/settings.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:stow/stow.dart';

/// Ayarlar satırı: birkaç seçenekten biri (sağda bölümlü seçici; yer
/// yetmezse açılır liste).
class SettingsSelection<T extends num> extends StatefulWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconBuilder,
    required this.pref,
    required this.options,
    this.afterChange,
    this.optionsWidth = 48,
    this.optionsHeight = 32,
  }) : assert(
         icon == null || iconBuilder == null,
         'Cannot set both icon and iconBuilder',
       );

  final String title;
  final String? subtitle;
  final IconData? icon;
  final IconData? Function(T)? iconBuilder;

  final Stow<dynamic, T, dynamic> pref;
  final List<ToggleButtonsOption<T>> options;
  final ValueChanged<T>? afterChange;

  final double optionsWidth, optionsHeight;

  @override
  State<SettingsSelection> createState() => _SettingsSelectionState<T>();
}

class _SettingsSelectionState<T extends num>
    extends State<SettingsSelection<T>> {
  @override
  void initState() {
    widget.pref.addListener(onChanged);
    super.initState();
  }

  void onChanged() {
    widget.afterChange?.call(widget.pref.value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.options.any(
      (ToggleButtonsOption option) => widget.pref.value == option.value,
    )) {
      if (kDebugMode)
        throw Exception(
          'SettingsSelection (${widget.pref.key}): Value ${widget.pref.value} is not in the list of values, set it to ${widget.options.first.value}?',
        );
      widget.pref.value = widget.options.first.value;
    }

    final expSelectionWidth = widget.options.length * (widget.optionsWidth + 6);
    final useDropdownInstead =
        MediaQuery.sizeOf(context).width * 0.48 < expSelectionWidth;
    if (useDropdownInstead) {
      // Yer yetmiyorsa açılır liste
      return SettingsDropdown<T>(
        pref: widget.pref,
        options: widget.options,
        title: widget.title,
        subtitle: widget.subtitle,
        icon: widget.icon,
        iconBuilder: widget.iconBuilder,
        afterChange: widget.afterChange,
      );
    }

    final icon =
        widget.icon ??
        widget.iconBuilder?.call(widget.pref.value) ??
        TarusIkon.ayarlar;

    return ListTile(
      onLongPress: () {
        SettingsPage.showResetDialog(
          context: context,
          pref: widget.pref,
          prefTitle: widget.title,
        );
      },
      contentPadding: AyarSatiri.ic,
      leading: AyarSatiri.ikon(icon),
      title: AyarSatiri.baslik(
        widget.title,
        degisti: widget.pref.value != widget.pref.defaultValue,
      ),
      subtitle: widget.subtitle == null || widget.subtitle!.isEmpty
          ? null
          : Text(widget.subtitle!),
      trailing: TarusSecmeli<T>(
        value: widget.pref.value,
        options: widget.options,
        onChange: (T? value) {
          // pref değişince setState kendiliğinden çağrılır
          if (value != null) widget.pref.value = value;
        },
        optionsWidth: widget.optionsWidth,
        optionsHeight: widget.optionsHeight,
      ),
    );
  }

  @override
  void dispose() {
    widget.pref.removeListener(onChanged);
    super.dispose();
  }
}
