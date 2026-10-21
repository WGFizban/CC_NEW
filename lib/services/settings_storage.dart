import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/circus.dart';
import '../models/expansion.dart';

/// Ustawienia i stan gry niezwiązany z konkretnym graczem.
class GameSettings {
  /// Włączone dodatki (domyślnie wszystkie).
  final Set<Expansion> expansions;

  /// Ile żetonów zwierząt cyrku zostało już odkrytych i zużytych.
  final Map<CircusAnimal, int> usedAnimals;

  GameSettings({Set<Expansion>? expansions, Map<CircusAnimal, int>? usedAnimals})
    : expansions = expansions ?? Expansion.values.toSet(),
      usedAnimals = usedAnimals ?? {};

  /// Ile żetonów danego zwierzęcia zostało jeszcze w stosie.
  int remaining(CircusAnimal animal) =>
      animal.count - (usedAnimals[animal] ?? 0);
}

class SettingsStorage {
  static const _expansionsKey = 'expansions';
  static const _usedAnimalsKey = 'circus_used';

  Future<GameSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    Set<Expansion>? expansions;
    final names = prefs.getStringList(_expansionsKey);
    if (names != null) {
      expansions = {
        for (final e in Expansion.values)
          if (names.contains(e.name)) e,
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

    return GameSettings(expansions: expansions, usedAnimals: used);
  }

  Future<void> save(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_expansionsKey, [
      for (final e in settings.expansions) e.name,
    ]);
    await prefs.setString(
      _usedAnimalsKey,
      json.encode({
        for (final e in settings.usedAnimals.entries) e.key.name: e.value,
      }),
    );
  }
}
