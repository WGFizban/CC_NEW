import 'package:flutter/material.dart';

import 'meeple_icon.dart';

/// Piramida z trzech mepli: dwóch na dole i jednego na górze.
///
/// [slots] to kolory kolejnych miejsc (dół-lewo, dół-prawo, góra);
/// `null` oznacza puste miejsce.
class PyramidView extends StatelessWidget {
  final List<Color?> slots;
  final double size;

  const PyramidView({super.key, required this.slots, this.size = 56});

  Widget _slot(int index) {
    final color = index < slots.length ? slots[index] : null;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: MeepleIcon(color: color ?? Colors.black26, size: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _slot(2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [_slot(0), _slot(1)],
        ),
      ],
    );
  }
}
