import '../l10n/tr.dart';

/// Punkty za akrobatę (przy podliczeniu piramidy i na koniec gry).
const int kAcrobatPoints = 5;

/// Liczba mepli tworzących ukończoną piramidę akrobatów.
const int kPyramidSize = 3;

/// Punkty dyrektora cyrku za każdą płytkę cyrku lub akrobatów obok niego.
const int kRingmasterPointsPerTile = 2;

/// Płytek cyrku i akrobatów, które dyrektor cyrku może mieć pod sobą i wokół
/// siebie: obszar 3×3 to najwyżej 9 płytek.
const int kMaxRingmasterTiles = 9;

/// Żetony zwierząt z dodatku „Cyrk objazdowy" (polska edycja).
///
/// [value] to punkty za każdego mepla na płytce cyrku i ośmiu sąsiednich,
/// [count] to liczba takich żetonów w grze (razem 16).
enum CircusAnimal {
  elephant('Słoń', 'Elephant', 7, 1),
  lion('Lew', 'Lion', 6, 2),
  bear('Niedźwiedź', 'Bear', 5, 3),
  seal('Foka', 'Seal', 4, 5),
  monkey('Małpka', 'Monkey', 3, 4),
  flea('Pchła', 'Flea', 1, 1);

  const CircusAnimal(this._pl, this._en, this.value, this.count);

  final String _pl;
  final String _en;

  /// Nazwa zwierzęcia w aktualnym języku.
  String get displayName => tr(_pl, _en);
  final int value;
  final int count;
}

/// Punkty za punktowanie cyrku: każdy mepel (także dyrektor cyrku)
/// na płytce cyrku i ośmiu sąsiednich daje wartość odkrytego zwierzęcia.
int circusPoints(CircusAnimal animal, int meeples) => animal.value * meeples;

/// Punkty za akrobatów gracza (5 za każdego).
int acrobatPoints(int acrobats) => acrobats * kAcrobatPoints;

/// Punkty dyrektora cyrku za płytki cyrku i akrobatów wokół niego.
int ringmasterPoints(int tiles) => tiles * kRingmasterPointsPerTile;
