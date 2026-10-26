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
