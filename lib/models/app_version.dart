/// Wersja do pokazania użytkownikowi. Wydania z GitHuba mają numer wersji
/// samą liczbą (np. „7") i pokazujemy je jako „v7", tak jak tag wydania.
/// Inne wersje (np. „0.1.0" z lokalnej kompilacji) zostają bez zmian.
String formatAppVersion(String version) =>
    RegExp(r'^\d+$').hasMatch(version) ? 'v$version' : version;
