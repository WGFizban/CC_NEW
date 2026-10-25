import 'package:flutter/material.dart';

import '../l10n/tr.dart';
import '../models/expansion.dart';
import '../widgets/info_hint.dart';

/// Zestaw ustawień zgłaszany przez [SettingsScreen].
typedef SettingsValues = ({
  Set<Expansion> expansions,
  bool keepScreenOn,
  ThemeMode themeMode,
  AppLanguage language,
});

/// Ustawienia aplikacji: wygląd, język, ekran i dodatki. Zmiany są zgłaszane
/// od razu przez [onChanged], a ekran tylko pokazuje przełączniki.
class SettingsScreen extends StatefulWidget {
  final Set<Expansion> expansions;
  final bool keepScreenOn;
  final ThemeMode themeMode;
  final AppLanguage language;

  /// Gra trwa: dodatków nie można zmieniać do jej zakończenia.
  final bool expansionsLocked;
  final void Function(SettingsValues values) onChanged;

  const SettingsScreen({
    super.key,
    required this.expansions,
    required this.keepScreenOn,
    required this.themeMode,
    required this.language,
    required this.expansionsLocked,
    required this.onChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Set<Expansion> _expansions = {...widget.expansions};
  late bool _keepScreenOn = widget.keepScreenOn;
  late ThemeMode _themeMode = widget.themeMode;
  late AppLanguage _language = widget.language;

  bool get _allOn => _expansions.length == Expansion.values.length;

  void _notify() => widget.onChanged((
    expansions: {..._expansions},
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

  void _setExpansion(Expansion e, bool on) {
    setState(() {
      if (on) {
        _expansions.add(e);
      } else {
        _expansions.remove(e);
      }
    });
    _notify();
  }

  void _setAll(bool on) {
    setState(() {
      _expansions
        ..clear()
        ..addAll(on ? Expansion.values : const <Expansion>[]);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.expansionsLocked;

    return Scaffold(
      appBar: AppBar(title: Text(tr('Ustawienia', 'Settings'))),
      body: ListView(
        children: [
          _header(tr('Wygląd', 'Appearance')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Motyw', 'Theme')),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto),
                        label: Text(tr('Systemowy', 'System')),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode),
                        label: Text(tr('Jasny', 'Light')),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode),
                        label: Text(tr('Ciemny', 'Dark')),
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
                Text(tr('Język', 'Language')),
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
          _header(tr('Ekran', 'Screen')),
          SwitchListTile(
            title: Text(tr('Nie wygaszaj ekranu', 'Keep the screen on')),
            subtitle: Text(
              tr(
                'Ekran nie zgaśnie, dopóki aplikacja jest otwarta.',
                'The screen stays on while the app is open.',
              ),
            ),
            value: _keepScreenOn,
            onChanged: (on) {
              setState(() => _keepScreenOn = on);
              _notify();
            },
          ),
          const Divider(),
          _header(tr('Dodatki', 'Expansions')),
          if (locked)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(tr('Gra trwa', 'Game in progress')),
                  subtitle: Text(
                    tr(
                      'Dodatków nie można zmienić do końca gry. Zakończ grę '
                          'i zacznij nową albo zresetuj punkty w menu.',
                      'Expansions cannot be changed until the game ends. '
                          'End the game and start a new one, or reset the '
                          'points in the menu.',
                    ),
                  ),
                ),
              ),
            ),
          SwitchListTile(
            title: Text(
              tr('Wszystkie dodatki', 'All expansions'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            value: _allOn,
            onChanged: locked ? null : _setAll,
          ),
          for (final e in Expansion.values)
            SwitchListTile(
              title: LabelWithHint(e.label, e.description),
              value: _expansions.contains(e),
              onChanged: locked ? null : (on) => _setExpansion(e, on),
            ),
        ],
      ),
    );
  }
}
