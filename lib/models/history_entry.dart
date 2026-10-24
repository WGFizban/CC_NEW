import 'score_event.dart';

/// Zmiana wyniku jednego gracza w historii.
class HistoryChange {
  final String player;
  final int points;

  /// Surowce według nazw (np. „Wino": 1).
  final Map<String, int> goods;

  const HistoryChange({
    required this.player,
    required this.points,
    this.goods = const {},
  });

  /// Surowce jako tekst, np. „Wino ×1, Sukno ×2".
  String get goodsText =>
      goods.entries.map((e) => '${e.key} ×${e.value}').join(', ');

  Map<String, dynamic> toJson() => {
    'player': player,
    'points': points,
    'goods': goods,
  };

  factory HistoryChange.fromJson(Map<String, dynamic> json) => HistoryChange(
    player: json['player'] as String,
    points: (json['points'] as int?) ?? 0,
    goods: {
      for (final e in ((json['goods'] as Map?) ?? const {}).entries)
        e.key as String: e.value as int,
    },
  );
}

/// Wpis w trwałej historii punktów: co i kiedy zostało zatwierdzone.
class HistoryEntry {
  /// Unikalny numer wpisu (czas zatwierdzenia w mikrosekundach).
  final int id;
  final DateTime time;
  final String label;

  /// Rodzaj punktacji (np. „Miasto") albo `null` dla starszych wpisów.
  final String? category;
  final List<HistoryChange> changes;

  const HistoryEntry({
    required this.id,
    required this.time,
    required this.label,
    this.category,
    this.changes = const [],
  });

  factory HistoryEntry.fromEvent(ScoreEvent event, {DateTime? now}) {
    final time = now ?? DateTime.now();
    return HistoryEntry(
      id: time.microsecondsSinceEpoch,
      time: time,
      label: event.label,
      category: event.category,
      changes: [
        for (final c in event.changes)
          HistoryChange(
            player: c.player.name,
            points: c.points,
            goods: {for (final g in c.goods.entries) g.key.displayName: g.value},
          ),
      ],
    );
  }

  /// Opis zmian po graczach, np. „Ala: +12 pkt, Wino ×1".
  List<String> get lines => [
    for (final c in changes)
      '${c.player}: ${[
        if (c.points != 0) '${c.points > 0 ? '+' : ''}${c.points} pkt',
        if (c.goods.isNotEmpty) c.goodsText,
      ].join(', ')}',
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time.millisecondsSinceEpoch,
    'label': label,
    'category': category,
    'changes': [for (final c in changes) c.toJson()],
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: json['id'] as int,
    time: DateTime.fromMillisecondsSinceEpoch(json['time'] as int),
    label: json['label'] as String,
    category: json['category'] as String?,
    changes: [
      for (final c in (json['changes'] as List? ?? const []))
        HistoryChange.fromJson(c as Map<String, dynamic>),
    ],
  );
}
