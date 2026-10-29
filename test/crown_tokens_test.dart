import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cc_new/models/crown_tokens.dart';
import 'package:cc_new/models/player.dart';
import 'package:cc_new/models/score_event.dart';
import 'package:cc_new/services/settings_storage.dart';

Player _p(String name) => Player(name: name, color: const Color(0xFF1D27EA));

void main() {
  group('wielkość budowli przy przejęciu żetonu', () {
    test('bez właściciela wystarczy 1 płytka', () {
      expect(minTokenSize(null), 1);
    });

    test('nowa wartość musi być większa od zapamiętanej', () {
      final ala = _p('Ala');
      expect(minTokenSize(TokenHolding(ala.id, 7)), 8);
    });
  });

  group('punkty końcowe za żetony', () {
    test('Król i Baron rabusiów dostają po 1 pkt za płytkę', () {
      final ala = _p('Ala');
      final bob = _p('Bob');

      final result = crownEndPoints(
        tokens: {
          CrownToken.king: TokenHolding(ala.id, 8),
          CrownToken.robber: TokenHolding(bob.id, 6),
        },
        players: [ala, bob],
        cityTiles: 21,
        roadTiles: 14,
      );

      expect(result, {ala: 21, bob: 14});
    });

    test('gracz z obydwoma żetonami dostaje obie sumy', () {
      final ala = _p('Ala');

      final result = crownEndPoints(
        tokens: {
          CrownToken.king: TokenHolding(ala.id, 8),
          CrownToken.robber: TokenHolding(ala.id, 6),
        },
        players: [ala, _p('Bob')],
        cityTiles: 10,
        roadTiles: 5,
      );

      expect(result, {ala: 15});
    });

    test('nieprzejęty żeton i zerowe płytki nic nie dają', () {
      final ala = _p('Ala');

      expect(
        crownEndPoints(
          tokens: {CrownToken.king: TokenHolding(ala.id, 8)},
          players: [ala],
          cityTiles: 0,
          roadTiles: 12,
        ),
        isEmpty,
      );
    });
  });

  group('zapis stanu żetonów', () {
    test('holding przeżywa JSON, a zepsuty wpis jest pomijany', () {
      final h = TokenHolding.fromJson(const TokenHolding('x', 5).toJson());
      expect(h?.playerId, 'x');
      expect(h?.size, 5);
      expect(TokenHolding.fromJson({'playerId': 1, 'size': 'a'}), isNull);
      expect(TokenHolding.fromJson(null), isNull);
    });

    test('ustawienia zapisują i wczytują właścicieli żetonów', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = SettingsStorage();
      final settings = GameSettings(
        tokens: {
          CrownToken.king: const TokenHolding('a', 9),
          CrownToken.robber: const TokenHolding('b', 4),
        },
      );

      await storage.save(settings);
      final loaded = await storage.load();

      expect(loaded.tokens[CrownToken.king]?.playerId, 'a');
      expect(loaded.tokens[CrownToken.king]?.size, 9);
      expect(loaded.tokens[CrownToken.robber]?.size, 4);
    });
  });

  test('zdarzenie przenosi zmianę żetonu (do cofnięcia)', () {
    final ala = _p('Ala');
    final change = TokenChange(
      CrownToken.king,
      null,
      TokenHolding(ala.id, 6),
    );

    final event = ScoreEvent('Miasto', [ScoreChange(ala, 12)], token: change);

    expect(event.token?.before, isNull);
    expect(event.token?.after.size, 6);
  });
}
