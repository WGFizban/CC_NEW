import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/history_entry.dart';
import '../widgets/game_icon.dart';
import '../widgets/info_hint.dart';
import '../widgets/meeple_icon.dart';

/// Historia zatwierdzonych punktów jako tabela, od najnowszych wpisów.
/// Każda zmiana gracza to osobny wiersz w kolorze tego gracza; zdarzenie jest
/// przy pierwszym wierszu danego wpisu. Kolumny: gracz, zdarzenie, punkty,
/// surowce, łącznie.
class HistoryScreen extends StatefulWidget {
  final List<HistoryEntry> entries;
  /// Czyszczenie historii; `null` ukrywa przycisk (np. po zakończeniu gry).
  final VoidCallback? onClear;

  const HistoryScreen({super.key, required this.entries, this.onClear});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<HistoryEntry> _entries = List.of(widget.entries);

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.clearHistoryQuestion),
        content: Text(ctx.l10n.clearHistoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.clear),
          ),
        ],
      ),
    );
    if (ok != true) return;
    widget.onClear?.call();
    setState(() => _entries = []);
  }

  /// Zdarzenie jako ikona rodzaju punktacji (opis w podpowiedzi); starsze
  /// wpisy bez rodzaju pokazują tekst.
  Widget _eventCell(BuildContext context, HistoryEntry e) {
    final text = e.category ?? e.label;
    final type = e.scoringType;
    if (type == null) return Text(text);
    return Builder(
      builder: (ctx) => GestureDetector(
        onTap: () => showHintBubble(ctx, message: text),
        child: GameIcon(type.iconAsset, size: 28),
      ),
    );
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
              DataCell(first ? _eventCell(context, e) : const Text('')),
              DataCell(
                Text(
                  points,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text(c?.goodsText(context.l10n) ?? '')),
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
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.historyTitle),
        actions: [
          if (widget.onClear != null)
            IconButton(
              tooltip: l.clearHistoryTooltip,
              onPressed: _entries.isEmpty ? null : _clear,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _entries.isEmpty
          ? Center(child: Text(l.historyEmpty))
          : SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 48,
                  columns: [
                    DataColumn(label: Text(l.colPlayer)),
                    DataColumn(label: Text(l.colEvent)),
                    DataColumn(
                      label: Text(l.colPoints),
                      numeric: true,
                    ),
                    DataColumn(label: Text(l.colGoods)),
                    DataColumn(
                      label: Text(l.colTotal),
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
