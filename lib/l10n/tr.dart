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

/// Aktualny język. Zmiana odświeża `MaterialApp`; ekrany, które są już
/// otwarte, odświeżają się same przy własnym `setState`.
final ValueNotifier<AppLanguage> appLanguage = ValueNotifier(AppLanguage.pl);

/// Tekst w aktualnym języku: [pl] po polsku, [en] po angielsku.
String tr(String pl, String en) =>
    appLanguage.value == AppLanguage.en ? en : pl;
