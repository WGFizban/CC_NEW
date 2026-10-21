import 'package:flutter/material.dart';

import '../models/player.dart';
import 'counter_stepper.dart';
import 'meeple_icon.dart';

/// Wiersz „gracz + licznik", np. liczba ludków na planszy.
class PlayerCounterTile extends StatelessWidget {
  final Player player;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  /// Dodatkowy opis pod imieniem, np. „= 12 pkt".
  final String? caption;

  const PlayerCounterTile({
    super.key,
    required this.player,
    required this.value,
    required this.max,
    required this.onChanged,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          MeepleIcon(color: player.color, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (caption != null)
                  Text(caption!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          CounterStepper(value: value, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}
