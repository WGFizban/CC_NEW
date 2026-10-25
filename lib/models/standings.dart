import 'dart:math' as math;

import 'gold.dart';
import 'goods.dart';
import 'player.dart';

/// Premia za największą liczbę danego surowca.
const int kGoodsBonus = 10;

/// Gracze prowadzący w danym surowcu: ci z największą, niezerową liczbą
/// żetonów. Przy remisie prowadzą wszyscy remisujący.
List<Player> goodsLeaders(Goods goods, List<Player> players) {
  var best = 0;
  for (final p in players) {
    best = math.max(best, p.goodsOf(goods));
  }
  if (best == 0) return const [];
  return [
    for (final p in players)
      if (p.goodsOf(goods) == best) p,
  ];
}

/// Premia gracza za surowce w danej chwili: 10 pkt za każdy rodzaj,
/// w którym prowadzi (przy remisie każdy z remisujących dostaje pełne 10).
int goodsBonus(Player player, List<Player> players) {
  var bonus = 0;
  for (final g in Goods.values) {
    if (goodsLeaders(g, players).contains(player)) bonus += kGoodsBonus;
  }
  return bonus;
}

/// Ile żetonów danego surowca zostało jeszcze w puli, czyli poza graczami.
int goodsRemaining(Goods goods, List<Player> players) {
  var held = 0;
  for (final p in players) {
    held += p.goodsOf(goods);
  }
  return math.max(0, goods.supply - held);
}

/// Ile sztabek złota zostało jeszcze w puli, czyli poza graczami.
int goldRemaining(List<Player> players) {
  var held = 0;
  for (final p in players) {
    held += p.gold;
  }
  return math.max(0, kGoldSupply - held);
}

/// Wynik końcowy gracza: punkty z planszy plus premia za surowce oraz
/// wartość zebranego złota. Liczony dopiero w podsumowaniu gry; w trakcie gry
/// pokazujemy tylko punkty z planszy (`player.points`).
int finalScore(Player player, List<Player> players) =>
    player.points + goodsBonus(player, players) + goldPoints(player.gold);
