import 'dart:ui';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cc_new/l10n/app_language.dart';
import 'package:cc_new/l10n/app_localizations_en.dart';
import 'package:cc_new/l10n/app_localizations_pl.dart';
import 'package:cc_new/l10n/labels.dart';
import 'package:cc_new/models/circus.dart';
import 'package:cc_new/models/expansion.dart';
import 'package:cc_new/models/game_state.dart';
import 'package:cc_new/models/german.dart';
import 'package:cc_new/models/goods.dart';
import 'package:cc_new/models/history_entry.dart';
import 'package:cc_new/models/player.dart';
import 'package:cc_new/models/score_event.dart';
import 'package:cc_new/models/scoring.dart';
import 'package:cc_new/models/app_version.dart';
import 'package:cc_new/models/monastery.dart';
import 'package:cc_new/models/summary.dart';
import 'package:cc_new/models/tower.dart';
import 'package:cc_new/services/settings_storage.dart';

Player _player(String name, {int points = 0}) =>
    Player(name: name, color: const Color(0xFF1D27EA), points: points);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pl = AppLocalizationsPl();
  final en = AppLocalizationsEn();

  group('wieża: wykup mepla', () {
    test('okup to 3 punkty', () {
      expect(kRansomPoints, 3);
    });

    test('wykupić może gracz z co najmniej 3 punktami', () {
      expect(canAffordRansom(_player('A', points: 2)), isFalse);
      expect(canAffordRansom(_player('A', points: 3)), isTrue);
      expect(canAffordRansom(_player('A', points: 40)), isTrue);
    });

    test('wykup przesuwa 3 punkty od wykupującego do właściciela jeńca', () {
      final buyer = _player('A', points: 10);
      final holder = _player('B', points: 4);
      final event = ScoreEvent('Wieża', [
        ScoreChange(buyer, -kRansomPoints),
        ScoreChange(holder, kRansomPoints),
      ]);

      event.apply();
      expect((buyer.points, holder.points), (7, 7));

      event.revert();
      expect((buyer.points, holder.points), (10, 4));
    });

    test('wieża jest dostępna tylko z dodatkiem Wieża', () {
      expect(ScoringType.availableFor({}), isNot(contains(ScoringType.tower)));
      expect(
        ScoringType.availableFor({Expansion.tower}),
        contains(ScoringType.tower),
      );
      expect(ScoringType.tower.expansion, Expansion.tower);
    });

    test('wieża sama nie liczy punktów budowli', () {
      expect(calculatePoints(ScoringType.tower, tiles: 5), 0);
    });
  });

  group('numeracja dodatków', () {
    test('dodatki są ułożone według numerów, a mini dodatki na końcu', () {
      expect(Expansion.values, [
        Expansion.innsCathedrals,
        Expansion.tradersBuilders,
        Expansion.princessDragon,
        Expansion.tower,
        Expansion.abbeyMayor,
        Expansion.bridgesCastlesBazaars,
        Expansion.hillsSheep,
        Expansion.circus,
        Expansion.goldMines,
        Expansion.monasteries,
        Expansion.germanCastles,
        Expansion.germanCathedrals,
      ]);
      expect([for (final e in Expansion.values) e.number], [
        1, 2, 3, 4, 5, 8, 9, 10, 4, 5, 6, 7, //
      ]);
    });

    test('etykieta zawiera numer, a mini dodatek dopisek na końcu', () {
      expect(Expansion.tower.label(pl), '4. Wieża');
      expect(Expansion.innsCathedrals.label(pl), '1. Karczmy i katedry');
      expect(Expansion.goldMines.label(pl), 'Kopalnie złota (Mini dodatek 4)');
      expect(Expansion.goldMines.mini, isTrue);
    });

    test('Wzgórza i owce nazywają się po polsku „Owce i wzgórza"', () {
      expect(Expansion.hillsSheep.title(pl), 'Owce i wzgórza');
    });
  });

  group('język interfejsu', () {
    test('nazwy dodatków i punktacji zmieniają się z językiem', () {
      expect(Expansion.hillsSheep.title(en), 'Hills & Sheep');
      expect(Expansion.goldMines.label(en), 'Gold Mines (Mini expansion 4)');
      expect(Expansion.tower.label(en), '4. The Tower');
      expect(ScoringType.meadow.title(en), 'Farms');
      expect(ScoringType.meadow.title(pl), 'Pola');
    });

    test('każdy dodatek, typ punktacji i surowiec ma nazwę w obu językach', () {
      for (final l in [pl, en]) {
        for (final e in Expansion.values) {
          expect(e.title(l), isNotEmpty);
          expect(e.description(l), isNotEmpty);
        }
        for (final t in ScoringType.values) {
          expect(t.title(l), isNotEmpty);
        }
        for (final g in Goods.values) {
          expect(g.title(l), isNotEmpty);
        }
        for (final a in CircusAnimal.values) {
          expect(a.title(l), isNotEmpty);
        }
      }
    });

    test('teksty z parametrami wstawiają wartości', () {
      expect(pl.bazaarBuyDesc('Ala', 5, 'Ola'), 'Ala płaci 5 pkt, a Ola je dostaje.');
      expect(en.bazaarBuyDesc('Ala', 5, 'Ola'), 'Ala pays 5 pts and Ola receives them.');
      expect(pl.sheepWord(1), 'owca');
      expect(pl.sheepWord(3), 'owce');
    });

    test('nieznany kod języka daje polski', () {
      expect(AppLanguage.fromCode('xx'), AppLanguage.pl);
      expect(AppLanguage.fromCode(null), AppLanguage.pl);
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
    });
  });

  group('ustawienia: motyw i język', () {
    test('domyślnie motyw systemowy i polski', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = await SettingsStorage().load();

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.language, AppLanguage.pl);
    });

    test('motyw i język przetrwają zapis i odczyt', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = SettingsStorage();
      final settings = await storage.load();
      settings
        ..themeMode = ThemeMode.dark
        ..language = AppLanguage.en;
      await storage.save(settings);

      final restored = await storage.load();

      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.language, AppLanguage.en);
    });

    test('etap i czas gry przetrwają zapis i odczyt', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = SettingsStorage();
      final settings = await storage.load();
      expect(settings.stage, isNull);
      final start = DateTime(2026, 1, 1, 12);
      settings
        ..stage = GameStage.finished
        ..startedAt = start
        ..endedAt = start.add(const Duration(minutes: 30));
      await storage.save(settings);

      final restored = await storage.load();

      expect(restored.stage, GameStage.finished);
      expect(restored.startedAt, start);
      expect(restored.endedAt, start.add(const Duration(minutes: 30)));
    });

    test('uszkodzone wartości dają ustawienia domyślne', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'neon',
        'language': 'xx',
      });
      final settings = await SettingsStorage().load();

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.language, AppLanguage.pl);
    });

    test('nowy dodatek Wieża jest domyślnie wyłączony po aktualizacji', () async {
      SharedPreferences.setMockInitialValues({
        'expansions': ['circus'],
        'expansions_seen': [
          'innsCathedrals',
          'tradersBuilders',
          'abbeyMayor',
          'princessDragon',
          'bridgesCastlesBazaars',
          'circus',
          'hillsSheep',
          'goldMines',
        ],
      });
      final settings = await SettingsStorage().load();

      expect(settings.expansions, {Expansion.circus});
    });
  });

  group('historia: kolor i wynik łączny', () {
    test('wpis zapamiętuje kolor gracza i jego wynik po zdarzeniu', () {
      final ala = _player('Ala', points: 12);
      final entry = HistoryEntry.fromEvent(
        ScoreEvent('Miasto', [ScoreChange(ala, 12)]),
        totals: {ala: 22},
      );

      expect(entry.changes.single.color, 0xFF1D27EA);
      expect(entry.changes.single.total, 22);
    });

    test('kolor i wynik przetrwają zapis do JSON-a', () {
      final entry = HistoryEntry(
        id: 1,
        time: DateTime.fromMillisecondsSinceEpoch(1000),
        label: 'Test',
        changes: const [
          HistoryChange(player: 'Ala', points: 3, color: 0xFFCC1B1B, total: 9),
        ],
      );

      final restored = HistoryEntry.fromJson(entry.toJson());

      expect(restored.changes.single.color, 0xFFCC1B1B);
      expect(restored.changes.single.total, 9);
    });

    test('surowce w historii są zapisane kluczem i tłumaczone przy wyświetlaniu',
        () {
      const change = HistoryChange(
        player: 'Ala',
        points: 1,
        goods: {'wine': 2},
        gold: 3,
      );

      expect(change.goodsText(pl), 'Wino ×2, Złoto ×3');
      expect(change.goodsText(en), 'Wine ×2, Gold ×3');
    });

    test('starsze wpisy z polskimi nazwami surowców wyświetlają się bez zmian',
        () {
      const change = HistoryChange(player: 'Ala', points: 1, goods: {'Wino': 2});

      expect(change.goodsText(en), 'Wino ×2');
    });

    test('wpis zapamiętuje rodzaj punktacji, po którym wybierana jest ikona', () {
      final entry = HistoryEntry.fromEvent(
        ScoreEvent(
          'Droga',
          [ScoreChange(_player('Ala'), 4)],
          type: ScoringType.road,
        ),
      );

      expect(entry.type, 'road');
      expect(entry.scoringType, ScoringType.road);
      expect(HistoryEntry.fromJson(entry.toJson()).scoringType, ScoringType.road);
    });

    test('wpis bez rodzaju lub z nieznanym rodzajem nie ma ikony', () {
      final old = HistoryEntry.fromJson({
        'id': 1,
        'time': 1000,
        'label': 'Stary',
        'changes': [],
      });
      final unknown = HistoryEntry.fromJson({
        'id': 2,
        'time': 1000,
        'label': 'Nowy',
        'type': 'nieistnieje',
        'changes': [],
      });

      expect(old.scoringType, isNull);
      expect(unknown.scoringType, isNull);
    });

    test('starsze wpisy bez koloru i wyniku nadal się wczytują', () {
      final restored = HistoryEntry.fromJson({
        'id': 1,
        'time': 1000,
        'label': 'Stary',
        'changes': [
          {'player': 'Ala', 'points': 2, 'goods': {}, 'gold': 0},
        ],
      });

      expect(restored.changes.single.color, isNull);
      expect(restored.changes.single.total, isNull);
      expect(restored.changes.single.points, 2);
    });
  });

  group('podsumowanie: punkty według rodzaju', () {
    test('sumuje punkty graczy osobno dla każdego rodzaju punktacji', () {
      final ala = _player('Ala');
      final bob = _player('Bob');
      HistoryEntry e(ScoringType t, Player p, int pts) => HistoryEntry.fromEvent(
        ScoreEvent('x', [ScoreChange(p, pts)], type: t),
      );
      final log = [
        e(ScoringType.city, ala, 8),
        e(ScoringType.city, ala, 4),
        e(ScoringType.road, ala, 3),
        e(ScoringType.city, bob, 6),
      ];

      final result = pointsByType(log);

      expect(result['Ala']![ScoringType.city], 12);
      expect(result['Ala']![ScoringType.road], 3);
      expect(result['Bob']![ScoringType.city], 6);
      expect(result['Bob']![ScoringType.road], isNull);
    });
  });

  group('klasztory niemieckie i holenderskie', () {
    test('opat: punkty za płytki w liniach plus sam klasztor', () {
      expect(monasteryLinePoints(0), 1);
      expect(monasteryLinePoints(5), 6);
    });

    test('typ punktacji jest dostępny tylko z włączonym dodatkiem', () {
      expect(ScoringType.availableFor({}), isNot(contains(ScoringType.monastery)));
      expect(
        ScoringType.availableFor({Expansion.monasteries}),
        contains(ScoringType.monastery),
      );
      expect(Expansion.monasteries.mini, isTrue);
    });
  });

  group('wersja aplikacji', () {
    test('wydanie z GitHuba pokazujemy jako vN, a inne wersje bez zmian', () {
      expect(formatAppVersion('7'), 'v7');
      expect(formatAppVersion('0.1.0'), '0.1.0');
    });
  });

  group('zamki i katedry w Niemczech', () {
    test('zamek na końcu ukończonej drogi lub miasta daje 3 pkt za sztukę', () {
      // Przykłady z instrukcji: miasto 10 pkt + 2 zamki = 16, droga 2 + 3 = 5.
      expect(
        calculatePoints(ScoringType.city, tiles: 3, banners: 2, germanCastles: 2),
        10 + 2 * kGermanCastleBonus,
      );
      expect(
        calculatePoints(ScoringType.road, tiles: 2, germanCastles: 1),
        2 + kGermanCastleBonus,
      );
      expect(
        calculatePoints(ScoringType.road, tiles: 4, germanCastles: 2),
        4 + 2 * kGermanCastleBonus,
      );
    });

    test('premia za zamek jest po karczmie i katedrze, a nieukończona jej nie ma', () {
      expect(
        calculatePoints(ScoringType.city, tiles: 2, bonus: true, germanCastles: 1),
        2 * 3 + kGermanCastleBonus,
      );
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 3,
          completed: false,
          germanCastles: 1,
        ),
        3,
      );
    });

    test('pan zamku: 12 pkt albo 2 pkt plus płytki wokół na koniec gry', () {
      expect(calculatePoints(ScoringType.germanCastle), 12);
      expect(
        calculatePoints(ScoringType.germanCastle, completed: false, tiles: 6),
        8,
      );
    });

    test('droga z rondem: trzy niemieckie zamki dają 9 pkt premii', () {
      expect(
        calculatePoints(ScoringType.road, tiles: 5, germanCastles: 3),
        14,
      );
    });

    test('droga do katedry: 2 pkt za płytkę, z karczmą 3', () {
      expect(
        calculatePoints(ScoringType.road, tiles: 4, cathedralRoad: true),
        8,
      );
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 4,
          cathedralRoad: true,
          bonus: true,
        ),
        12,
      );
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 4,
          cathedralRoad: true,
          completed: false,
        ),
        8,
      );
      expect(
        calculatePoints(
          ScoringType.road,
          tiles: 4,
          cathedralRoad: true,
          completed: false,
          bonus: true,
        ),
        0,
      );
    });

    test('arcybiskup: 1 pkt za odcinek, z karczmą 2, nieukończona 0', () {
      expect(calculatePoints(ScoringType.archbishop, tiles: 8), 8);
      expect(calculatePoints(ScoringType.archbishop, tiles: 8, bonus: true), 16);
      expect(
        calculatePoints(ScoringType.archbishop, tiles: 5, completed: false),
        0,
      );
      expect(
        calculatePoints(
          ScoringType.archbishop,
          tiles: 5,
          completed: false,
          bonus: true,
        ),
        0,
      );
    });

    test('dodatki są mini dodatkami 6 i 7', () {
      expect(Expansion.germanCastles.number, 6);
      expect(Expansion.germanCathedrals.number, 7);
      expect(Expansion.germanCastles.mini, isTrue);
    });
  });
}
