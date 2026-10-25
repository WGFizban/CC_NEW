import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../l10n/l10n.dart';

/// Zestaw ustawień zgłaszany przez [SettingsScreen].
typedef SettingsValues = ({
  bool keepScreenOn,
  ThemeMode themeMode,
  AppLanguage language,
});

/// Ustawienia aplikacji: wygląd, język, ekran. Zmiany są zgłaszane
/// od razu przez [onChanged], a ekran tylko pokazuje przełączniki.
class SettingsScreen extends StatefulWidget {
  final bool keepScreenOn;
  final ThemeMode themeMode;
  final AppLanguage language;

  final void Function(SettingsValues values) onChanged;

  const SettingsScreen({
    super.key,
    required this.keepScreenOn,
    required this.themeMode,
    required this.language,
    required this.onChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _keepScreenOn = widget.keepScreenOn;
  late ThemeMode _themeMode = widget.themeMode;
  late AppLanguage _language = widget.language;

  void _notify() => widget.onChanged((
    keepScreenOn: _keepScreenOn,
    themeMode: _themeMode,
    language: _language,
  ));

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          _header(l.appearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.theme),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto),
                        label: Text(l.themeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode),
                        label: Text(l.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode),
                        label: Text(l.themeDark),
                      ),
                    ],
                    selected: {_themeMode},
                    onSelectionChanged: (s) {
                      setState(() => _themeMode = s.first);
                      _notify();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(l.language),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AppLanguage>(
                    segments: [
                      for (final l in AppLanguage.values)
                        ButtonSegment(value: l, label: Text(l.nativeName)),
                    ],
                    selected: {_language},
                    onSelectionChanged: (s) {
                      setState(() => _language = s.first);
                      _notify();
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          _header(l.screenSection),
          SwitchListTile(
            title: Text(l.keepScreenOn),
            subtitle: Text(l.keepScreenOnHint),
            value: _keepScreenOn,
            onChanged: (on) {
              setState(() => _keepScreenOn = on);
              _notify();
            },
          ),
        ],
      ),
    );
  }
}
