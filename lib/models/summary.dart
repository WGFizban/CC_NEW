import 'history_entry.dart';
import 'scoring.dart';

/// Punkty każdego gracza (po nazwie) zebrane w całej grze, według rodzaju
/// punktacji. Wpisy bez rodzaju (stare zapisy) trafiają pod klucz `null`.
Map<String, Map<ScoringType?, int>> pointsByType(List<HistoryEntry> log) {
  final result = <String, Map<ScoringType?, int>>{};
  for (final e in log) {
    final type = e.scoringType;
    for (final c in e.changes) {
      if (c.points == 0) continue;
      final row = result.putIfAbsent(c.player, () => {});
      row[type] = (row[type] ?? 0) + c.points;
    }
  }
  return result;
}
