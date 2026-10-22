import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Ikona z jednolitego zestawu gry (`assets/icons/game/*.svg`).
class GameIcon extends StatelessWidget {
  final String asset;
  final double size;

  const GameIcon(this.asset, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(asset, width: size, height: size);
  }
}
