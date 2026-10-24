import 'player.dart';

/// Gra się zaczęła, gdy ruszył licznik czasu albo ktokolwiek ma już punkty,
/// surowce lub złoto. Do końca gry nie można wtedy zmieniać dodatków.
bool isGameStarted({
  required bool timerRunning,
  required Duration elapsed,
  required Iterable<Player> players,
}) =>
    timerRunning ||
    elapsed > Duration.zero ||
    players.any((p) => p.points != 0 || p.goodsTotal > 0 || p.gold != 0);
