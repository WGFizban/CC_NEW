import 'package:flutter/material.dart';

import '../l10n/tr.dart';
import '../models/circus.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../widgets/confirm_action.dart';
import '../widgets/info_hint.dart';
import '../widgets/player_counter_tile.dart';

/// Punktowanie cyrku: po wyłożeniu płytki cyrku odkrywasz żeton zwierzęcia
/// spod namiotu, a każdy mepel na tej płytce i ośmiu sąsiednich daje
/// właścicielowi tyle punktów, ile wynosi żeton. Meple zostają na planszy.
///
/// Zwraca [ScoreEvent] z zużytym żetonem zwierzęcia.
class CircusScreen extends StatefulWidget {
  final Player player;
  final List<Player> players;

  /// Ile żetonów każdego zwierzęcia zostało już zużytych.
  final Map<CircusAnimal, int> used;

  const CircusScreen({
    super.key,
    required this.player,
    required this.players,
    required this.used,
  });

  @override
  State<CircusScreen> createState() => _CircusScreenState();
}

class _CircusScreenState extends State<CircusScreen> {
  CircusAnimal? _animal;
  late final Map<Player, int> _meeples = {
    for (final p in widget.players) p: 0,
  };

  int _remaining(CircusAnimal a) => a.count - (widget.used[a] ?? 0);

  int _pointsOf(Player p) {
    final animal = _animal;
    if (animal == null) return 0;
    return circusPoints(animal, _meeples[p] ?? 0);
  }

  void _confirm() {
    final animal = _animal;
    if (animal == null) return;
    final changes = [
      for (final p in widget.players)
        if ((_meeples[p] ?? 0) > 0) ScoreChange(p, _pointsOf(p)),
    ];
    Navigator.pop(
      context,
      ScoreEvent(
        '${tr('Cyrk', 'Circus')} (${animal.displayName})',
        changes,
        animal: animal,
        category: tr('Cyrk', 'Circus'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animal = _animal;
    final allUsed = CircusAnimal.values.every((a) => _remaining(a) <= 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Punktacja cyrku', 'Circus scoring')),
        actions: [
          ConfirmAction(onPressed: animal == null ? null : _confirm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr(
              '1. Odkryj żeton zwierzęcia spod namiotu i wybierz go:',
              '1. Reveal the animal token from under the tent and pick it:',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final a in CircusAnimal.values)
                ChoiceChip(
                  label: Text(
                    '${a.displayName} · ${a.value} ${tr('pkt', 'pts')} '
                    '(${_remaining(a)}/${a.count})',
                  ),
                  selected: animal == a,
                  onSelected: _remaining(a) > 0
                      ? (_) => setState(() => _animal = a)
                      : null,
                ),
            ],
          ),
          if (allUsed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                tr(
                  'Wszystkie żetony zwierząt zostały już zużyte. '
                      'Zeruje je reset punktów.',
                  'All animal tokens have been used. '
                      'Resetting the points restores them.',
                ),
              ),
            ),
          const SizedBox(height: 16),
          LabelWithHint(
            tr(
              '2. Ile mepli ma każdy gracz na płytce cyrku i ośmiu '
                  'sąsiednich?',
              '2. How many meeples does each player have on the circus '
                  'tile and the eight neighboring ones?',
            ),
            tr(
              'Liczą się zwykłe meple, duże meple, opaci, wozy '
                  'i dyrektorzy cyrku. Nie liczą się budowniczowie, świnie, '
                  'pasterze ani stodoły. Punktujące meple zostają na planszy.',
              'Normal meeples, big meeples, abbots, wagons and ringmasters '
                  'count. Builders, pigs, shepherds and barns do not. '
                  'Scoring meeples stay on the board.',
            ),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final p in widget.players)
            PlayerCounterTile(
              player: p,
              value: _meeples[p] ?? 0,
              max: 20,
              caption: animal == null
                  ? null
                  : '= ${_pointsOf(p)} ${tr('pkt', 'pts')}',
              onChanged: (v) => setState(() => _meeples[p] = v),
            ),
        ],
      ),
    );
  }
}
