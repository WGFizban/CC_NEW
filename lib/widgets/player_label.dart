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

/// Znacznik gracza do wstawienia w tekście zamiast imienia (np. jako argument
/// funkcji z tłumaczeń); [PlayerRichText] zamienia go na mepla i imię.
String playerMark(int index) => String.fromCharCode(0xE000 + index);

/// Tekst opisu z imionami graczy poprzedzonymi meplem w ich kolorze.
///
/// [template] to zwykły przetłumaczony tekst, w którym imiona zastąpiono
/// znacznikami [playerMark] (indeks w [players]), dzięki czemu także dwóch
/// graczy o tym samym imieniu jest rozróżnionych kolorem mepla.
class PlayerRichText extends StatelessWidget {
  final String template;
  final List<Player> players;
  final TextAlign textAlign;
  final TextStyle? style;

  const PlayerRichText(
    this.template, {
    super.key,
    required this.players,
    this.textAlign = TextAlign.center,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    void flush() {
      if (buffer.isEmpty) return;
      spans.add(TextSpan(text: buffer.toString()));
      buffer.clear();
    }

    for (final unit in template.runes) {
      final index = unit - 0xE000;
      if (index >= 0 && index < players.length) {
        flush();
        final p = players[index];
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MeepleIcon(color: p.color, size: (base.fontSize ?? 14) + 4),
                const SizedBox(width: 3),
                Text(p.name, style: base),
              ],
            ),
          ),
        );
      } else {
        buffer.writeCharCode(unit);
      }
    }
    flush();
    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      style: base,
    );
  }
}
