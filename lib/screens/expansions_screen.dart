import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../models/expansion.dart';
import '../widgets/info_hint.dart';

/// Wybór dodatków. Zmiany są zgłaszane od razu przez [onChanged]. Po
/// rozpoczęciu gry przełączniki są zablokowane ([locked]).
class ExpansionsScreen extends StatefulWidget {
  final Set<Expansion> expansions;
  final bool locked;
  final void Function(Set<Expansion> values) onChanged;

  const ExpansionsScreen({
    super.key,
    required this.expansions,
    required this.locked,
    required this.onChanged,
  });

  @override
  State<ExpansionsScreen> createState() => _ExpansionsScreenState();
}

class _ExpansionsScreenState extends State<ExpansionsScreen> {
  late final Set<Expansion> _expansions = {...widget.expansions};

  bool get _allOn => _expansions.length == Expansion.values.length;

  void _setExpansion(Expansion e, bool on) {
    setState(() {
      if (on) {
        _expansions.add(e);
      } else {
        _expansions.remove(e);
      }
    });
    widget.onChanged({..._expansions});
  }

  void _setAll(bool on) {
    setState(() {
      _expansions
        ..clear()
        ..addAll(on ? Expansion.values : const <Expansion>[]);
    });
    widget.onChanged({..._expansions});
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.locked;
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l.expansionsSection)),
      body: ListView(
        children: [
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
              title: LabelWithHint(e.title(l), e.description(l)),
              value: _expansions.contains(e),
              onChanged: locked ? null : (on) => _setExpansion(e, on),
            ),
        ],
      ),
    );
  }
}
