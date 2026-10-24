import 'score_event.dart';

/// Wpis w trwałej historii punktów: co i kiedy zostało zatwierdzone.
class HistoryEntry {
  /// Unikalny numer wpisu (czas zatwierdzenia w mikrosekundach).
  final int id;
  final DateTime time;
  final String label;

  /// Zmiany po graczach, np. „Ala: +12 pkt, Wino ×1".
  final List<String> lines;

  const HistoryEntry({
    required this.id,
    required this.time,
    required this.label,
    this.lines = const [],
  });

  factory HistoryEntry.fromEvent(ScoreEvent event, {DateTime? now}) {
    final time = now ?? DateTime.now();
    return HistoryEntry(
      id: time.microsecondsSinceEpoch,
      time: time,
      label: event.label,
      lines: [
        for (final c in event.changes)
          '${c.player.name}: ${[
            if (c.points != 0) '${c.points > 0 ? '+' : ''}${c.points} pkt',
            for (final g in c.goods.entries) '${g.key.displayName} ×${g.value}',
          ].join(', ')}',
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time.millisecondsSinceEpoch,
    'label': label,
    'lines': lines,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: json['id'] as int,
    time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
    label: json['label'] as String,
    lines: [for (final l in (json['lines'] as List? ?? const [])) l as String],
  );
}
