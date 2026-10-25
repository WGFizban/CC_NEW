import 'package:flutter/material.dart';

/// Główny kolor aplikacji (lawenda) – używany w motywie, kartach i tle mepla.
const Color kBrandColor = Color(0xFFBDABFB);

/// Kolory mepli dostępne do wyboru bez otwierania palety.
const List<Color> kPlayerColors = [
  Color(0xFF1D27EA), // niebieski
  Color(0xFF078E04), // zielony
  Color(0xFFCC1B1B), // czerwony
  Color(0xFF070707), // czarny
  Color(0xFFFFFFFF), // biały
  Color(0xFFF0F811), // żółty
  Color(0xFFFA8612), // pomarańczowy
  Color(0xFF8C1AFF), // fioletowy
  Color(0xFFFF42FF), // różowy
  Color(0xFF7E7777), // szary
];

/// Kolor ramki gracza widoczny na tle [background]: gdy kolor gracza jest
/// zbyt podobny do tła (np. biały na białym, czarny na ciemnym), zwraca
/// kontrastowy szary.
Color visibleOn(Color color, Color background) {
  final diff = (color.computeLuminance() - background.computeLuminance()).abs();
  return diff < 0.2 ? foregroundOn(background).withValues(alpha: 0.6) : color;
}

/// Kolor tekstu/ikon czytelny na podanym tle (jasne tło → czarny, ciemne → biały).
Color foregroundOn(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black;
