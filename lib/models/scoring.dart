import 'circus.dart';
import 'expansion.dart';
import 'fairy.dart';
import 'sheep.dart';

/// Rodzaje punktacji dostępne w aplikacji. Typy z dodatków pojawiają się
/// tylko wtedy, gdy dany dodatek jest włączony.
///
/// Wszystkie ikony pochodzą z jednego zestawu w `assets/icons/game/`.
enum ScoringType {
  city('Miasto', 'assets/icons/game/city.svg'),
  road('Droga', 'assets/icons/game/road.svg'),
  cloister('Klasztor', 'assets/icons/game/cloister.svg'),
  meadow('Pola', 'assets/icons/game/meadow.svg'),
  fairy(
    'Wróżka',
    'assets/icons/game/fairy.svg',
    expansion: Expansion.princessDragon,
  ),
  sheep(
    'Owce',
    'assets/icons/game/sheep.svg',
    expansion: Expansion.hillsSheep,
  ),
  goods(
    'Surowce',
    'assets/icons/game/goods.svg',
    expansion: Expansion.tradersBuilders,
  ),
  castle(
    'Zamek',
    'assets/icons/game/castle.svg',
    expansion: Expansion.bridgesCastlesBazaars,
  ),
  bazaar(
    'Bazar',
    'assets/icons/game/bazaar.svg',
    expansion: Expansion.bridgesCastlesBazaars,
  ),
  circus('Cyrk', 'assets/icons/game/circus.svg', expansion: Expansion.circus),
  pyramid(
    'Akrobaci',
    'assets/icons/game/acrobats.svg',
    expansion: Expansion.circus,
  ),
  ringmaster(
    'Dyrektor cyrku',
    'assets/icons/game/ringmaster.svg',
    expansion: Expansion.circus,
  );

  const ScoringType(this.displayName, this.iconAsset, {this.expansion});

  final String displayName;

  /// Ikona SVG z jednolitego zestawu gry.
  final String iconAsset;

  /// Dodatek wymagany do tego typu punktacji (`null` = gra podstawowa).
  final Expansion? expansion;

  /// Budowle punktowane według zasad (do nich można dodać wróżkę
  /// i dyrektora cyrku).
  bool get isFeature =>
      this == city || this == road || this == cloister || this == meadow;

  static List<ScoringType> availableFor(Set<Expansion> enabled) => [
    for (final t in values)
      if (t.expansion == null || enabled.contains(t.expansion)) t,
  ];
}

/// Liczy punkty za pojedynczy obiekt.
///
/// - [tiles] – liczba płytek (pola: liczba ukończonych miast; zamek: punkty
///   ukończonej sąsiedniej budowli; owce: wpisane punkty),
/// - [banners] – sztandary (tylko miasto),
/// - [bridges] – płytki z mostem, których nie ma jeszcze w [tiles]
///   (most punktuje jak płytka z drogą, ale płytka liczy się tylko raz),
/// - [castles] – zamki przy polu, każdy wart 4 zamiast 3,
/// - [vineyards] – winnice wokół ukończonego klasztoru, po 3 pkt,
/// - [completed] – czy miasto/droga/klasztor jest ukończony,
/// - [bonus] – katedra (miasto), karczma (droga) lub świnka (pola),
/// - [circusTiles] – płytki cyrku i akrobatów wokół dyrektora cyrku
///   (po 2 pkt, doliczane do dowolnej punktacji z jego udziałem),
/// - [withFairy] – wróżka stoi przy ludku w tej budowli: +3 pkt
///   niezależnie od reszty (tylko miasto, droga, klasztor i pole).
///
/// Wróżka sama w sobie ([ScoringType.fairy]) to zawsze 1 pkt.
int calculatePoints(
  ScoringType type, {
  int tiles = 0,
  int banners = 0,
  int bridges = 0,
  int castles = 0,
  int vineyards = 0,
  bool completed = true,
  bool bonus = false,
  int circusTiles = 0,
  bool withFairy = false,
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
      return kFairyTurnPoints;

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
  final fairy = withFairy && type.isFeature ? kFairyFeaturePoints : 0;
  return base + ringmasterPoints(circusTiles) + fairy;
}
