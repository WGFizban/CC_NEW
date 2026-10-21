import 'package:flutter/material.dart';

import '../models/player.dart';
import 'meeple_icon.dart';

/// Wybór jednego gracza z listy (np. kto dostaje surowce, kto kupuje na bazarze).
class PlayerPicker extends StatelessWidget {
  final List<Player> players;
  final Player? selected;
  final ValueChanged<Player> onSelected;

  /// Gracz, którego nie można wybrać (np. ten, który już jest drugą stroną).
  final Player? exclude;

  const PlayerPicker({
    super.key,
    required this.players,
    required this.selected,
    required this.onSelected,
    this.exclude,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final p in players)
          if (p != exclude)
            ChoiceChip(
              avatar: MeepleIcon(color: p.color, size: 22),
              label: Text(p.name),
              selected: selected == p,
              onSelected: (_) => onSelected(p),
            ),
      ],
    );
  }
}
