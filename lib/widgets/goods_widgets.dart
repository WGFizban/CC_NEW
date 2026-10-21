import 'package:flutter/material.dart';

import '../models/goods.dart';
import '../models/player.dart';
import '../models/standings.dart';
import 'counter_stepper.dart';

extension GoodsStyle on Goods {
  IconData get icon => switch (this) {
    Goods.wine => Icons.wine_bar,
    Goods.grain => Icons.grass,
    Goods.cloth => Icons.checkroom,
  };

  Color get color => switch (this) {
    Goods.wine => const Color(0xFF8E24AA),
    Goods.grain => const Color(0xFFF9A825),
    Goods.cloth => const Color(0xFF1E88E5),
  };
}

/// Liczniki trzech surowców (wino, żyto, sukno).
class GoodsCounters extends StatelessWidget {
  final Map<Goods, int> values;
  final void Function(Goods goods, int value) onChanged;

  /// Ile żetonów danego surowca można jeszcze wziąć z puli (limit z gry).
  final int Function(Goods goods)? maxFor;

  const GoodsCounters({
    super.key,
    required this.values,
    required this.onChanged,
    this.maxFor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final g in Goods.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(g.icon, color: g.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.displayName, style: const TextStyle(fontSize: 16)),
                      if (maxFor != null)
                        Text(
                          'w puli: ${maxFor!(g)} z ${g.supply}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                CounterStepper(
                  value: values[g] ?? 0,
                  max: maxFor?.call(g) ?? 99,
                  onChanged: (v) => onChanged(g, v),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Surowce gracza w wierszu; te, w których prowadzi (premia +10), są wyróżnione.
class GoodsBadges extends StatelessWidget {
  final Player player;
  final List<Player> players;

  const GoodsBadges({super.key, required this.player, required this.players});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final g in Goods.values)
          if (player.goodsOf(g) > 0)
            _GoodsBadge(
              goods: g,
              count: player.goodsOf(g),
              leading: goodsLeaders(g, players).contains(player),
            ),
      ],
    );
  }
}

class _GoodsBadge extends StatelessWidget {
  final Goods goods;
  final int count;
  final bool leading;

  const _GoodsBadge({
    required this.goods,
    required this.count,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: leading ? goods.color.withValues(alpha: 0.25) : Colors.white54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: leading ? goods.color : Colors.black26,
          width: leading ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(goods.icon, size: 16, color: goods.color),
          const SizedBox(width: 4),
          Text(
            leading ? '$count · +$kGoodsBonus' : '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Tabela prowadzących w każdym surowcu (z remisami), liczona na bieżąco.
class GoodsLeaderboard extends StatelessWidget {
  final List<Player> players;

  const GoodsLeaderboard({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final g in Goods.values) _row(g),
          ],
        ),
      ),
    );
  }

  Widget _row(Goods g) {
    final leaders = goodsLeaders(g, players);
    final String text;
    if (leaders.isEmpty) {
      text = '${g.displayName}: nikt jeszcze nie zbiera';
    } else {
      final names = leaders.map((p) => p.name).join(', ');
      final tie = leaders.length > 1 ? ' (remis – każdy +$kGoodsBonus)' : '';
      text =
          '${g.displayName}: ${leaders.first.goodsOf(g)} szt. – $names$tie';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(g.icon, size: 18, color: g.color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
