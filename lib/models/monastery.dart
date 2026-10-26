/// Najwięcej punktów, jakie może dać klasztor liniowy: pole klasztoru plus
/// dwa pełne rzędy i kolumny po obu stronach (ograniczenie pola wpisu).
const int kMaxMonasteryPoints = 99;

/// Punkty końcowe opata w klasztorze z dodatku „Klasztory niemieckie
/// i holenderskie": 1 pkt za każdą płytkę w wierszu i kolumnie klasztoru
/// (liczone od klasztoru aż do pierwszej luki w danym kierunku) oraz 1 pkt
/// za samą płytkę klasztoru.
int monasteryLinePoints(int tilesInLines) => tilesInLines + 1;
