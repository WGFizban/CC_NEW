import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MeepleIcon extends StatelessWidget {
  final Color color;
  final double size;

  const MeepleIcon({super.key, required this.color, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/meeple.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
