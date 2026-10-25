import 'package:flutter/foundation.dart';

/// Język interfejsu aplikacji.
enum AppLanguage {
  pl('pl', 'Polski'),
  en('en', 'English');

  const AppLanguage(this.code, this.nativeName);

  final String code;

  /// Nazwa języka w nim samym (do wyboru w ustawieniach).
  final String nativeName;

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => pl);
}

/// Aktualny język. Zmiana odświeża `MaterialApp` (jego `locale`), a ekrany
/// biorą teksty z `AppLocalizations`.
final ValueNotifier<AppLanguage> appLanguage = ValueNotifier(AppLanguage.pl);
