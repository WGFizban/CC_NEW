import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/models/player.dart';

void main() {
  test('Player zachowuje dane po zapisie i odczycie JSON', () {
    final player = Player(
      name: 'Ala',
      color: const Color(0xFF1D27EA),
      points: 42,
    );

    final restored = Player.fromJson(player.toJson());

    expect(restored.name, 'Ala');
    expect(restored.color, const Color(0xFF1D27EA));
    expect(restored.points, 42);
  });

  test('brak punktów w JSON oznacza 0', () {
    final restored = Player.fromJson({'name': 'Ola', 'color': 0xFF078E04});

    expect(restored.points, 0);
  });
}
