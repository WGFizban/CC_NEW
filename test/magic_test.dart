import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/models/expansion.dart';
import 'package:cc_new/models/german.dart';
import 'package:cc_new/models/history_entry.dart';
import 'package:cc_new/models/magic.dart';
import 'package:cc_new/models/player.dart';
import 'package:cc_new/models/score_event.dart';
import 'package:cc_new/models/scoring.dart';
import 'package:cc_new/models/summary.dart';

void main() {
  _summaryTests();
  _cathedralTests();
  group('Mag i wiedźma – dodatek', () {
    test('mag i maszyny latające to mini dodatki', () {
      expect(Expansion.mageWitch.mini, isTrue);
      expect(Expansion.flyingMachines.mini, isTrue);
    });

    test('applyMagic bez pionka nic nie zmienia', () {
      expect(applyMagic(null, base: 7, tiles: 4), 7);
    });
  });

  group('Mag', () {
    test('ukończona droga 3 płytek: 3 + 3 = 6 (przykład z instrukcji)', () {
      expect(
        calculatePoints(ScoringType.road, tiles: 3, magic: MagicPawn.mage),
        6,
      );
    });

    test('miasto 8 płytek i 2 sztandary: 20 + 8 = 28 (sztandary bez bonusu)', () {
      expect(
        calculatePoints(
          ScoringType.city,
          tiles: 8,
          banners: 2,
          magic: MagicPawn.mage,
        ),
        28,
      );
    });

    test('nieukończona droga z karczmą: 0 + płytki', () {
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 4,
          completed: false,
          bonus: true,
          magic: MagicPawn.mage,
        ),
        4,
      );
    });

    test('nieukończone miasto z katedrą: 0 + płytki', () {
      expect(
        calculatePoints(
          ScoringType.city,
          tiles: 3,
          banners: 1,
          completed: false,
          bonus: true,
          magic: MagicPawn.mage,
        ),
        3,
      );
    });

    test('karczma nie zmienia premii maga: ukończona droga 4 płytek', () {
      // 4 * 2 (karczma) + 4 (mag)
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 4,
          bonus: true,
          magic: MagicPawn.mage,
        ),
        12,
      );
    });

    test('nie dotyczy klasztoru ani pola', () {
      expect(
        calculatePoints(ScoringType.cloister, magic: MagicPawn.mage),
        9,
      );
      expect(
        calculatePoints(ScoringType.meadow, tiles: 2, magic: MagicPawn.mage),
        6,
      );
    });
  });

  group('Wiedźma', () {
    test('droga 5 płytek: 3 pkt (połowa w górę, przykład z instrukcji)', () {
      expect(
        calculatePoints(ScoringType.road, tiles: 5, magic: MagicPawn.witch),
        3,
      );
    });

    test('liczy się po karczmie: 4 płytki z karczmą 8 -> 4', () {
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 4,
          bonus: true,
          magic: MagicPawn.witch,
        ),
        4,
      );
    });

    test('liczy się po katedrze niemieckiej: 4 płytki 8 -> 4', () {
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 4,
          cathedralRoad: true,
          magic: MagicPawn.witch,
        ),
        4,
      );
    });

    test('miasto z katedrą: 3 płytki i sztandar 4 * 3 = 12 -> 6', () {
      expect(
        calculatePoints(
          ScoringType.city,
          tiles: 3,
          banners: 1,
          bonus: true,
          magic: MagicPawn.witch,
        ),
        6,
      );
    });

    test('nie dzieli premii za zamki niemieckie, wróżki ani cyrku', () {
      // droga 5 płytek: 5 -> 3, +2 zamki * 3, +3 wróżka, +2 płytki cyrku * 2
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 5,
          germanCastles: 2,
          withFairy: true,
          circusTiles: 2,
          magic: MagicPawn.witch,
        ),
        3 + 6 + 3 + 4,
      );
    });

    test('nieukończona droga z karczmą nadal daje 0', () {
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 4,
          completed: false,
          bonus: true,
          magic: MagicPawn.witch,
        ),
        0,
      );
    });
  });
}

void _summaryTests() {
  group('Kolumna „Magia” w podsumowaniu', () {
    final a = Player(name: 'A', color: const Color(0xFF000000));
    final b = Player(name: 'B', color: const Color(0xFF000000));

    test('punkty od maga i wiedźmy idą do osobnej kolumny', () {
      // Droga 3 płytek z magiem: 6 pkt, z czego 3 od maga.
      final mage = HistoryEntry.fromEvent(
        ScoreEvent(
          'Droga',
          [ScoreChange(a, 6, magic: 3)],
          type: ScoringType.road,
        ),
      );
      // Droga 5 płytek z wiedźmą: 3 pkt, czyli −2 od wiedźmy.
      final witch = HistoryEntry.fromEvent(
        ScoreEvent(
          'Droga',
          [ScoreChange(b, 3, magic: -2)],
          type: ScoringType.road,
        ),
      );

      final byType = pointsByType([mage, witch], [a, b]);

      expect(byType[a.id], {ScoringType.road: 3, ScoringType.magic: 3});
      expect(byType[b.id], {ScoringType.road: 5, ScoringType.magic: -2});
    });

    test('magia przechodzi przez zapis historii', () {
      final entry = HistoryEntry.fromEvent(
        ScoreEvent('Droga', [ScoreChange(a, 6, magic: 3)]),
      );
      final copy = HistoryEntry.fromJson(entry.toJson());

      expect(copy.changes.single.magic, 3);
    });

    test('kolumna jest tylko przy włączonym dodatku i nie do wyboru', () {
      expect(
        ScoringType.availableFor({Expansion.mageWitch}),
        contains(ScoringType.magic),
      );
      expect(ScoringType.availableFor({}), isNot(contains(ScoringType.magic)));
      expect(
        ScoringType.selectableFor({Expansion.mageWitch}),
        isNot(contains(ScoringType.magic)),
      );
    });
  });
}

void _cathedralTests() {
  group('Mag i wiedźma przy katedrze niemieckiej', () {
    test('mag liczy płytki, nie odcinki (przykład z wikicarpedii: 14 pkt)', () {
      // Droga z 4 płytek wraca do katedry: 5 odcinków * 2 + 4 płytki maga.
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 5,
          cathedralRoad: true,
          magic: MagicPawn.mage,
          magicTiles: 4,
        ),
        14,
      );
    });

    test('wiedźma zmniejsza o połowę tylko swoją drogę arcybiskupa', () {
      final roads = [
        const CathedralRoad(tiles: 5, magic: MagicPawn.witch), // 5 -> 3
        const CathedralRoad(tiles: 4), // 4
        const CathedralRoad(tiles: 3, inn: true), // 6
      ];
      expect(archbishopPoints(roads), 3 + 4 + 6);
    });

    test('mag nie daje arcybiskupowi punktów', () {
      final roads = [
        const CathedralRoad(tiles: 5, magic: MagicPawn.mage),
        const CathedralRoad(tiles: 4, magic: MagicPawn.witch), // 4 -> 2
      ];
      expect(archbishopPoints(roads), 5 + 2);
    });

    test('nieukończona droga z karczmą nadal 0, także z wiedźmą', () {
      expect(
        archbishopPoints([
          const CathedralRoad(
            tiles: 4,
            inn: true,
            completed: false,
            magic: MagicPawn.witch,
          ),
        ]),
        0,
      );
    });
  });
}
