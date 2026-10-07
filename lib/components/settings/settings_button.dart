import 'package:flutter/material.dart';
import 'package:saber/components/settings/settings_subtitle.dart';
import 'package:saber/tarus/tarus_ikon.dart';

/// Ayarlar satırı: dokununca bir eylem ya da sayfa açar (sağda ok).
class SettingsButton extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onPressed,
    this.ok = true,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Sağda ileri oku göster.
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPressed,
      contentPadding: AyarSatiri.ic,
      leading: AyarSatiri.ikon(icon),
      title: Text(title),
      subtitle: subtitle == null || subtitle!.isEmpty ? null : Text(subtitle!),
      trailing: ok ? const Icon(TarusIkon.ileri, size: 18) : null,
    );
  }
}
