/// Dodatki do gry obsługiwane przez aplikację, w kolejności numeracji
/// z instrukcji (mini dodatki na końcu). Nazwy i opisy są w plikach `.arb`
/// (zob. `l10n/labels.dart`).
enum Expansion {
  innsCathedrals(1),
  tradersBuilders(2),
  princessDragon(3),
  tower(4),
  abbeyMayor(5),
  bridgesCastlesBazaars(8),
  hillsSheep(9),
  circus(10),
  goldMines(4, mini: true);

  const Expansion(this.number, {this.mini = false});

  /// Numer z instrukcji (osobna numeracja dla mini dodatków).
  final int number;

  /// Czy to mini dodatek.
  final bool mini;
}
