import 'package:flutter/material.dart';

import '../models/expansion.dart';
import '../models/history_entry.dart';
import 'history_screen.dart';

/// Ustawienia aplikacji: ekran i dodatki. Zmiany są zgłaszane od razu przez
/// [onChanged], a ekran tylko pokazuje przełączniki.
class SettingsScreen extends StatefulWidget {
  final Set<Expansion> expansions;
  final bool keepScreenOn;
  final void Function(Set<Expansion> expansions, bool keepScreenOn) onChanged;

  /// Historia zatwierdzonych punktów i jej czyszczenie.
  final List<HistoryEntry> history;
  final VoidCallback onClearHistory;

  const SettingsScreen({
    super.key,
    required this.expansions,
    required this.keepScreenOn,
    required this.onChanged,
    required this.history,
    required this.onClearHistory,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Set<Expansion> _expansions = {...widget.expansions};
  late bool _keepScreenOn = widget.keepScreenOn;

  void _notify() => widget.onChanged({..._expansions}, _keepScreenOn);

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
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        children: [
          _header('Ekran'),
          SwitchListTile(
            title: const Text('Nie wygaszaj ekranu'),
            subtitle: const Text(
              'Ekran nie zgaśnie, dopóki aplikacja jest otwarta.',
            ),
            value: _keepScreenOn,
            onChanged: (on) {
              setState(() => _keepScreenOn = on);
              _notify();
            },
          ),
          const Divider(),
          _header('Historia'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historia punktów'),
            subtitle: const Text('Wszystkie zatwierdzone punkty, od najnowszych.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryScreen(
                  entries: widget.history,
                  onClear: widget.onClearHistory,
                ),
              ),
            ),
          ),
          const Divider(),
          _header('Dodatki'),
          for (final e in Expansion.values)
            SwitchListTile(
              title: Text(e.displayName),
              subtitle: Text(e.description),
              value: _expansions.contains(e),
              onChanged: (on) {
                setState(() {
                  if (on) {
                    _expansions.add(e);
                  } else {
                    _expansions.remove(e);
                  }
                });
                _notify();
              },
            ),
        ],
      ),
    );
  }
}
