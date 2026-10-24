import 'package:flutter/material.dart';

import '../models/expansion.dart';

/// Ustawienia aplikacji: ekran i dodatki. Zmiany są zgłaszane od razu przez
/// [onChanged], a ekran tylko pokazuje przełączniki.
class SettingsScreen extends StatefulWidget {
  final Set<Expansion> expansions;
  final bool keepScreenOn;

  /// Gra trwa: dodatków nie można zmieniać do jej zakończenia.
  final bool expansionsLocked;
  final void Function(Set<Expansion> expansions, bool keepScreenOn) onChanged;

  const SettingsScreen({
    super.key,
    required this.expansions,
    required this.keepScreenOn,
    required this.expansionsLocked,
    required this.onChanged,
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
          _header('Dodatki'),
          if (widget.expansionsLocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Gra trwa'),
                  subtitle: Text(
                    'Dodatków nie można zmienić do końca gry. Zakończ grę '
                    'i zacznij nową albo zresetuj punkty w menu.',
                  ),
                ),
              ),
            ),
          for (final e in Expansion.values)
            SwitchListTile(
              title: Text(e.displayName),
              subtitle: Text(e.description),
              value: _expansions.contains(e),
              onChanged: widget.expansionsLocked
                  ? null
                  : (on) {
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
