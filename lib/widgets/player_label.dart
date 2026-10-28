import 'package:flutter/material.dart';

import '../models/player.dart';
import 'meeple_icon.dart';

/// Mały mepel w kolorze gracza przed tekstem (zwykle jego imieniem lub
/// opisem z imieniem), żeby graczy o tym samym imieniu dało się odróżnić.
class PlayerLabel extends StatelessWidget {
  final Player player;

  /// Tekst obok mepla; domyślnie imię gracza.
  final String? text;
  final TextStyle? style;
  final double iconSize;

  const PlayerLabel({
    super.key,
    required this.player,
    this.text,
    this.style,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MeepleIcon(color: player.color, size: iconSize),
        const SizedBox(width: 4),
        Flexible(child: Text(text ?? player.name, style: style)),
      ],
    );
  }
}

/// Lista graczy z opisami w jednej linii zawijanej (`mepel tekst · mepel
/// tekst`); gdy lista jest pusta, pokazuje [empty].
class PlayerLabels extends StatelessWidget {
  final List<({Player player, String text})> items;
  final String empty;
  final WrapAlignment alignment;

  const PlayerLabels({
    super.key,
    required this.items,
    required this.empty,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Text(empty);
    return Wrap(
      alignment: alignment,
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i > 0) const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Text('·'),
              ),
              PlayerLabel(player: items[i].player, text: items[i].text),
            ],
          ),
      ],
    );
  }
}
