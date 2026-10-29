import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cc_new/models/crown_tokens.dart';
import 'package:cc_new/models/expansion.dart';
import 'package:cc_new/models/player.dart';
import 'package:cc_new/models/scoring.dart';
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
    test('Król i Baron rabusiów dostają po 1 pkt za ukończony zamek i drogę', () {
      final ala = _p('Ala');
      final bob = _p('Bob');

      final result = crownEndPoints(
        tokens: {
          CrownToken.king: TokenHolding(ala.id, 8),
          CrownToken.robber: TokenHolding(bob.id, 6),
        },
        players: [ala, bob],
        cities: 6,
        roads: 4,
      );

      expect(result, {ala: 6, bob: 4});
    });

    test('gracz z obydwoma żetonami dostaje obie sumy', () {
      final ala = _p('Ala');

      final result = crownEndPoints(
        tokens: {
          CrownToken.king: TokenHolding(ala.id, 8),
          CrownToken.robber: TokenHolding(ala.id, 6),
        },
        players: [ala, _p('Bob')],
        cities: 3,
        roads: 2,
      );

      expect(result, {ala: 5});
    });

    test('nieprzejęty żeton i zero zamków nic nie daje', () {
      final ala = _p('Ala');

      expect(
        crownEndPoints(
          tokens: {CrownToken.king: TokenHolding(ala.id, 8)},
          players: [ala],
          cities: 0,
          roads: 12,
        ),
        isEmpty,
      );
    });
  });

  group('typy punktacji króla i rabusia', () {
    test('kafelek jest do wyboru, kolumny podsumowania nie', () {
      final all = ScoringType.selectableFor({Expansion.kingRobber});
      expect(all, contains(ScoringType.crown));
      expect(all, isNot(contains(ScoringType.king)));
      expect(all, isNot(contains(ScoringType.robber)));
      expect(
        ScoringType.availableFor({Expansion.kingRobber}),
        containsAll([ScoringType.king, ScoringType.robber]),
      );
      expect(ScoringType.selectableFor({}), isNot(contains(ScoringType.crown)));
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
