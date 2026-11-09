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
    this.castles = 0,
  });

  /// Odcinki drogi (razem z odcinkiem na płytce katedry).
  final int tiles;

  /// Droga ma karczmę.
  final bool inn;

  /// Droga jest zamknięta; otwarta liczy się tylko na koniec gry.
  final bool completed;

  /// Niemieckie zamki na drugim końcu ukończonej drogi (+3 za każdy).
  final int castles;
}

/// Punkty arcybiskupa: każda droga osobno, wyniki się sumują.
///
/// Ukończona: 1 pkt za odcinek (2 z karczmą) plus premia za niemieckie zamki.
/// Nieukończona (koniec gry): 1 pkt za odcinek, a z karczmą 0 (zasady
/// C1/C2/C3).
int archbishopPoints(Iterable<CathedralRoad> roads) {
  var sum = 0;
  for (final r in roads) {
    if (r.completed) {
      sum += r.tiles * (r.inn ? 2 : 1) + r.castles * kGermanCastleBonus;
    } else {
      sum += r.inn ? 0 : r.tiles;
    }
  }
  return sum;
}
