import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/tr.dart';
import '../models/circus.dart';
import '../models/expansion.dart';

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

  GameSettings({
    Set<Expansion>? expansions,
    Map<CircusAnimal, int>? usedAnimals,
    this.keepScreenOn = true,
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.pl,
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
    );
  }

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
    await prefs.setString(
      _usedAnimalsKey,
      json.encode({
        for (final e in settings.usedAnimals.entries) e.key.name: e.value,
      }),
    );
  }
}
