import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';
import '../models/circus.dart';
import '../models/expansion.dart';
import '../models/game_state.dart';

/// Ustawienia i stan gry niezwiązany z konkretnym graczem.
class GameSettings {
  /// Włączone dodatki (domyślnie żaden).
  final Set<Expansion> expansions;

  /// Ile żetonów zwierząt cyrku zostało już odkrytych i zużytych.
  final Map<CircusAnimal, int> usedAnimals;

  /// Czy nie wygaszać ekranu, gdy aplikacja jest otwarta.
  bool keepScreenOn;

  /// Motyw aplikacji (domyślnie zgodny z systemem).
  ThemeMode themeMode;

  /// Język interfejsu (domyślnie polski).
  AppLanguage language;

  /// Etap gry oraz czas jej rozpoczęcia i zakończenia. Etap `null` oznacza
  /// stary zapis bez etapu (patrz [inferLegacyStage]).
  /// Czy użytkownik widział już samouczek (pokazujemy go przy pierwszym
  /// uruchomieniu).
  bool tutorialSeen;

  GameStage? stage;
  DateTime? startedAt;
  DateTime? endedAt;

  GameSettings({
    Set<Expansion>? expansions,
    Map<CircusAnimal, int>? usedAnimals,
    this.keepScreenOn = true,
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.pl,
    this.stage,
    this.tutorialSeen = false,
    this.startedAt,
    this.endedAt,
  }) : expansions = expansions ?? <Expansion>{},
       usedAnimals = usedAnimals ?? {};

  /// Ile żetonów danego zwierzęcia zostało jeszcze w stosie.
  int remaining(CircusAnimal animal) =>
      animal.count - (usedAnimals[animal] ?? 0);
}

class SettingsStorage {
  static const _expansionsKey = 'expansions';
  static const _seenKey = 'expansions_seen';
  static const _usedAnimalsKey = 'circus_used';
  static const _keepScreenOnKey = 'keep_screen_on';
  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language';
  static const _tutorialKey = 'tutorial_seen';
  static const _stageKey = 'game_stage';
  static const _startedKey = 'game_started_at';
  static const _endedKey = 'game_ended_at';

  /// Dodatki znane, zanim zaczęliśmy zapisywać listę „widzianych".
  static const _legacyExpansions = {
    'tradersBuilders',
    'bridgesCastlesBazaars',
    'circus',
    'hillsSheep',
  };

  /// Elementy, które w starych zapisach były częścią gry podstawowej (wróżka
  /// oraz katedra i karczma), więc po aktualizacji zostają włączone. Wszystkie
  /// nowsze dodatki startują jako wyłączone.
  static const _formerlyBaseGame = {
    Expansion.princessDragon,
    Expansion.innsCathedrals,
  };

  Future<GameSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    Set<Expansion>? expansions;
    final names = prefs.getStringList(_expansionsKey);
    if (names != null) {
      final storedSeen = prefs.getStringList(_seenKey);
      final seen = (storedSeen ?? _legacyExpansions.toList()).toSet();
      expansions = {
        for (final e in Expansion.values)
          if (names.contains(e.name) ||
              // Tylko bardzo stary zapis (bez listy „widzianych") traktuje
              // wróżkę oraz katedrę i karczmę jako grę podstawową.
              (storedSeen == null &&
                  !seen.contains(e.name) &&
                  _formerlyBaseGame.contains(e)))
            e,
      };
    }

    final used = <CircusAnimal, int>{};
    final raw = prefs.getString(_usedAnimalsKey);
    if (raw != null) {
      try {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        for (final animal in CircusAnimal.values) {
          final count = decoded[animal.name];
          if (count is int && count > 0) used[animal] = count;
        }
      } catch (_) {
        // Uszkodzone dane – zaczynamy od pełnego stosu żetonów.
      }
    }

    return GameSettings(
      expansions: expansions,
      usedAnimals: used,
      keepScreenOn: prefs.getBool(_keepScreenOnKey) ?? true,
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_themeKey),
        orElse: () => ThemeMode.system,
      ),
      language: AppLanguage.fromCode(prefs.getString(_languageKey)),
      tutorialSeen: prefs.getBool(_tutorialKey) ?? false,
      stage: GameStage.values
          .where((g) => g.name == prefs.getString(_stageKey))
          .firstOrNull,
      startedAt: _readTime(prefs.getString(_startedKey)),
      endedAt: _readTime(prefs.getString(_endedKey)),
    );
  }

  static DateTime? _readTime(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);

  Future<void> save(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_expansionsKey, [
      for (final e in settings.expansions) e.name,
    ]);
    await prefs.setStringList(_seenKey, [
      for (final e in Expansion.values) e.name,
    ]);
    await prefs.setBool(_keepScreenOnKey, settings.keepScreenOn);
    await prefs.setString(_themeKey, settings.themeMode.name);
    await prefs.setString(_languageKey, settings.language.code);
    await prefs.setBool(_tutorialKey, settings.tutorialSeen);
    await _writeString(prefs, _stageKey, settings.stage?.name);
    await _writeString(prefs, _startedKey, settings.startedAt?.toIso8601String());
    await _writeString(prefs, _endedKey, settings.endedAt?.toIso8601String());
    await prefs.setString(
      _usedAnimalsKey,
      json.encode({
        for (final e in settings.usedAnimals.entries) e.key.name: e.value,
      }),
    );
  }

  static Future<void> _writeString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }
}
