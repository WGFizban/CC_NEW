import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/models/scoring.dart';

void main() {
  group('miasto', () {
    test('ukończone: 2 pkt za płytkę i sztandar', () {
      expect(calculatePoints(ScoringType.city, tiles: 4, banners: 1), 10);
    });

    test('ukończone z katedrą: 3 pkt za płytkę i sztandar', () {
      expect(
        calculatePoints(ScoringType.city, tiles: 4, banners: 1, bonus: true),
        15,
      );
    });

    test('nieukończone: 1 pkt za płytkę i sztandar', () {
      expect(
        calculatePoints(
          ScoringType.city,
          tiles: 4,
          banners: 1,
          completed: false,
        ),
        5,
      );
    });

    test('nieukończone z katedrą: 0 pkt', () {
      expect(
        calculatePoints(
          ScoringType.city,
          tiles: 4,
          banners: 1,
          completed: false,
          bonus: true,
        ),
        0,
      );
    });
  });

  group('droga', () {
    test('1 pkt za płytkę', () {
      expect(calculatePoints(ScoringType.road, tiles: 5), 5);
    });

    test('ukończona z karczmą: 2 pkt za płytkę', () {
      expect(calculatePoints(ScoringType.road, tiles: 5, bonus: true), 10);
    });

    test('nieukończona z karczmą: 0 pkt', () {
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 5,
          completed: false,
          bonus: true,
        ),
        0,
      );
    });
  });

  group('klasztor', () {
    test('ukończony: 9 pkt', () {
      expect(calculatePoints(ScoringType.cloister, tiles: 0), 9);
    });

    test('nieukończony: liczba płytek', () {
      expect(
        calculatePoints(ScoringType.cloister, tiles: 6, completed: false),
        6,
      );
    });
  });

  group('pola', () {
    test('3 pkt za miasto', () {
      expect(calculatePoints(ScoringType.meadow, tiles: 3), 9);
    });

    test('ze świnką 4 pkt za miasto', () {
      expect(calculatePoints(ScoringType.meadow, tiles: 3, bonus: true), 12);
    });
  });

  test('wróżka i owce zwracają wpisaną liczbę punktów', () {
    expect(calculatePoints(ScoringType.fairy, tiles: 3), 3);
    expect(calculatePoints(ScoringType.sheep, tiles: 7), 7);
  });
}
