import 'package:flutter/material.dart';

import 'l10n/app_language.dart';
import 'l10n/l10n.dart';
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
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          // Na Androidzie z pełnoekranowym układem (edge-to-edge) dolne przyciski
          // systemu zasłaniałyby treść. SafeArea odsuwa wszystkie ekrany od
          // dolnego paska, a tło pod nim ma kolor motywu.
          builder: (context, child) => ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
          home: const PlayersScreen(),
        ),
      ),
    );
  }
}
