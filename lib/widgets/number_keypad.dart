import 'dart:math' as math;

import 'package:flutter/material.dart';

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
                        vertical: 16,
                        horizontal: 20,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
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
