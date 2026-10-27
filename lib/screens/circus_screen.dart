import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../models/circus.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../models/scoring.dart';
import '../theme/app_theme.dart';
import '../widgets/scoring_app_bar.dart';
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
        context.l10n.circusEventLabel(animal.title(context.l10n)),
        changes,
        animal: animal,
        category: context.l10n.scCircus,
        type: ScoringType.circus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final animal = _animal;
    final allUsed = CircusAnimal.values.every((a) => _remaining(a) <= 0);

    // Neutralna ramka (kolor wierszy graczy): nie wiadomo z góry, kto
    // dokładnie dostanie punkty.
    final frameColor = playerCardColor(context);
    final frameSide = BorderSide(color: frameColor, width: 4);

    return Scaffold(
      bottomNavigationBar: scoringBottomBar(
        context,
        frameColor: frameColor,
        onConfirm: animal == null ? null : _confirm,
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: frameSide,
              left: frameSide,
              right: frameSide,
            ),
          ),
          child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l.circusStep1,
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
                    l.animalChip(
                      a.title(l),
                      a.value,
                      _remaining(a),
                      a.count,
                    ),
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
                l.circusAllUsed,
              ),
            ),
          const SizedBox(height: 16),
          LabelWithHint(
            l.circusStep2,
            l.circusStep2Hint,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final p in widget.players)
            PlayerCounterTile(
              player: p,
              value: _meeples[p] ?? 0,
              max: 20,
              caption: animal == null ? null : l.equalsPoints(_pointsOf(p)),
              onChanged: (v) => setState(() => _meeples[p] = v),
            ),
        ],
      ),
        ),
      ),
    );
  }
}
