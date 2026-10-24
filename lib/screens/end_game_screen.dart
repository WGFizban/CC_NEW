import 'package:flutter/material.dart';

import '../models/goods.dart';
import '../models/history_entry.dart';
import '../models/player.dart';
import '../models/standings.dart';
import '../widgets/meeple_icon.dart';

/// Podsumowanie gry: zwycięzca, ranking i rozbicie punktów. Zwraca `true`,
/// gdy użytkownik chce od razu zacząć nową grę.
class EndGameScreen extends StatelessWidget {
  final List<Player> players;
  final List<HistoryEntry> log;

  /// Czas gry, jeśli stoper był używany.
  final Duration? elapsed;
  final bool showGoods;

  const EndGameScreen({
    super.key,
    required this.players,
    required this.log,
    required this.showGoods,
    this.elapsed,
  });

  /// Punkty gracza według rodzaju punktacji, z historii.
  Map<String, int> _categories(Player p) {
    final result = <String, int>{};
    for (final e in log) {
      for (final c in e.changes) {
        if (c.player == p.name && c.points != 0) {
          final key = e.category ?? 'Inne';
          result[key] = (result[key] ?? 0) + c.points;
        }
      }
    }
    // Punkty bez wpisu w historii (np. po jej wyczyszczeniu).
    final rest = p.points - result.values.fold(0, (a, b) => a + b);
    if (rest != 0) result['Inne'] = (result['Inne'] ?? 0) + rest;
    return result;
  }

  static String _duration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:'
        '${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final scores = {for (final p in players) p: totalScore(p, players)};
    final ranking = [...players]
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    final best = ranking.isEmpty ? 0 : scores[ranking.first]!;
    final winners = [
      for (final p in ranking)
        if (scores[p] == best) p,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Koniec gry')),
      body: players.isEmpty
          ? const Center(child: Text('Brak graczy.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _winnerBanner(context, winners, best),
                if (elapsed != null && elapsed! > Duration.zero)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Czas gry: ${_duration(elapsed!)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                for (var i = 0; i < ranking.length; i++)
                  _playerCard(
                    context,
                    ranking[i],
                    // Remis dzieli miejsce.
                    1 + ranking.indexWhere((p) => scores[p] == scores[ranking[i]]),
                    scores[ranking[i]]!,
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Nowa gra'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Wróć do gry'),
                ),
              ],
            ),
    );
  }

  Widget _winnerBanner(BuildContext context, List<Player> winners, int best) {
    final title = winners.length == 1 ? 'Zwycięzca' : 'Remis na czele';
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
            Text('$best pkt', style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Widget _playerCard(BuildContext context, Player p, int place, int total) {
    final bonus = goodsBonus(p, players);
    final categories = _categories(p);
    final goods = [
      for (final g in Goods.values)
        if (p.goodsOf(g) > 0) '${g.displayName} ×${p.goodsOf(g)}',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '$place.',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                MeepleIcon(color: p.color, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (categories.isNotEmpty || bonus > 0) const Divider(height: 20),
            for (final e in categories.entries) _row(e.key, '${e.value}'),
            if (showGoods && bonus > 0)
              _row('Premia za surowce', '+$bonus'),
            if (showGoods && goods.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Surowce: ${goods.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
