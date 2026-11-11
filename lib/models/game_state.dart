import 'player.dart';

/// Etap gry: przygotowanie (dodawanie graczy i dodatków), rozgrywka,
/// punktowanie końcowe (kafelki się skończyły, na planszy zostały mepelki
/// do podliczenia) i koniec.
enum GameStage { setup, playing, endScoring, finished }

/// Czy można dopisywać punkty (w trakcie gry albo w punktowaniu końcowym).
bool canScore(GameStage stage) =>
    stage == GameStage.playing || stage == GameStage.endScoring;

/// Czy trwa punktowanie końcowe: kafelki się skończyły, czas gry stoi.
bool isEndScoring(GameStage stage) => stage == GameStage.endScoring;

/// Najmniejsza liczba graczy potrzebna do rozpoczęcia gry.
const int kMinPlayers = 2;

/// Czy można rozpocząć grę przy [playerCount] graczach.
bool canStartGame(int playerCount) => playerCount >= kMinPlayers;

/// Czas gry: od rozpoczęcia do zakończenia (albo do teraz, gdy gra trwa).
Duration gameElapsed({
  required DateTime? startedAt,
  required DateTime? endedAt,
  DateTime? now,
}) {
  if (startedAt == null) return Duration.zero;
  final end = endedAt ?? now ?? DateTime.now();
  final d = end.difference(startedAt);
  return d.isNegative ? Duration.zero : d;
}

/// Etap dla starych zapisów bez zapisanego etapu: jeśli ktoś ma już punkty,
/// surowce lub złoto, gra trwa.
GameStage inferLegacyStage(Iterable<Player> players) =>
    players.any((p) => p.points != 0 || p.goodsTotal > 0 || p.gold != 0)
    ? GameStage.playing
    : GameStage.setup;

/// Dodatki, graczy i punkty można zmieniać tylko w fazie przygotowania.
bool isSetup(GameStage stage) => stage == GameStage.setup;
