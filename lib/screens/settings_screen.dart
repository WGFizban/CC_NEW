import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';
import '../l10n/l10n.dart';
import '../widgets/adaptive_layout.dart';

/// Zestaw ustawień zgłaszany przez [SettingsScreen].
typedef SettingsValues = ({
  bool keepScreenOn,
  bool showGroupTitles,
  bool groupsOnNewLines,
  ThemeMode themeMode,
  AppLanguage language,
});

/// Ustawienia aplikacji: wygląd, język, ekran. Zmiany są zgłaszane
/// od razu przez [onChanged], a ekran tylko pokazuje przełączniki.
class SettingsScreen extends StatefulWidget {
  final bool keepScreenOn;
  final bool showGroupTitles;
  final bool groupsOnNewLines;
  final ThemeMode themeMode;
  final AppLanguage language;

  final void Function(SettingsValues values) onChanged;

  const SettingsScreen({
    super.key,
    required this.keepScreenOn,
    required this.showGroupTitles,
    required this.groupsOnNewLines,
    required this.themeMode,
    required this.language,
    required this.onChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _keepScreenOn = widget.keepScreenOn;
  late bool _showGroupTitles = widget.showGroupTitles;
  late bool _groupsOnNewLines = widget.groupsOnNewLines;
  late ThemeMode _themeMode = widget.themeMode;
  late AppLanguage _language = widget.language;

  void _notify() => widget.onChanged((
    keepScreenOn: _keepScreenOn,
    showGroupTitles: _showGroupTitles,
    groupsOnNewLines: _groupsOnNewLines,
    themeMode: _themeMode,
    language: _language,
  ));

  /// Etykieta segmentu w jednej linii; przy bardzo wąskim ekranie zmniejsza się
  /// zamiast łamać słowo.
  Widget _oneLine(String text) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );

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
      body: ContentWidth(child: ListView(
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
                    // Ikona zaznaczenia i ikony motywów zabierały miejsce, przez
                    // co na wąskim telefonie „Systemowy" łamał się do nowej linii.
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: _oneLine(l.themeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: _oneLine(l.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: _oneLine(l.themeDark),
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
                  child: DropdownButtonFormField<AppLanguage>(
                    initialValue: _language,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      for (final lang in AppLanguage.values)
                        DropdownMenuItem(
                          value: lang,
                          child: Text(lang.nativeName),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _language = v);
                      _notify();
                    },
                  ),
                ),
              ],
            ),
          ),
          // W przeglądarce nie wygaszamy ekranu na życzenie: sekcja ukryta.
          if (!kIsWeb) ...[
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
          const Divider(),
          _header(l.typeScreenSection),
          SwitchListTile(
            title: Text(l.showGroupTitles),
            value: _showGroupTitles,
            onChanged: (on) {
              setState(() => _showGroupTitles = on);
              _notify();
            },
          ),
          SwitchListTile(
            title: Text(l.groupsOnNewLines),
            subtitle: Text(l.groupsOnNewLinesHint),
            value: _groupsOnNewLines,
            onChanged: (on) {
              setState(() => _groupsOnNewLines = on);
              _notify();
            },
          ),
        ],
      )),
    );
  }
}
