import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import 'goods.dart';
import 'player.dart';
import 'score_event.dart';

/// Zmiana wyniku jednego gracza w historii.
class HistoryChange {
  final String player;
  final int points;

  /// Surowce według kluczy (nazwa wartości [Goods], np. „wine"). Starsze
  /// wpisy mają tu zapisane polskie nazwy (np. „Wino"), które pokazujemy
  /// bez zmian.
  final Map<String, int> goods;

  /// Sztabki złota.
  final int gold;

  /// Kolor gracza (ARGB) w chwili zdarzenia; `null` w starszych wpisach.
  final int? color;

  /// Wynik gracza łącznie (z premiami) po tym zdarzeniu; `null` w starszych
  /// wpisach.
  final int? total;

  const HistoryChange({
    required this.player,
    required this.points,
    this.goods = const {},
    this.gold = 0,
    this.color,
    this.total,
  });

  /// Surowce i złoto jako tekst w aktualnym języku, np. „Wino ×1, Złoto ×3".
  String goodsText(AppLocalizations l) => [
    for (final e in goods.entries)
      '${_goodsName(e.key, l)} ×${e.value}',
    if (gold != 0) l.goldTimes(gold),
  ].join(', ');

  static String _goodsName(String key, AppLocalizations l) {
    for (final g in Goods.values) {
      if (g.name == key) return g.title(l);
    }
    return key;
  }

  Map<String, dynamic> toJson() => {
    'player': player,
    'points': points,
    'goods': goods,
    'gold': gold,
    'color': color,
    'total': total,
  };

  factory HistoryChange.fromJson(Map<String, dynamic> json) => HistoryChange(
    player: json['player'] as String,
    points: (json['points'] as int?) ?? 0,
    gold: (json['gold'] as int?) ?? 0,
    color: json['color'] as int?,
    total: json['total'] as int?,
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

  /// [totals] to wyniki łączne graczy po zdarzeniu (z premiami).
  factory HistoryEntry.fromEvent(
    ScoreEvent event, {
    DateTime? now,
    Map<Player, int>? totals,
  }) {
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
            goods: {for (final g in c.goods.entries) g.key.name: g.value},
            gold: c.gold,
            color: c.player.color.toARGB32(),
            total: totals?[c.player],
          ),
      ],
    );
  }

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
