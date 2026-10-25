import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/tr.dart';
import 'screens/players_screen.dart';
import 'services/settings_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Motyw i język czytamy przed pierwszą klatką, żeby nic nie migało.
  try {
    final settings = await SettingsStorage().load();
    appThemeMode.value = settings.themeMode;
    appLanguage.value = settings.language;
  } catch (_) {
    // Zostają ustawienia domyślne.
  }
  runApp(const CarcassonneCounterApp());
}

class CarcassonneCounterApp extends StatelessWidget {
  const CarcassonneCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => ValueListenableBuilder<ThemeMode>(
        valueListenable: appThemeMode,
        builder: (context, mode, _) => MaterialApp(
          title: 'CarcassonneCounter',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: mode,
          locale: Locale(language.code),
          supportedLocales: [
            for (final l in AppLanguage.values) Locale(l.code),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const PlayersScreen(),
        ),
      ),
    );
  }
}
