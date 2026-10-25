import '../l10n/tr.dart';
import 'circus.dart';
import 'expansion.dart';
import 'fairy.dart';
import 'sheep.dart';

/// Rodzaje punktacji dostępne w aplikacji. Typy z dodatków pojawiają się
/// tylko wtedy, gdy dany dodatek jest włączony.
///
/// Wszystkie ikony pochodzą z jednego zestawu w `assets/icons/game/`.
enum ScoringType {
  city('Miasto', 'City', 'assets/icons/game/city.svg'),
  road('Droga', 'Road', 'assets/icons/game/road.svg'),
  cloister('Klasztor', 'Cloister', 'assets/icons/game/cloister.svg'),
  meadow('Pola', 'Farms', 'assets/icons/game/meadow.svg'),
  fairy(
    'Wróżka', 'Fairy',
    'assets/icons/game/fairy.svg',
    expansion: Expansion.princessDragon,
  ),
  sheep(
    'Owce', 'Sheep',
    'assets/icons/game/sheep.svg',
    expansion: Expansion.hillsSheep,
  ),
  goods(
    'Surowce', 'Goods',
    'assets/icons/game/goods.svg',
    expansion: Expansion.tradersBuilders,
  ),
  bazaar(
    'Bazar', 'Bazaar',
    'assets/icons/game/bazaar.svg',
    expansion: Expansion.bridgesCastlesBazaars,
  ),
  circus('Cyrk', 'Circus', 'assets/icons/game/circus.svg', expansion: Expansion.circus),
  pyramid(
    'Akrobaci', 'Acrobats',
    'assets/icons/game/acrobats.svg',
    expansion: Expansion.circus,
  ),
  ringmaster(
    'Dyrektor cyrku', 'Ringmaster',
    'assets/icons/game/ringmaster.svg',
    expansion: Expansion.circus,
  ),
  abbey(
    'Opactwo', 'Abbey',
    'assets/icons/game/abbey.svg',
    expansion: Expansion.abbeyMayor,
  ),
  gold(
    'Złoto', 'Gold',
    'assets/icons/game/gold.svg',
    expansion: Expansion.goldMines,
  ),
  tower(
    'Wieża', 'Tower',
    'assets/icons/game/tower.svg',
    expansion: Expansion.tower,
  );

  const ScoringType(this._pl, this._en, this.iconAsset, {this.expansion});

  final String _pl;
  final String _en;

  /// Nazwa punktacji w aktualnym języku.
  String get displayName => tr(_pl, _en);

  /// Ikona SVG z jednolitego zestawu gry.
  final String iconAsset;

  /// Dodatek wymagany do tego typu punktacji (`null` = gra podstawowa).
  final Expansion? expansion;

  /// Budowle punktowane według zasad (do nich można dodać wróżkę
  /// i dyrektora cyrku).
  bool get isFeature =>
      this == city ||
      this == road ||
      this == cloister ||
      this == abbey ||
      this == meadow;

  /// Budowle, przy których może stać zamek z dodatku „Mosty, zamki i bazary":
  /// jego właściciel dostaje punkty ukończonej sąsiedniej budowli (na polach
  /// zamek nie punktuje).
  bool get supportsCastle =>
      this == city || this == road || this == cloister || this == abbey;

  /// Budowle, za które przy ukończeniu dostaje się sztabki złota z minidodatku
  /// (rolnicy złota nie dostają).
  bool get supportsGold =>
      this == city || this == road || this == cloister || this == abbey;

  static List<ScoringType> availableFor(Set<Expansion> enabled) => [
    for (final t in values)
      if (t.expansion == null || enabled.contains(t.expansion)) t,
  ];
}

/// Sposób punktowania pola przy dodatku „Opactwo i burmistrz" (stodoła).
enum FarmScoring {
  /// Zwykłe punktowanie: na koniec gry albo w chwili postawienia stodoły.
  /// 3 pkt za ukończone miasto, 4 za zamek, ze świnką o 1 więcej.
  normal,

  /// Rolnicy na polu połączonym z polem ze stodołą: 1 pkt za miasto, 2 za
  /// zamek, ze świnką o 1 więcej.
  barnJoined,

  /// Właściciel stodoły na koniec gry: 4 pkt za miasto i 5 za zamek, bez świnki.
  barnOwner,
}

/// Liczy punkty za pojedynczy obiekt.
///
/// - [tiles] – liczba płytek (pola: liczba ukończonych miast; zamek: punkty
///   owce: wpisane punkty),
/// - [banners] – sztandary (tylko miasto),
/// - [castles] – zamki przy polu, każdy wart 4 zamiast 3,
/// - [farm] – sposób punktowania pola (stodoła),
/// - [vineyards] – winnice wokół ukończonego klasztoru, po 3 pkt,
/// - [completed] – czy miasto/droga/klasztor jest ukończony,
/// - [bonus] – katedra (miasto), karczma (droga) lub świnka (pola),
/// - [circusTiles] – płytki cyrku i akrobatów wokół dyrektora cyrku
///   (po 2 pkt, doliczane do dowolnej punktacji z jego udziałem),
/// - [withFairy] – wróżka stoi przy meplu w tej budowli: +3 pkt
///   niezależnie od reszty (tylko miasto, droga, klasztor i pole).
///
/// Wróżka sama w sobie ([ScoringType.fairy]) to zawsze 1 pkt.
int calculatePoints(
  ScoringType type, {
  int tiles = 0,
  int banners = 0,
  int castles = 0,
  int vineyards = 0,
  bool completed = true,
  bool bonus = false,
  FarmScoring farm = FarmScoring.normal,
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
      if (completed) {
        base = tiles * (bonus ? 2 : 1);
      } else {
        // Niedokończona droga z karczmą nie daje punktów.
        base = bonus ? 0 : tiles;
      }

    case ScoringType.cloister:
    case ScoringType.abbey:
      // Opactwo punktuje jak klasztor. Winnice punktują tylko przy
      // ukończonym klasztorze (lub opactwie).
      base = completed ? 9 + vineyards * kVineyardPoints : tiles;

    case ScoringType.meadow:
      // Zamek na polu jest wart 4 pkt zamiast 3 (ze świnką o 1 więcej,
      // tak jak miasto). Pole połączone ze stodołą: 1 i 2 pkt, a stodoła
      // na koniec gry: 4 i 5 pkt (bez świnki).
      base = switch (farm) {
        FarmScoring.normal => tiles * (bonus ? 4 : 3) + castles * (bonus ? 5 : 4),
        FarmScoring.barnJoined =>
          tiles * (bonus ? 2 : 1) + castles * (bonus ? 3 : 2),
        FarmScoring.barnOwner => tiles * 4 + castles * 5,
      };

    case ScoringType.fairy:
      return kFairyTurnPoints;

    case ScoringType.sheep:
      base = tiles;

    case ScoringType.goods:
    case ScoringType.gold:
    case ScoringType.bazaar:
    case ScoringType.circus:
    case ScoringType.pyramid:
    case ScoringType.ringmaster:
    case ScoringType.tower:
      base = 0;
  }
  final fairy = withFairy && type.isFeature ? kFairyFeaturePoints : 0;
  return base + ringmasterPoints(circusTiles) + fairy;
}
