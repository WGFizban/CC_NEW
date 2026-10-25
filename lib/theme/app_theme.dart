import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Wybrany motyw: zgodny z systemem, jasny albo ciemny.
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.system);

ThemeData buildTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: kBrandColor,
    brightness: brightness,
  ),
  useMaterial3: true,
);

bool isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

/// Tło karty gracza na liście (lawenda; w trybie ciemnym przygaszona).
Color playerCardColor(BuildContext context) => isDark(context)
    ? const Color(0xFF665CA0)
    : kBrandColor.withValues(alpha: 180 / 255);

/// Tło kafelka wyboru punktacji.
Color tileSurfaceColor(BuildContext context) => isDark(context)
    ? Theme.of(context).colorScheme.surfaceContainerHigh
    : Colors.white;

/// Półprzezroczyste tło odznak (surowce, złoto).
Color badgeColor(BuildContext context) =>
    isDark(context) ? Colors.white12 : Colors.white54;

/// Kolor obramowań pomocniczych.
Color outlineSoft(BuildContext context) =>
    isDark(context) ? Colors.white30 : Colors.black26;
