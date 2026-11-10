import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/models/expansion.dart';
import 'package:cc_new/models/magic.dart';
import 'package:cc_new/models/scoring.dart';

void main() {
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
