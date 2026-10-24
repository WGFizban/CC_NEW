import 'package:flutter/material.dart';

import '../models/circus.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../widgets/confirm_action.dart';
import '../widgets/info_hint.dart';
import '../widgets/player_counter_tile.dart';

/// Punktowanie cyrku: po wyłożeniu płytki cyrku odkrywasz żeton zwierzęcia
/// spod namiotu, a każdy ludek na tej płytce i ośmiu sąsiednich daje
/// właścicielowi tyle punktów, ile wynosi żeton. Ludki zostają na planszy.
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
        'Cyrk (${animal.displayName})',
        changes,
        animal: animal,
        category: 'Cyrk',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animal = _animal;
    final allUsed = CircusAnimal.values.every((a) => _remaining(a) <= 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Punktacja cyrku'),
        actions: [
          ConfirmAction(onPressed: animal == null ? null : _confirm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '1. Odkryj żeton zwierzęcia spod namiotu i wybierz go:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final a in CircusAnimal.values)
                ChoiceChip(
                  label: Text(
                    '${a.displayName} · ${a.value} pkt '
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
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Wszystkie żetony zwierząt zostały już zużyte. '
                'Zeruje je reset punktów.',
              ),
            ),
          const SizedBox(height: 16),
          const LabelWithHint(
            '2. Ile ludków ma każdy gracz na płytce cyrku i ośmiu '
            'sąsiednich?',
            'Liczą się zwykłe ludki, duże ludki, opaci, wozy, burmistrzowie '
                'i dyrektorzy cyrku. Nie liczą się budowniczowie, świnie, '
                'pasterze ani stodoły. Punktujące ludki zostają na planszy.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final p in widget.players)
            PlayerCounterTile(
              player: p,
              value: _meeples[p] ?? 0,
              max: 20,
              caption: animal == null ? null : '= ${_pointsOf(p)} pkt',
              onChanged: (v) => setState(() => _meeples[p] = v),
            ),
        ],
      ),
    );
  }
}
