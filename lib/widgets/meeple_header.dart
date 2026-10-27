import 'package:flutter/material.dart';

import 'meeple_icon.dart';

/// Nagłówek z meplem punktującego gracza po obu stronach treści:
/// [mepel] [child] [mepel]. Pokazuje, czyje punkty są właśnie liczone.
class MeepleHeader extends StatelessWidget {
  final Color color;
  final Widget child;
  final double size;

  const MeepleHeader({
    super.key,
    required this.color,
    required this.child,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MeepleIcon(color: color, size: size),
        Expanded(child: Center(child: child)),
        MeepleIcon(color: color, size: size),
      ],
    );
  }
}
