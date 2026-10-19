import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player.dart';

/// Zapis i odczyt listy graczy w pamięci urządzenia.
class PlayersStorage {
  static const _key = 'players';

  Future<List<Player>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = json.decode(raw) as List;
      return decoded
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Uszkodzone dane – zaczynamy od pustej listy zamiast się wywracać.
      return [];
    }
  }

  Future<void> save(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(players.map((p) => p.toJson()).toList()),
    );
  }
}
