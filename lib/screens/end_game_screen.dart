import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/expansion.dart';
import '../models/history_entry.dart';
import '../models/player.dart';
import '../models/standings.dart';
import '../widgets/game_dialogs.dart';
import 'summary_screen.dart';

/// Koniec gry: zwycięzca (albo remis) i dwa przyciski – podsumowanie oraz
/// nowa gra. Zwraca wybrany sposób rozpoczęcia nowej gry; cofnąć się nie
/// można.
class EndGameScreen extends StatelessWidget {
  final List<Player> players;
  final List<HistoryEntry> log;
  final Set<Expansion> expansions;
  final Duration elapsed;

  const EndGameScreen({
    super.key,
    required this.players,
    required this.log,
    required this.expansions,
    required this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scores = {for (final p in players) p: finalScore(p, players)};
    final best = scores.values.isEmpty
        ? 0
        : scores.values.reduce((a, b) => a > b ? a : b);
    final winners = [
      for (final p in players)
        if (scores[p] == best) p,
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.gameOver),
          automaticallyImplyLeading: false,
        ),
        body: players.isEmpty
            ? Center(child: Text(l.noPlayersDot))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _winnerBanner(context, winners, best),
                  const SizedBox(height: 24),
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SummaryScreen(
                          players: players,
                          log: log,
                          expansions: expansions,
                          elapsed: elapsed,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: Text(l.summaryTitle),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      final choice = await askNewGame(context);
                      if (choice != null && context.mounted) {
                        Navigator.pop(context, choice);
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l.newGame),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _winnerBanner(BuildContext context, List<Player> winners, int best) {
    final l = context.l10n;
    final title = winners.length == 1 ? l.winner : l.tiedLead;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Color(0xFFD4A017)),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              winners.map((p) => p.name).join(', '),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(l.pointsValue(best), style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
