import 'package:flutter/material.dart';
import 'package:saber/components/settings/settings_subtitle.dart';
import 'package:saber/pages/home/settings.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:stow/stow.dart';

/// Ayarlar satırı: açma/kapama. Basılı tutunca varsayılana döndürme sorar.
class SettingsSwitch extends StatefulWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconBuilder,
    required this.pref,
    this.afterChange,
  }) : assert(
         icon == null || iconBuilder == null,
         'Cannot set both icon and iconBuilder',
       );

  final String title;
  final String? subtitle;
  final IconData? icon;
  final IconData? Function(bool)? iconBuilder;

  final Stow<dynamic, bool, dynamic> pref;
  final ValueChanged<bool>? afterChange;

  @override
  State<SettingsSwitch> createState() => _SettingsSwitchState();
}

class _SettingsSwitchState extends State<SettingsSwitch> {
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
    final icon =
        widget.icon ??
        widget.iconBuilder?.call(widget.pref.value) ??
        TarusIkon.ayarlar;

    return GestureDetector(
      onLongPress: () {
        SettingsPage.showResetDialog(
          context: context,
          pref: widget.pref,
          prefTitle: widget.title,
        );
      },
      child: SwitchListTile(
        contentPadding: AyarSatiri.ic,
        secondary: AyarSatiri.ikon(icon),
        title: AyarSatiri.baslik(
          widget.title,
          degisti: widget.pref.value != widget.pref.defaultValue,
        ),
        subtitle: widget.subtitle == null || widget.subtitle!.isEmpty
            ? null
            : Text(widget.subtitle!),
        value: widget.pref.value,
        onChanged: (bool value) {
          widget.pref.value = value;
        },
      ),
    );
  }

  @override
  void dispose() {
    widget.pref.removeListener(onChanged);
    super.dispose();
  }
}
