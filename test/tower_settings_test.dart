import 'dart:ui';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cc_new/l10n/tr.dart';
import 'package:cc_new/models/expansion.dart';
import 'package:cc_new/models/history_entry.dart';
import 'package:cc_new/models/player.dart';
import 'package:cc_new/models/score_event.dart';
import 'package:cc_new/models/scoring.dart';
import 'package:cc_new/models/tower.dart';
import 'package:cc_new/services/settings_storage.dart';

Player _player(String name, {int points = 0}) =>
    Player(name: name, color: const Color(0xFF1D27EA), points: points);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => appLanguage.value = AppLanguage.pl);

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
      ]);
      expect([for (final e in Expansion.values) e.number], [
        1, 2, 3, 4, 5, 8, 9, 10, 4, //
      ]);
    });

    test('etykieta zawiera numer, a mini dodatek dopisek na końcu', () {
      expect(Expansion.tower.label, '4. Wieża');
      expect(Expansion.innsCathedrals.label, '1. Karczmy i katedry');
      expect(Expansion.goldMines.label, 'Kopalnie złota (Mini dodatek 4)');
      expect(Expansion.goldMines.mini, isTrue);
    });

    test('Wzgórza i owce nazywają się po polsku „Owce i wzgórza"', () {
      expect(Expansion.hillsSheep.displayName, 'Owce i wzgórza');
    });
  });

  group('język interfejsu', () {
    test('tr wybiera tekst według języka', () {
      expect(tr('Miasto', 'City'), 'Miasto');
      appLanguage.value = AppLanguage.en;
      expect(tr('Miasto', 'City'), 'City');
    });

    test('nazwy dodatków i punktacji zmieniają się z językiem', () {
      appLanguage.value = AppLanguage.en;
      expect(Expansion.hillsSheep.displayName, 'Hills & Sheep');
      expect(Expansion.goldMines.label, 'Gold Mines (Mini expansion 4)');
      expect(Expansion.tower.label, '4. The Tower');
      expect(ScoringType.meadow.displayName, 'Farms');
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
}
