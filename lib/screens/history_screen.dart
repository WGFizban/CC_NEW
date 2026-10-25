import 'package:flutter/material.dart';

import '../l10n/tr.dart';
import '../models/history_entry.dart';
import '../widgets/meeple_icon.dart';

/// Historia zatwierdzonych punktów jako tabela, od najnowszych wpisów.
/// Każda zmiana gracza to osobny wiersz w kolorze tego gracza; czas i zdarzenie
/// są przy pierwszym wierszu danego wpisu. Kolumny: czas, gracz, zdarzenie,
/// punkty, surowce, łącznie.
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

  static String _format(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Wyczyścić historię?', 'Clear history?')),
        content: Text(
          tr(
            'Punkty graczy zostaną bez zmian.',
            'Players\' points will stay unchanged.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Anuluj', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Wyczyść', 'Clear')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    widget.onClear();
    setState(() => _entries = []);
  }

  List<DataRow> _rows(BuildContext context) {
    final rows = <DataRow>[];
    for (final e in _entries.reversed) {
      final changes = e.changes;
      final count = changes.isEmpty ? 1 : changes.length;
      for (var i = 0; i < count; i++) {
        final c = changes.isEmpty ? null : changes[i];
        final first = i == 0;
        final color = c?.color == null ? null : Color(c!.color!);
        final points = c == null || c.points == 0
            ? ''
            : '${c.points > 0 ? '+' : ''}${c.points}';
        rows.add(
          DataRow(
            // Wiersz w kolorze gracza (przyciemniony, żeby tekst był czytelny).
            color: color == null
                ? null
                : WidgetStatePropertyAll(color.withValues(alpha: 0.22)),
            cells: [
              DataCell(Text(first ? _format(e.time) : '')),
              DataCell(
                c == null
                    ? const Text('')
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (color != null) ...[
                            MeepleIcon(color: color, size: 22),
                            const SizedBox(width: 6),
                          ],
                          Text(c.player),
                        ],
                      ),
              ),
              DataCell(Text(first ? e.category ?? e.label : '')),
              DataCell(
                Text(
                  points,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text(c?.goodsText ?? '')),
              DataCell(
                Text(
                  c?.total == null ? '' : '${c!.total}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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
        title: Text(tr('Historia punktów', 'Points history')),
        actions: [
          IconButton(
            tooltip: tr('Wyczyść historię', 'Clear history'),
            onPressed: _entries.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _entries.isEmpty
          ? Center(child: Text(tr('Historia jest pusta.', 'History is empty.')))
          : SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 48,
                  columns: [
                    DataColumn(label: Text(tr('Czas', 'Time'))),
                    DataColumn(label: Text(tr('Gracz', 'Player'))),
                    DataColumn(label: Text(tr('Zdarzenie', 'Event'))),
                    DataColumn(
                      label: Text(tr('Punkty', 'Points')),
                      numeric: true,
                    ),
                    DataColumn(label: Text(tr('Surowce', 'Goods'))),
                    DataColumn(
                      label: Text(tr('Łącznie', 'Total')),
                      numeric: true,
                    ),
                  ],
                  rows: _rows(context),
                ),
              ),
            ),
    );
  }
}
