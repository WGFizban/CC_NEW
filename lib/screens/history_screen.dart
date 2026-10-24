import 'package:flutter/material.dart';

import '../models/history_entry.dart';

/// Historia zatwierdzonych punktów, od najnowszych. Dostępna z ustawień.
class HistoryScreen extends StatefulWidget {
  final List<HistoryEntry> entries;
  final VoidCallback onClear;

  const HistoryScreen({super.key, required this.entries, required this.onClear});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<HistoryEntry> _entries = List.of(widget.entries);

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _format(DateTime t) =>
      '${_two(t.day)}.${_two(t.month)} ${_two(t.hour)}:${_two(t.minute)}';

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wyczyścić historię?'),
        content: const Text('Punkty graczy zostaną bez zmian.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Wyczyść'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    widget.onClear();
    setState(() => _entries = []);
  }

  @override
  Widget build(BuildContext context) {
    final newestFirst = _entries.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historia punktów'),
        actions: [
          IconButton(
            tooltip: 'Wyczyść historię',
            onPressed: _entries.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: newestFirst.isEmpty
          ? const Center(child: Text('Historia jest pusta.'))
          : ListView.separated(
              itemCount: newestFirst.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = newestFirst[i];
                return ListTile(
                  title: Text(e.label),
                  subtitle: e.lines.isEmpty ? null : Text(e.lines.join('\n')),
                  trailing: Text(
                    _format(e.time),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
    );
  }
}
