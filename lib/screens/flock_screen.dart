import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../models/sheep.dart';
import '../widgets/confirm_action.dart';
import '../widgets/counter_stepper.dart';
import '../widgets/info_hint.dart';
import '../widgets/meeple_icon.dart';

/// Punktowanie stada z dodatku „Wzgórza i owce".
///
/// Stado składa się z żetonów owiec (1, 2, 3 lub 4 owce). Liczbę żetonów
/// każdego rodzaju ogranicza ich liczba w grze (4×1, 5×2, 5×3, 2×4),
/// więc stado nie może mieć więcej niż [kMaxSheep] owiec. Wszyscy pasterze
/// w jednym polu dostają punkty za całe stado.
class FlockScreen extends StatefulWidget {
  final Player player;
  final List<Player> players;

  const FlockScreen({super.key, required this.player, required this.players});

  @override
  State<FlockScreen> createState() => _FlockScreenState();
}

class _FlockScreenState extends State<FlockScreen> {
  final Map<int, int> _tokens = {for (final v in kSheepTokens.keys) v: 0};
  late final Set<Player> _shepherds = {widget.player};

  int get _sheep => flockPoints(_tokens);

  int get _tokenCount => _tokens.values.fold(0, (a, b) => a + b);

  void _confirm() {
    final sheep = _sheep;
    final owners = [
      for (final p in widget.players)
        if (_shepherds.contains(p)) p,
    ];
    final names = owners.map((p) => p.name).join(', ');
    Navigator.pop(
      context,
      ScoreEvent(
        context.l10n.flockEventLabel(names, sheep),
        [for (final p in owners) ScoreChange(p, sheep)],
        category: context.l10n.scSheep,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheep = _sheep;
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.flockTitle(widget.player.name)),
        backgroundColor: widget.player.color.withValues(alpha: 0.2),
        actions: [
          ConfirmAction(
            onPressed: sheep > 0 && _shepherds.isNotEmpty ? _confirm : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LabelWithHint(
            l.flockHowMany,
            l.flockHint(kMaxSheep),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final entry in kSheepTokens.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.flockToken(entry.key, l.sheepWord(entry.key)),
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          l.tokensInGame(entry.value),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  CounterStepper(
                    value: _tokens[entry.key] ?? 0,
                    max: entry.value,
                    onChanged: (v) => setState(() => _tokens[entry.key] = v),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Center(
            child: Text(
              l.flockSummary(sheep, kMaxSheep, _tokenCount, kSheepTokenCount),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          LabelWithHint(
            l.shepherdsTitle,
            l.shepherdsHint,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in widget.players)
                FilterChip(
                  avatar: MeepleIcon(color: p.color, size: 22),
                  label: Text(p.name),
                  selected: _shepherds.contains(p),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _shepherds.add(p);
                    } else {
                      _shepherds.remove(p);
                    }
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
