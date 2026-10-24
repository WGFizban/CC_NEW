import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';

/// Zapis historii punktów w pamięci urządzenia (najstarsze wpisy na początku).
class HistoryStorage {
  static const _key = 'history';

  /// Ile ostatnich wpisów przechowujemy.
  static const maxEntries = 500;

  Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return [
        for (final e in json.decode(raw) as List)
          HistoryEntry.fromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      // Uszkodzone dane – zaczynamy od pustej historii.
      return [];
    }
  }

  Future<void> save(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final kept = entries.length > maxEntries
        ? entries.sublist(entries.length - maxEntries)
        : entries;
    await prefs.setString(_key, json.encode([for (final e in kept) e.toJson()]));
  }
}
