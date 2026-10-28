import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/models/history_entry.dart';
import 'package:cc_new/models/player.dart';
import 'package:cc_new/models/score_event.dart';
import 'package:cc_new/models/scoring.dart';
import 'package:cc_new/models/sharing.dart';
import 'package:cc_new/models/summary.dart';

HistoryEntry _entry(Player p, int points, {ScoringType? type}) =>
    HistoryEntry.fromEvent(
      ScoreEvent('x', [ScoreChange(p, points)], type: type),
    );

void main() {
  test('każdy gracz dostaje inne id, które przeżywa zapis JSON', () {
    final a = Player(name: 'Ja', color: const Color(0xFF1D27EA));
    final b = Player(name: 'Ja', color: const Color(0xFFEA1D27));

    expect(a.id, isNot(b.id));
    expect(Player.fromJson(a.toJson()).id, a.id);
  });

  test('stary zapis gracza bez id dostaje id przy wczytaniu', () {
    final p = Player.fromJson({'name': 'Ola', 'color': 0xFF078E04});

    expect(p.id, isNotEmpty);
  });

  test('podsumowanie rozróżnia graczy o tym samym imieniu', () {
    final a = Player(name: 'Ja', color: const Color(0xFF1D27EA));
    final b = Player(name: 'Ja', color: const Color(0xFFEA1D27));
    final log = [
      _entry(a, 10, type: ScoringType.city),
      _entry(b, 4, type: ScoringType.city),
      _entry(b, 6, type: ScoringType.road),
    ];

    final byType = pointsByType(log, [a, b]);

    expect(byType[a.id], {ScoringType.city: 10});
    expect(byType[b.id], {ScoringType.city: 4, ScoringType.road: 6});
  });

  test('zmiana imienia i koloru nie gubi wcześniejszych punktów', () {
    final a = Player(name: 'Ala', color: const Color(0xFF1D27EA));
    final log = [_entry(a, 5, type: ScoringType.city)];

    a
      ..name = 'Alicja'
      ..color = const Color(0xFFEA1D27);
    log.add(_entry(a, 3, type: ScoringType.city));

    expect(pointsByType(log, [a])[a.id], {ScoringType.city: 8});
  });

  test('id gracza przeżywa zapis historii w JSON', () {
    final a = Player(name: 'Ja', color: const Color(0xFF1D27EA));
    final restored = HistoryEntry.fromJson(_entry(a, 7).toJson());

    expect(restored.changes.single.playerId, a.id);
    expect(restored.changes.single.belongsTo(a), isTrue);
  });

  group('dwóch graczy o imieniu „Ja” w różnych kolorach', () {
    final a = Player(name: 'Ja', color: const Color(0xFF1D27EA));
    final b = Player(name: 'Ja', color: const Color(0xFFEA1D27));

    test('współdzielenie przypisuje punkty właściwemu graczowi', () {
      // A punktuje, B (też „Ja”) jest zaznaczony jako współdzielący.
      final result = splitPoints(
        scorer: a,
        base: 10,
        others: {b: const PointsShare()},
      );

      expect(result[a], 10);
      expect(result[b], 10);
      expect(result.length, 2);
    });

    test('zamek drugiego „Ja” liczy się tylko jemu', () {
      final result = splitPoints(
        scorer: a,
        base: 10,
        others: {
          b: const PointsShare(castle: true, castles: 2, alsoShares: true),
        },
      );

      expect(result, {a: 10, b: 30});
    });

    test('zatwierdzenie i cofnięcie zmienia wynik tylko wskazanego gracza', () {
      final event = ScoreEvent('x', [ScoreChange(b, 7)]);

      event.apply();
      expect(a.points, 0);
      expect(b.points, 7);

      event.revert();
      expect(b.points, 0);
    });

    test('wpisy historii należą tylko do swojego gracza', () {
      final entry = _entry(b, 5);

      expect(entry.changes.single.belongsTo(b), isTrue);
      expect(entry.changes.single.belongsTo(a), isFalse);
    });
  });

  group('migracja starych wpisów bez id', () {
    HistoryEntry legacy(String name, int color, int points) => HistoryEntry(
      id: 1,
      time: DateTime(2026),
      label: 'x',
      changes: [HistoryChange(player: name, points: points, color: color)],
    );

    test('wpis dostaje id gracza o tym samym imieniu i kolorze', () {
      final a = Player(name: 'Ja', color: const Color(0xFF1D27EA));
      final b = Player(name: 'Ja', color: const Color(0xFFEA1D27));

      final migrated = legacy('Ja', 0xFFEA1D27, 5).withPlayerIds([a, b]);

      expect(migrated.changes.single.playerId, b.id);
    });

    test('niejednoznaczny wpis (bez koloru, dwóch graczy) zostaje bez id', () {
      final a = Player(name: 'Ja', color: const Color(0xFF1D27EA));
      final b = Player(name: 'Ja', color: const Color(0xFFEA1D27));
      final old = HistoryEntry(
        id: 1,
        time: DateTime(2026),
        label: 'x',
        changes: [const HistoryChange(player: 'Ja', points: 5)],
      );

      final migrated = old.withPlayerIds([a, b]);

      expect(migrated.changes.single.playerId, isNull);
      expect(pointsByType([migrated], [a, b]), isEmpty);
    });

    test('pointsByType przypisuje stary wpis po imieniu i kolorze', () {
      final a = Player(name: 'Ala', color: const Color(0xFF1D27EA));

      final byType = pointsByType([legacy('Ala', 0xFF1D27EA, 9)], [a]);

      expect(byType[a.id], {null: 9});
    });
  });
}
