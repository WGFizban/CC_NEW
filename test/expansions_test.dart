import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cc_new/models/circus.dart';
import 'package:cc_new/models/expansion.dart';
import 'package:cc_new/models/fairy.dart';
import 'package:cc_new/models/goods.dart';
import 'package:cc_new/models/history_entry.dart';
import 'package:cc_new/models/player.dart';
import 'package:cc_new/models/score_event.dart';
import 'package:cc_new/models/sharing.dart';
import 'package:cc_new/models/scoring.dart';
import 'package:cc_new/models/sheep.dart';
import 'package:cc_new/models/standings.dart';
import 'package:cc_new/services/history_storage.dart';
import 'package:cc_new/services/settings_storage.dart';

Player _player(String name, {int points = 0, Map<Goods, int>? goods}) =>
    Player(name: name, color: const Color(0xFF000000), points: points, goods: goods);

void main() {
  group('mosty, zamki, dyrektor cyrku w punktacji', () {
    test('most liczy się jak płytka drogi', () {
      expect(
        calculatePoints(ScoringType.road, tiles: 4, bridges: 2),
        6,
      );
      expect(
        calculatePoints(ScoringType.road, tiles: 4, bridges: 2, bonus: true),
        12,
      );
    });

    test('nieukończona droga z karczmą nadal daje 0 pkt', () {
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 4,
          bridges: 2,
          completed: false,
          bonus: true,
        ),
        0,
      );
    });

    test('zamek na polu jest wart 4 zamiast 3', () {
      expect(
        calculatePoints(ScoringType.meadow, tiles: 2, castles: 1),
        10,
      );
      expect(
        calculatePoints(
          ScoringType.meadow,
          tiles: 2,
          castles: 1,
          bonus: true,
        ),
        13,
      );
    });

    test('zamek może punktować przy mieście, drodze i klasztorze', () {
      expect(ScoringType.city.supportsCastle, isTrue);
      expect(ScoringType.road.supportsCastle, isTrue);
      expect(ScoringType.cloister.supportsCastle, isTrue);
      expect(ScoringType.meadow.supportsCastle, isFalse);
    });

    test('dyrektor cyrku dodaje 2 pkt za płytkę (przykład z instrukcji)', () {
      // Ukończona droga 5 pkt + 4 płytki cyrku/akrobatów = 13 pkt.
      expect(
        calculatePoints(ScoringType.road, tiles: 5, circusTiles: 4),
        13,
      );
    });

    test('dyrektor punktuje samodzielnie, gdy nie ma większości', () {
      expect(
        calculatePoints(ScoringType.ringmaster, tiles: 0, circusTiles: 3),
        6,
      );
    });

    test('dyrektor w ukończonym klasztorze', () {
      expect(
        calculatePoints(ScoringType.cloister, tiles: 0, circusTiles: 3),
        15,
      );
    });
  });

  group('surowce liczone na bieżąco', () {
    test('prowadzi gracz z największą liczbą, zero nie liczy się jako lider', () {
      final a = _player('A', goods: {Goods.wine: 2});
      final b = _player('B', goods: {Goods.wine: 1});
      final c = _player('C');
      final all = [a, b, c];

      expect(goodsLeaders(Goods.wine, all), [a]);
      expect(goodsLeaders(Goods.grain, all), isEmpty);
    });

    test('remis: każdy remisujący dostaje pełne 10 pkt', () {
      final a = _player('A', goods: {Goods.wine: 2});
      final b = _player('B', goods: {Goods.wine: 2});
      final c = _player('C', goods: {Goods.wine: 1});
      final all = [a, b, c];

      expect(goodsLeaders(Goods.wine, all), [a, b]);
      expect(goodsBonus(a, all), 10);
      expect(goodsBonus(b, all), 10);
      expect(goodsBonus(c, all), 0);
    });

    test('każdy rodzaj surowca liczy się osobno', () {
      final a = _player('A', points: 5, goods: {Goods.wine: 2, Goods.grain: 1});
      final b = _player('B', goods: {Goods.wine: 2, Goods.cloth: 3});
      final c = _player('C');
      final all = [a, b, c];

      expect(goodsBonus(a, all), 20); // wino (remis) + żyto
      expect(goodsBonus(b, all), 20); // wino (remis) + sukno
      expect(totalScore(a, all), 25);
      expect(totalScore(c, all), 0);
    });

    test('lider zmienia się, gdy ktoś go przegoni', () {
      final a = _player('A', goods: {Goods.cloth: 1});
      final b = _player('B');
      final all = [a, b];
      expect(goodsBonus(a, all), 10);

      b.goods[Goods.cloth] = 2;
      expect(goodsBonus(a, all), 0);
      expect(goodsBonus(b, all), 10);
    });
  });

  group('cyrk', () {
    test('w grze jest 16 żetonów zwierząt', () {
      expect(CircusAnimal.values.fold<int>(0, (s, a) => s + a.count), 16);
    });

    test('wartości zwierząt z polskiej edycji', () {
      expect(CircusAnimal.elephant.value, 7);
      expect(CircusAnimal.lion.value, 6);
      expect(CircusAnimal.bear.value, 5);
      expect(CircusAnimal.seal.value, 4);
      expect(CircusAnimal.monkey.value, 3);
      expect(CircusAnimal.flea.value, 1);
    });

    test('foka i trzy ludki dają 12 pkt (przykład z instrukcji)', () {
      expect(circusPoints(CircusAnimal.seal, 3), 12);
    });

    test('akrobata jest wart 5 pkt, piramida ma 3 ludki', () {
      expect(acrobatPoints(3), 15);
      expect(kPyramidSize, 3);
    });

    test('dyrektor cyrku: 2 pkt za płytkę', () {
      expect(ringmasterPoints(4), 8);
    });
  });

  group('owce', () {
    test('limity żetonów dają 37 owiec w 16 żetonach', () {
      final sheep = kSheepTokens.entries.fold<int>(
        0,
        (sum, e) => sum + e.key * e.value,
      );
      final tokens = kSheepTokens.values.fold<int>(0, (a, b) => a + b);

      expect(sheep, kMaxSheep);
      expect(tokens, kSheepTokenCount);
    });

    test('stado nie może mieć więcej owiec niż w grze', () {
      expect(flockPoints({1: 4, 2: 5, 3: 5, 4: 2}), kMaxSheep);
      expect(flockPoints({1: 99, 2: 99, 3: 99, 4: 99}), kMaxSheep);
    });

    test('liczba żetonów jest obcinana do limitu danego rodzaju', () {
      expect(flockPoints({4: 9}), 8);
    });

    test('zwykłe stado', () {
      expect(flockPoints({1: 2, 3: 1}), 5);
      expect(flockPoints({}), 0);
    });
  });

  group('zdarzenia punktowe (cofanie)', () {
    test('apply i revert przywracają stan, także dla wielu graczy', () {
      final a = _player('A');
      final b = _player('B', points: 7);
      final event = ScoreEvent('test', [
        ScoreChange(a, 10, goods: {Goods.wine: 2}),
        ScoreChange(b, -3),
      ]);

      event.apply();
      expect(a.points, 10);
      expect(a.goodsOf(Goods.wine), 2);
      expect(b.points, 4);

      event.revert();
      expect(a.points, 0);
      expect(a.goodsOf(Goods.wine), 0);
      expect(b.points, 7);
    });
  });

  group('zapis gracza z surowcami', () {
    test('surowce przetrwają zapis i odczyt JSON', () {
      final player = _player(
        'Ala',
        points: 3,
        goods: {Goods.wine: 1, Goods.cloth: 4},
      );

      final restored = Player.fromJson(player.toJson());

      expect(restored.goodsOf(Goods.wine), 1);
      expect(restored.goodsOf(Goods.grain), 0);
      expect(restored.goodsOf(Goods.cloth), 4);
      expect(restored.goodsTotal, 5);
    });

    test('stary zapis bez surowców daje zero', () {
      final restored = Player.fromJson({
        'name': 'Ola',
        'color': 0xFF078E04,
        'points': 9,
      });

      expect(restored.goodsTotal, 0);
      expect(restored.points, 9);
    });
  });

  group('limity z gry', () {
    test('w grze jest 20 żetonów surowców: 9 wina, 6 żyta, 5 sukna', () {
      expect(Goods.wine.supply, 9);
      expect(Goods.grain.supply, 6);
      expect(Goods.cloth.supply, 5);
      expect(Goods.values.fold<int>(0, (s, g) => s + g.supply), 20);
    });

    test('pula surowców maleje o to, co mają gracze', () {
      final a = _player('A', goods: {Goods.wine: 4, Goods.cloth: 5});
      final b = _player('B', goods: {Goods.wine: 3});
      final all = [a, b];

      expect(goodsRemaining(Goods.wine, all), 2);
      expect(goodsRemaining(Goods.grain, all), 6);
      expect(goodsRemaining(Goods.cloth, all), 0);
    });

    test('pula nigdy nie jest ujemna', () {
      final a = _player('A', goods: {Goods.cloth: 8});

      expect(goodsRemaining(Goods.cloth, [a]), 0);
    });

    test('dyrektor cyrku ma najwyżej 9 płytek w obszarze 3×3', () {
      expect(kMaxRingmasterTiles, 9);
      expect(ringmasterPoints(kMaxRingmasterTiles), 18);
    });
  });

  group('winnice (Wzgórza i owce)', () {
    test('ukończony klasztor: 9 pkt + 3 pkt za każdą winnicę', () {
      expect(
        calculatePoints(ScoringType.cloister, tiles: 0, vineyards: 2),
        15,
      );
      expect(
        calculatePoints(
          ScoringType.cloister,
          tiles: 0,
          vineyards: kMaxVineyards,
        ),
        9 + 8 * kVineyardPoints,
      );
    });

    test('nieukończony klasztor nie dostaje punktów za winnice', () {
      expect(
        calculatePoints(
          ScoringType.cloister,
          tiles: 6,
          vineyards: 3,
          completed: false,
        ),
        6,
      );
    });
  });

  group('wróżka (Księżniczka i smok)', () {
    test('samo kliknięcie wróżki daje 1 pkt', () {
      expect(kFairyTurnPoints, 1);
      expect(calculatePoints(ScoringType.fairy), 1);
      expect(calculatePoints(ScoringType.fairy, tiles: 9), 1);
    });

    test('ukończone miasto z wróżką: +3 pkt do zwykłej punktacji', () {
      expect(
        calculatePoints(ScoringType.city, tiles: 4, banners: 1),
        10,
      );
      expect(
        calculatePoints(
          ScoringType.city,
          tiles: 4,
          banners: 1,
          withFairy: true,
        ),
        13,
      );
    });

    test('wróżka daje 3 pkt także bez zwykłych punktów', () {
      // Nieukończone miasto z katedrą = 0 pkt, ale wróżka nadal punktuje.
      expect(
        calculatePoints(
          ScoringType.city,
          tiles: 4,
          completed: false,
          bonus: true,
          withFairy: true,
        ),
        kFairyFeaturePoints,
      );
    });

    test('wróżka działa przy drodze, klasztorze i polu', () {
      expect(calculatePoints(ScoringType.road, tiles: 5, withFairy: true), 8);
      expect(calculatePoints(ScoringType.cloister, withFairy: true), 12);
      expect(
        calculatePoints(ScoringType.meadow, tiles: 2, withFairy: true),
        9,
      );
    });

    test('wróżka nie dodaje punktów do zamku ani owiec', () {
      expect(
        calculatePoints(ScoringType.sheep, tiles: 6, withFairy: true),
        6,
      );
      expect(
        calculatePoints(ScoringType.sheep, tiles: 5, withFairy: true),
        5,
      );
    });

    test('wróżka łączy się z dyrektorem cyrku', () {
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 5,
          circusTiles: 4,
          withFairy: true,
        ),
        16,
      );
    });
  });

  group('ustawienia', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('domyślnie ekran nie jest wygaszany i wszystkie dodatki są włączone',
        () async {
      SharedPreferences.setMockInitialValues({});

      final settings = await SettingsStorage().load();

      expect(settings.keepScreenOn, isTrue);
      expect(settings.expansions, Expansion.values.toSet());
    });

    test('ustawienie nie wygaszania ekranu jest zapamiętywane', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = SettingsStorage();

      await storage.save(GameSettings(keepScreenOn: false));
      final restored = await storage.load();

      expect(restored.keepScreenOn, isFalse);
    });

    test('po aktualizacji nowe dodatki (Księżniczka i smok, Karczmy i katedry) '
        'są włączone',
        () async {
      // Zapis sprzed wprowadzenia dodatku: wybrany tylko cyrk.
      SharedPreferences.setMockInitialValues({
        'expansions': ['circus'],
      });

      final settings = await SettingsStorage().load();

      expect(
        settings.expansions,
        {
          Expansion.circus,
          Expansion.princessDragon,
          Expansion.innsCathedrals,
        },
      );
    });

    test('świadomie wyłączony dodatek pozostaje wyłączony', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = SettingsStorage();

      await storage.save(
        GameSettings(expansions: {Expansion.circus}),
      );
      final restored = await storage.load();

      expect(restored.expansions, {Expansion.circus});
    });
  });

  group('punkty wspólne i zamki', () {
    test('współdzielący dostają te same punkty co punktujący', () {
      final a = _player('A');
      final b = _player('B');
      final c = _player('C');

      final result = splitPoints(
        scorer: a,
        base: 8,
        others: {b: const PointsShare(), c: const PointsShare()},
      );

      expect(result, {a: 8, b: 8, c: 8});
    });

    test('właściciel zamku dostaje punkty za każdy zamek', () {
      final a = _player('A');
      final b = _player('B');
      final c = _player('C');

      // A i B dzielą budowlę, C ma przy niej dwa zamki.
      final result = splitPoints(
        scorer: a,
        base: 10,
        others: {
          b: const PointsShare(),
          c: const PointsShare(castle: true, castles: 2),
        },
      );

      expect(result, {a: 10, b: 10, c: 20});
    });

    test('premie przy ludku dostaje tylko punktujący', () {
      final a = _player('A');
      final b = _player('B');

      final result = splitPoints(
        scorer: a,
        base: 6,
        extras: 3,
        others: {b: const PointsShare()},
      );

      expect(result, {a: 9, b: 6});
    });

    test('punktujący jako zamek nie dostaje premii przy ludku', () {
      final a = _player('A');

      final result = splitPoints(
        scorer: a,
        base: 4,
        extras: 3,
        scorerAsCastle: true,
        scorerCastles: 2,
      );

      expect(result, {a: 8});
    });

    test('punktujący jest pierwszy i nie liczy się dwa razy', () {
      final a = _player('A');
      final b = _player('B');

      final result = splitPoints(
        scorer: a,
        base: 5,
        others: {a: const PointsShare(), b: const PointsShare()},
      );

      expect(result.keys.toList(), [a, b]);
      expect(result[a], 5);
    });
  });

  group('historia punktów', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('wpis opisuje punkty i surowce każdego gracza', () {
      final entry = HistoryEntry.fromEvent(
        ScoreEvent('Miasto', [
          ScoreChange(_player('Ala'), 12, goods: {Goods.wine: 1}),
          ScoreChange(_player('Ola'), -3),
        ]),
        now: DateTime(2026, 10, 24, 14, 5),
      );

      expect(entry.label, 'Miasto');
      expect(entry.lines, ['Ala: +12 pkt, Wino ×1', 'Ola: -3 pkt']);
    });

    test('historia przetrwa zapis i odczyt', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = HistoryStorage();
      final entry = HistoryEntry(
        id: 1,
        time: DateTime.fromMillisecondsSinceEpoch(1000),
        label: 'Test',
        category: 'Miasto',
        changes: const [
          HistoryChange(player: 'Ala', points: 1, goods: {'Wino': 2}),
        ],
      );

      await storage.save([entry]);
      final restored = await storage.load();

      expect(restored, hasLength(1));
      expect(restored.single.label, 'Test');
      expect(restored.single.category, 'Miasto');
      expect(restored.single.lines, ['Ala: +1 pkt, Wino ×2']);
      expect(restored.single.time, entry.time);
    });

    test('zapisujemy tylko ostatnie wpisy', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = HistoryStorage();
      await storage.save([
        for (var i = 0; i < HistoryStorage.maxEntries + 5; i++)
          HistoryEntry(id: i, time: DateTime(2026), label: '$i'),
      ]);

      final restored = await storage.load();

      expect(restored, hasLength(HistoryStorage.maxEntries));
      expect(restored.first.label, '5');
    });
  });

  group('dostępne typy punktacji', () {
    test('bez dodatków: tylko gra podstawowa', () {
      expect(ScoringType.availableFor({}), [
        ScoringType.city,
        ScoringType.road,
        ScoringType.cloister,
        ScoringType.meadow,
      ]);
    });

    test('wróżka należy do dodatku Księżniczka i smok', () {
      expect(
        ScoringType.availableFor({Expansion.princessDragon}),
        contains(ScoringType.fairy),
      );
      expect(
        ScoringType.availableFor({Expansion.circus}),
        isNot(contains(ScoringType.fairy)),
      );
    });

    test('cyrk dodaje cyrk, akrobatów i dyrektora', () {
      final types = ScoringType.availableFor({Expansion.circus});
      expect(types, containsAll([
        ScoringType.circus,
        ScoringType.pyramid,
        ScoringType.ringmaster,
      ]));
      expect(types, isNot(contains(ScoringType.sheep)));
    });

    test('wszystkie dodatki włączają wszystkie typy', () {
      expect(
        ScoringType.availableFor(Expansion.values.toSet()),
        ScoringType.values,
      );
    });
  });
}
