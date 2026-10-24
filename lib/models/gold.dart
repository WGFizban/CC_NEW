/// Sztabki złota z minidodatku „Kopalnie złota".
library;

/// Liczba sztabek złota w grze.
const int kGoldSupply = 16;

/// Ile punktów jest warta każda sztabka przy [count] sztabkach:
/// 1–3 sztabki po 1 pkt, 4–6 po 2, 7–9 po 3, od 10 po 4.
int goldValuePerPiece(int count) {
  if (count >= 10) return 4;
  if (count >= 7) return 3;
  if (count >= 4) return 2;
  if (count >= 1) return 1;
  return 0;
}

/// Punkty za wszystkie [count] sztabek na koniec gry.
int goldPoints(int count) => count * goldValuePerPiece(count);
