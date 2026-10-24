import 'package:flutter/material.dart';

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
      ScoreEvent('Owce: $names +$sheep', [
        for (final p in owners) ScoreChange(p, sheep),
      ], category: 'Owce'),
    );
  }

  String _sheepWord(int value) => value == 1 ? 'owca' : 'owce';

  @override
  Widget build(BuildContext context) {
    final sheep = _sheep;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.player.name} — Owce'),
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
          const LabelWithHint(
            'Z ilu żetonów składa się stado?',
            'Liczbę żetonów każdego rodzaju ogranicza ich liczba w grze '
                '(4×1, 5×2, 5×3, 2×4), więc stado ma najwyżej $kMaxSheep owiec. '
                'Wilk rozpędza stado – wtedy nie dopisuj punktów. '
                'Owce na koniec gry nie punktują.',
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
                          'Żeton ${entry.key} ${_sheepWord(entry.key)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'w grze: ${entry.value} szt.',
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
              'Stado: $sheep / $kMaxSheep owiec '
              '($_tokenCount / $kSheepTokenCount żetonów)',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          const LabelWithHint(
            'Pasterze w tym polu',
            'Każdy pasterz w tym polu dostaje punkty za całe stado.',
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
