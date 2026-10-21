import 'package:flutter/material.dart';

import '../models/expansion.dart';

/// Włączanie i wyłączanie dodatków. Zmiany są zgłaszane od razu przez
/// [onChanged], a ekran tylko pokazuje przełączniki.
class ExpansionsScreen extends StatefulWidget {
  final Set<Expansion> initial;
  final ValueChanged<Set<Expansion>> onChanged;

  const ExpansionsScreen({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<ExpansionsScreen> createState() => _ExpansionsScreenState();
}

class _ExpansionsScreenState extends State<ExpansionsScreen> {
  late final Set<Expansion> _enabled = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dodatki')),
      body: ListView(
        children: [
          for (final e in Expansion.values)
            SwitchListTile(
              title: Text(e.displayName),
              subtitle: Text(e.description),
              value: _enabled.contains(e),
              onChanged: (on) {
                setState(() {
                  if (on) {
                    _enabled.add(e);
                  } else {
                    _enabled.remove(e);
                  }
                });
                widget.onChanged({..._enabled});
              },
            ),
        ],
      ),
    );
  }
}
