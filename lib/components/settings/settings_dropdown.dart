import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saber/components/settings/settings_subtitle.dart';
import 'package:saber/pages/home/settings.dart';
import 'package:saber/tarus/tarus_bilesenler.dart';
import 'package:saber/tarus/tarus_ikon.dart';
import 'package:saber/tarus/tarus_olcu.dart';
import 'package:saber/tarus/tarus_renkler.dart';
import 'package:stow/stow.dart';

/// Ayarlar satırı: açılır liste (sağda seçili değer ve aşağı ok).
class SettingsDropdown<T> extends StatefulWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconBuilder,
    required this.pref,
    required this.options,
    this.afterChange,
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

  int? indexOf(T value) {
    for (int i = 0; i < options.length; i++) {
      if (options[i].value == value) return i;
    }
    return null;
  }

  @override
  State<SettingsDropdown> createState() => _SettingsDropdownState<T>();
}

class _SettingsDropdownState<T> extends State<SettingsDropdown<T>> {
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
    if (widget.indexOf(widget.pref.value) == null) {
      if (kDebugMode)
        throw Exception(
          'SettingsDropdown (${widget.pref.key}): Value ${widget.pref.value} is not in the list of values, set it to ${widget.options.first.value}?',
        );
      widget.pref.value = widget.options.first.value;
    }

    final r = TarusRenkler.of(context);
    final icon =
        widget.icon ??
        widget.iconBuilder?.call(widget.pref.value) ??
        TarusIkon.ayarlar;

    return MergeSemantics(
      child: ListTile(
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
        trailing: PopupMenuButton<T>(
          initialValue: widget.pref.value,
          onSelected: (value) => widget.pref.value = value,
          tooltip: widget.title,
          itemBuilder: (context) => [
            for (final option in widget.options)
              PopupMenuItem(
                value: option.value,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                  ),
                  child: option.widget,
                ),
              ),
          ],
          child: Container(
            constraints: BoxConstraints(
              minHeight: 34,
              maxWidth: MediaQuery.sizeOf(context).width * 0.4,
            ),
            padding: const EdgeInsets.only(left: 10, right: 6),
            decoration: BoxDecoration(
              color: r.inputBg,
              borderRadius: BorderRadius.circular(TarusOlcu.rSm),
              border: Border.all(color: r.bdr2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(fontSize: 12.5, color: r.text),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    child: widget.options
                        .firstWhere(
                          (option) => option.value == widget.pref.value,
                        )
                        .widget,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(TarusIkon.asagi, size: 16, color: r.muted2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.pref.removeListener(onChanged);
    super.dispose();
  }
}
