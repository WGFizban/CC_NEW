/// Żetony stada z dodatku „Wzgórza i owce": wartość żetonu (liczba owiec)
/// → ile takich żetonów jest w woreczku. Do tego dochodzą 2 wilki,
/// które nie dają punktów.
const Map<int, int> kSheepTokens = {1: 4, 2: 5, 3: 5, 4: 2};

/// Największa liczba owiec możliwa do zdobycia (suma wartości wszystkich
/// żetonów owiec: 4·1 + 5·2 + 5·3 + 2·4).
const int kMaxSheep = 37;

/// Punkty za każdą winnicę wokół ukończonego klasztoru („Wzgórza i owce").
const int kVineyardPoints = 3;

/// Winnic może być najwyżej tyle, ile płytek wokół klasztoru.
const int kMaxVineyards = 8;

/// Liczba żetonów owiec w grze.
const int kSheepTokenCount = 16;

/// Punkty za stado złożone z żetonów: [counts] to wartość żetonu → liczba
/// sztuk. Liczby spoza zakresu 0..limit są obcinane do limitu z gry.
int flockPoints(Map<int, int> counts) {
  var sum = 0;
  kSheepTokens.forEach((value, limit) {
    var count = counts[value] ?? 0;
    if (count < 0) count = 0;
    if (count > limit) count = limit;
    sum += value * count;
  });
  return sum;
}
