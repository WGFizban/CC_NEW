import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/models/fairy.dart';
import 'package:cc_new/models/player.dart';
import 'package:cc_new/models/sharing.dart';

Player _player(String name) =>
    Player(name: name, color: const Color(0xFF000000));

void main() {
  group('Wróżka przy meplu gracza bez przewagi', () {
    test('gracz bez przewagi dostaje tylko +3 za wróżkę', () {
      final a = _player('A');
      final b = _player('B');

      // Budowla 8 pkt dla A; wróżka stoi przy B, który nie ma przewagi.
      final result = splitPoints(
        scorer: a,
        base: 8,
        fairyOwner: b,
        fairyPoints: kFairyFeaturePoints,
      );

      expect(result, {a: 8, b: 3});
    });

    test('współdzielący dostaje punkty budowli plus +3 za wróżkę', () {
      final a = _player('A');
      final b = _player('B');

      final result = splitPoints(
        scorer: a,
        base: 8,
        fairyOwner: b,
        fairyPoints: kFairyFeaturePoints,
        others: {b: const PointsShare()},
      );

      expect(result, {a: 8, b: 11});
    });

    test('wróżka przy punktującym nie zmienia podziału (extras)', () {
      final a = _player('A');
      final b = _player('B');

      final result = splitPoints(
        scorer: a,
        base: 8,
        extras: 3,
        others: {b: const PointsShare()},
      );

      expect(result, {a: 11, b: 8});
    });
  });
}
