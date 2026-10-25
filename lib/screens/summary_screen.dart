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
import '../widgets/game_icon.dart';
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

  Widget _typeHeader(BuildContext context, ScoringType type) {
    return Builder(
      builder: (ctx) => GestureDetector(
        onTap: () => showHintBubble(ctx, message: type.title(ctx.l10n)),
        child: GameIcon(type.iconAsset, size: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final byType = pointsByType(log);
    // Surowce i złoto nie dają punktów w trakcie gry – mają osobne kolumny
    // z premią i wartością złota, żeby wiersze sumowały się do wyniku.
    final types = [
      for (final t in ScoringType.availableFor(expansions))
        if (t != ScoringType.goods && t != ScoringType.gold) t,
    ];
    final showGoods = expansions.contains(Expansion.tradersBuilders);
    final showGold = expansions.contains(Expansion.goldMines);
    final hasOther = players.any(
      (p) => (byType[p.name]?[null] ?? 0) != 0,
    );

    final scores = {for (final p in players) p: finalScore(p, players)};
    final ranking = [...players]
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    DataCell num(int v, {bool bold = false}) => DataCell(
      Center(
        child: Text(
          v == 0 ? '–' : '$v',
          style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
        ),
      ),
    );

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
            for (final t in types) num(byType[p.name]?[t] ?? 0),
            if (showGoods) num(goodsBonus(p, players)),
            if (showGold) num(goldPoints(p.gold)),
            if (hasOther) num(byType[p.name]?[null] ?? 0),
            num(scores[p]!, bold: true),
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
                  DataColumn(label: _typeHeader(context, t)),
                if (showGoods)
                  DataColumn(
                    label: _typeHeader(context, ScoringType.goods),
                  ),
                if (showGold)
                  DataColumn(label: _typeHeader(context, ScoringType.gold)),
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
