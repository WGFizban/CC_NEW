import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../models/expansion.dart';
import '../models/gold.dart';
import '../models/history_entry.dart';
import '../models/player.dart';
import '../models/scoring.dart';
import '../models/standings.dart';
import '../models/summary.dart';
import '../models/goods.dart';
import '../widgets/game_icon.dart';
import '../widgets/goods_widgets.dart';
import '../widgets/info_hint.dart';
import '../widgets/meeple_icon.dart';

/// Podsumowanie gry: tabela punktów każdego gracza według rodzaju punktacji
/// (kolejność: zwycięzca na górze) i czas gry pod tabelą.
class SummaryScreen extends StatelessWidget {
  final List<Player> players;
  final List<HistoryEntry> log;
  final Set<Expansion> expansions;
  final Duration elapsed;

  const SummaryScreen({
    super.key,
    required this.players,
    required this.log,
    required this.expansions,
    required this.elapsed,
  });

  static String _duration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:'
        '${two(d.inSeconds.remainder(60))}';
  }

  Widget _header(String asset, String name) {
    return Builder(
      builder: (ctx) => GestureDetector(
        onTap: () => showHintBubble(ctx, message: name),
        child: GameIcon(asset, size: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final byType = pointsByType(log, players);
    // Surowce i złoto nie dają punktów w trakcie gry – mają osobne kolumny
    // z premią i wartością złota, żeby wiersze sumowały się do wyniku.
    final types = [
      for (final t in ScoringType.availableFor(expansions))
        if (t != ScoringType.goods &&
            t != ScoringType.gold &&
            t != ScoringType.crown)
          t,
    ];
    final showGoods = expansions.contains(Expansion.tradersBuilders);
    final showGold = expansions.contains(Expansion.goldMines);
    final hasOther = players.any(
      (p) => (byType[p.id]?[null] ?? 0) != 0,
    );

    final scores = {for (final p in players) p: finalScore(p, players)};
    final ranking = [...players]
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    // Premia za surowce osobno dla każdego rodzaju, żeby było widać źródło.
    final goodsTypes = showGoods ? Goods.values : const <Goods>[];
    int goodsPart(Player p, Goods g) =>
        goodsLeaders(g, players).contains(p) ? kGoodsBonus : 0;

    // Wartości w kolejności kolumn (bez nazwy gracza), osobno dla każdego
    // gracza – potrzebne do wyróżnienia najlepszych w kolumnie.
    List<int> values(Player p) => [
      for (final t in types) byType[p.id]?[t] ?? 0,
      for (final g in goodsTypes) goodsPart(p, g),
      if (showGold) goldPoints(p.gold),
      if (hasOther) byType[p.id]?[null] ?? 0,
      scores[p]!,
    ];
    final table = {for (final p in ranking) p: values(p)};
    final columnCount = table.values.isEmpty ? 0 : table.values.first.length;
    final best = [
      for (var i = 0; i < columnCount; i++)
        table.values.map((v) => v[i]).reduce((a, b) => a > b ? a : b),
    ];
    final accent = Theme.of(context).colorScheme.primary;

    DataCell num(int v, int column, {bool bold = false}) {
      final top = v > 0 && v == best[column];
      return DataCell(
        Center(
          child: top
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$v',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(
                  v == 0 ? '–' : '$v',
                  style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
                ),
        ),
      );
    }

    final rows = [
      for (final p in ranking)
        DataRow(
          color: WidgetStatePropertyAll(p.color.withValues(alpha: 0.22)),
          cells: [
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MeepleIcon(color: p.color, size: 26),
                  const SizedBox(width: 6),
                  Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < columnCount; i++)
              num(table[p]![i], i, bold: i == columnCount - 1),
          ],
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.summaryTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              horizontalMargin: 12,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 52,
              columns: [
                DataColumn(label: Text(l.colPlayer)),
                for (final t in types)
                  DataColumn(label: _header(t.iconAsset, t.title(l))),
                for (final g in goodsTypes)
                  DataColumn(label: _header(g.iconAsset, g.title(l))),
                if (showGold)
                  DataColumn(
                    label: _header(
                      ScoringType.gold.iconAsset,
                      ScoringType.gold.title(l),
                    ),
                  ),
                if (hasOther) DataColumn(label: Text(l.other)),
                DataColumn(label: Text(l.colTotal)),
              ],
              rows: rows,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.gameTime(_duration(elapsed)),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
