/// Wersja do pokazania użytkownikowi. Wydania z GitHuba mają numer wersji
/// samą liczbą (np. „7") i pokazujemy je jako „v7", tak jak tag wydania.
/// Inne wersje (np. „0.1.0" z lokalnej kompilacji) zostają bez zmian.
String formatAppVersion(String version) =>
    RegExp(r'^\d+$').hasMatch(version) ? 'v$version' : version;

/// Wersja z datą budowy w nawiasie, np. „v19 (2026-11-14)". Bez daty (lokalna
/// kompilacja) zostaje sama wersja.
String withBuildDate(String version, String date) =>
    date.isEmpty ? version : '$version ($date)';
