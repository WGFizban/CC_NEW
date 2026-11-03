import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Nowa wartość po naciśnięciu klawisza: cyfra '0'–'9', 'C' (zerowanie)
/// albo '<' (kasowanie ostatniej cyfry). Wynik nie przekracza [max].
int applyKey(int value, String key, {int max = 999}) => switch (key) {
  'C' => 0,
  '<' => value ~/ 10,
  _ => math.min(value * 10 + int.parse(key), max),
};

/// Klawiatura numeryczna do wpisywania liczb.
class NumberKeypad extends StatelessWidget {
  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['C', '0', '<'],
  ];

  /// Kolory klawiszy specjalnych: bursztyn dla „C” (zerowanie) i błękit dla
  /// „<” (cofnięcie cyfry). To nasycone, jasne barwy, czytelne na ciemnym i
  /// jasnym motywie, a różne od czerwieni „Anuluj” i zieleni „Zatwierdź”.
  static const Color clearColor = Color(0xFFF2A93B);
  static const Color backspaceColor = Color(0xFF5BB5D6);

  static Color? _colorOf(String key) => switch (key) {
    'C' => clearColor,
    '<' => backspaceColor,
    _ => null,
  };

  final ValueChanged<String> onKey;

  /// Opcjonalny pasek bezpośrednio nad klawiszami (np. przełącznik pola).
  /// Ma dokładnie szerokość klawiszy i jest wyśrodkowany jak one.
  final Widget? top;

  const NumberKeypad({super.key, required this.onKey, this.top});

  /// Szerokość klawisza poza panelem z ograniczoną wysokością (domyślne
  /// minimum przycisku Material).
  static const double _defaultKeyWidth = 64;

  /// Wysokość paska [top] razem z odstępem.
  static const double _topHeight = 48;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // W ograniczonej wysokości (panel z boku w poziomie) klawisze dopasowują
        // się do miejsca: wypełniają panel, ale nie rosną bez końca. W pionie
        // wysokość jest nieograniczona i wygląd zostaje taki jak dotąd.
        final fitted = constraints.hasBoundedHeight;
        final available =
            constraints.maxHeight - (top == null ? 0 : _topHeight);
        final rowHeight = fitted
            ? ((available - 8 * _keys.length) / _keys.length).clamp(34.0, 72.0)
            : null;
        final keyWidth = fitted && constraints.hasBoundedWidth
            ? ((constraints.maxWidth - 16 - 8 * 3) / 3).clamp(56.0, 120.0)
            : _defaultKeyWidth;
        final fontSize = rowHeight != null && rowHeight >= 60 ? 22.0 : 18.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (top != null)
              Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  width: 3 * (keyWidth + 8) - 8,
                  child: top,
                ),
              ),
            for (final row in _keys)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final key in row)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: ElevatedButton(
                        onPressed: () => onKey(key),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: fitted ? 0 : 12,
                            horizontal: 20,
                          ),
                          minimumSize: Size(keyWidth, fitted ? rowHeight! : 40),
                          // Domyślny obszar dotyku (48 dp) podnosiłby klawisze
                          // ponad wyliczoną wysokość i powodował przepełnienie.
                          tapTargetSize: fitted
                              ? MaterialTapTargetSize.shrinkWrap
                              : null,
                          textStyle: TextStyle(fontSize: fontSize),
                          backgroundColor: _colorOf(key),
                          foregroundColor: _colorOf(key) == null
                              ? null
                              : foregroundOn(_colorOf(key)!),
                        ),
                        child: Text(key),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
