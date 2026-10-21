import 'package:flutter/material.dart';

import 'circus.dart';
import 'expansion.dart';
import 'sheep.dart';

/// Rodzaje punktacji dostępne w aplikacji. Typy z dodatków pojawiają się
/// tylko wtedy, gdy dany dodatek jest włączony.
enum ScoringType {
  city('Miasto', Icons.location_city, imagePath: 'assets/images/city.jpg'),
  road('Droga', Icons.route, imagePath: 'assets/images/road.jpg'),
  cloister('Klasztor', Icons.church, imagePath: 'assets/images/cloister.jpg'),
  meadow('Pola', Icons.grass, imagePath: 'assets/images/meadow.jpg'),
  fairy('Wróżka', Icons.auto_awesome, imagePath: 'assets/images/fairy.png'),
  sheep(
    'Owce',
    Icons.pets,
    imagePath: 'assets/images/sheeps.jpg',
    expansion: Expansion.hillsSheep,
  ),
  goods(
    'Surowce',
    Icons.inventory_2,
    expansion: Expansion.tradersBuilders,
  ),
  castle(
    'Zamek',
    Icons.castle,
    expansion: Expansion.bridgesCastlesBazaars,
  ),
  bazaar(
    'Bazar',
    Icons.gavel,
    expansion: Expansion.bridgesCastlesBazaars,
  ),
  circus('Cyrk', Icons.festival, expansion: Expansion.circus),
  pyramid('Akrobaci', Icons.change_history, expansion: Expansion.circus),
  ringmaster('Dyrektor cyrku', Icons.star, expansion: Expansion.circus);

  const ScoringType(
    this.displayName,
    this.icon, {
    this.imagePath,
    this.expansion,
  });

  final String displayName;
  final IconData icon;

  /// Zdjęcie na kafelku; typy bez zdjęcia pokazują [icon].
  final String? imagePath;

  /// Dodatek wymagany do tego typu punktacji (`null` = gra podstawowa).
  final Expansion? expansion;

  static List<ScoringType> availableFor(Set<Expansion> enabled) => [
    for (final t in values)
      if (t.expansion == null || enabled.contains(t.expansion)) t,
  ];
}

/// Liczy punkty za pojedynczy obiekt.
///
/// - [tiles] – liczba płytek (pola: liczba ukończonych miast; wróżka:
///   wpisane punkty; zamek: punkty ukończonej sąsiedniej budowli),
/// - [banners] – sztandary (tylko miasto),
/// - [bridges] – płytki z mostem, których nie ma jeszcze w [tiles]
///   (most punktuje jak płytka z drogą, ale płytka liczy się tylko raz),
/// - [castles] – zamki przy polu, każdy wart 4 zamiast 3,
/// - [vineyards] – winnice wokół ukończonego klasztoru, po 3 pkt,
/// - [completed] – czy miasto/droga/klasztor jest ukończony,
/// - [bonus] – katedra (miasto), karczma (droga) lub świnka (pola),
/// - [circusTiles] – płytki cyrku i akrobatów wokół dyrektora cyrku
///   (po 2 pkt, doliczane do dowolnej punktacji z jego udziałem).
int calculatePoints(
  ScoringType type, {
  required int tiles,
  int banners = 0,
  int bridges = 0,
  int castles = 0,
  int vineyards = 0,
  bool completed = true,
  bool bonus = false,
  int circusTiles = 0,
}) {
  final int base;
  switch (type) {
    case ScoringType.city:
      final count = tiles + banners;
      if (completed) {
        base = count * (bonus ? 3 : 2);
      } else {
        // Niedokończone miasto z katedrą nie daje punktów.
        base = bonus ? 0 : count;
      }

    case ScoringType.road:
      final length = tiles + bridges;
      if (completed) {
        base = length * (bonus ? 2 : 1);
      } else {
        // Niedokończona droga z karczmą nie daje punktów.
        base = bonus ? 0 : length;
      }

    case ScoringType.cloister:
      // Winnice punktują tylko przy ukończonym klasztorze.
      base = completed ? 9 + vineyards * kVineyardPoints : tiles;

    case ScoringType.meadow:
      // Zamek na polu jest wart 4 pkt zamiast 3 (ze świnką o 1 więcej,
      // tak jak miasto).
      base = tiles * (bonus ? 4 : 3) + castles * (bonus ? 5 : 4);

    case ScoringType.fairy:
    case ScoringType.sheep:
    case ScoringType.castle:
      base = tiles;

    case ScoringType.goods:
    case ScoringType.bazaar:
    case ScoringType.circus:
    case ScoringType.pyramid:
    case ScoringType.ringmaster:
      base = 0;
  }
  return base + ringmasterPoints(circusTiles);
}
