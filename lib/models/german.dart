import 'magic.dart';

/// Premia za każdy niemiecki zamek na końcu ukończonej drogi lub miasta
/// (dodatek „Zamki w Niemczech"). Liczona po modyfikacjach z karczmy
/// i katedry.
const int kGermanCastleBonus = 3;

/// Zamek niemiecki ukończony (otoczony ze wszystkich stron jak klasztor).
const int kGermanCastleCompleted = 12;

/// Nieukończony zamek na koniec gry: sama płytka zamku jest warta tyle,
/// a każda otaczająca płytka dodatkowo 1 pkt.
const int kGermanCastleTileBase = 2;

/// Największa liczba płytek wokół zamku (zamek ma dwie płytki, więc obok niego
/// jest ich 10, ale ukończony jest dopiero przy pełnym otoczeniu).
const int kMaxGermanCastleSurround = 9;

/// Największa liczba dróg wychodzących z płytki niemieckiej katedry.
const int kMaxCathedralRoads = 4;

/// Jedna droga wychodząca z niemieckiej katedry (punktuje ją arcybiskup).
class CathedralRoad {
  const CathedralRoad({
    this.tiles = 0,
    this.inn = false,
    this.completed = true,
    this.magic,
  });

  /// Odcinki drogi (razem z odcinkiem na płytce katedry).
  final int tiles;

  /// Droga ma karczmę.
  final bool inn;

  /// Droga jest zamknięta; otwarta liczy się tylko na koniec gry.
  final bool completed;

  /// Pionek magiczny na tej drodze. Wiedźma zmniejsza o połowę (w górę)
  /// punkty arcybiskupa z tej drogi, mag nie daje mu nic (zasady).
  final MagicPawn? magic;
}

/// Punkty arcybiskupa: każda droga osobno, wyniki się sumują.
///
/// Ukończona: 1 pkt za odcinek (2 z karczmą). Premia za niemieckie zamki nie
/// dotyczy arcybiskupa (zasady podają ją tylko dla dróg i miast).
/// Nieukończona (koniec gry): 1 pkt za odcinek, a z karczmą 0 (zasady
/// C1/C2/C3).
int archbishopPoints(Iterable<CathedralRoad> roads) {
  var sum = 0;
  for (final r in roads) {
    final int points;
    if (r.completed) {
      points = r.tiles * (r.inn ? 2 : 1);
    } else {
      points = r.inn ? 0 : r.tiles;
    }
    sum += r.magic == MagicPawn.witch ? (points + 1) ~/ 2 : points;
  }
  return sum;
}
