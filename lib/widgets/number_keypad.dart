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

  const NumberKeypad({super.key, required this.onKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
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
  }
}
