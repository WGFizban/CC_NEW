import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Skrót do tekstów w aktualnym języku: `context.l10n.cancel`.
///
/// Teksty są w plikach `app_pl.arb` (wzorzec) i `app_en.arb`; klasa
/// `AppLocalizations` jest z nich generowana przez `flutter gen-l10n`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
