import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../l10n/l10n.dart';
import '../l10n/labels.dart';
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
          const Divider(),
          _header(l.expansionsSection),
          if (locked)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l.gameInProgress),
                  subtitle: Text(l.expansionsLocked),
                ),
              ),
            ),
          SwitchListTile(
            title: Text(
              l.allExpansions,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            value: _allOn,
            onChanged: locked ? null : _setAll,
          ),
          for (final e in Expansion.values)
            SwitchListTile(
              title: LabelWithHint(e.label(l), e.description(l)),
              value: _expansions.contains(e),
              onChanged: locked ? null : (on) => _setExpansion(e, on),
            ),
        ],
      ),
    );
  }
}
