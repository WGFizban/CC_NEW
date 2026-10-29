import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../models/goods.dart';
import '../models/player.dart';
import '../models/standings.dart';
import '../theme/app_theme.dart';
import 'counter_stepper.dart';
import 'game_icon.dart';

extension GoodsStyle on Goods {
  /// Ikona z jednolitego zestawu gry.
  String get iconAsset => switch (this) {
    Goods.wine => 'assets/icons/game/wine.svg',
    Goods.grain => 'assets/icons/game/grain.svg',
    Goods.cloth => 'assets/icons/game/cloth.svg',
  };

  Color get color => switch (this) {
    Goods.wine => const Color(0xFF7B3FA0),
    Goods.grain => const Color(0xFFD99A1E),
    Goods.cloth => const Color(0xFFC8303B),
  };
}

/// Liczniki trzech surowców (wino, pszenica, sukno).
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
                GameIcon(g.iconAsset, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.title(context.l10n),
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (maxFor != null)
                        Text(
                          context.l10n.goodsInSupply(maxFor!(g), g.supply),
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

/// Surowce gracza w wierszu; te, w których prowadzi, są wyróżnione.
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
        color: leading
            ? goods.color.withValues(alpha: 0.25)
            : badgeColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: leading ? goods.color : outlineSoft(context),
          width: leading ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(goods.iconAsset, size: 20),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Sztabki złota gracza w wierszu (minidodatek „Kopalnie złota").
class GoldBadge extends StatelessWidget {
  final int count;

  const GoldBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineSoft(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameIcon('assets/icons/game/gold.svg', size: 20),
          const SizedBox(width: 4),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
