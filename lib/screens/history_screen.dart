import 'package:flutter/material.dart';

import '../models/history_entry.dart';

/// Historia zatwierdzonych punktów jako tabela, od najnowszych wpisów.
/// Każda zmiana gracza to osobny wiersz; czas i zdarzenie są przy pierwszym
/// wierszu danego wpisu.
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

  List<DataRow> _rows() {
    final rows = <DataRow>[];
    for (final e in _entries.reversed) {
      final changes = e.changes;
      final count = changes.isEmpty ? 1 : changes.length;
      for (var i = 0; i < count; i++) {
        final c = changes.isEmpty ? null : changes[i];
        final first = i == 0;
        rows.add(
          DataRow(
            cells: [
              DataCell(Text(first ? _format(e.time) : '')),
              DataCell(Text(first ? e.category ?? e.label : '')),
              DataCell(Text(c?.player ?? '')),
              DataCell(
                Text(
                  c == null || c.points == 0
                      ? ''
                      : '${c.points > 0 ? '+' : ''}${c.points}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text(c?.goodsText ?? '')),
            ],
          ),
        );
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
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
      body: _entries.isEmpty
          ? const Center(child: Text('Historia jest pusta.'))
          : SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 48,
                  columns: const [
                    DataColumn(label: Text('Czas')),
                    DataColumn(label: Text('Zdarzenie')),
                    DataColumn(label: Text('Gracz')),
                    DataColumn(label: Text('Punkty'), numeric: true),
                    DataColumn(label: Text('Surowce')),
                  ],
                  rows: _rows(),
                ),
              ),
            ),
    );
  }
}
