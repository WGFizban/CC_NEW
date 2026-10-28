import 'history_entry.dart';
import 'player.dart';
import 'scoring.dart';

/// Punkty każdego gracza (po [Player.id]) zebrane w całej grze, według
/// rodzaju punktacji. Wpisy bez rodzaju (stare zapisy) trafiają pod klucz
/// `null`. Zmiany ze starych zapisów, które nie mają id, są przypisywane do
/// gracza o tym samym imieniu i kolorze; gdy pasuje kilku, są pomijane
/// (nie da się ich rozróżnić).
Map<String, Map<ScoringType?, int>> pointsByType(
  List<HistoryEntry> log,
  List<Player> players,
) {
  final result = <String, Map<ScoringType?, int>>{};
  for (final e in log) {
    final type = e.scoringType;
    for (final c in e.changes) {
      if (c.points == 0) continue;
      final id = c.playerId ?? _legacyId(c, players);
      if (id == null) continue;
      final row = result.putIfAbsent(id, () => {});
      row[type] = (row[type] ?? 0) + c.points;
    }
  }
  return result;
}

String? _legacyId(HistoryChange c, List<Player> players) {
  final matches = players.where(c.belongsTo).toList();
  return matches.length == 1 ? matches.first.id : null;
}
