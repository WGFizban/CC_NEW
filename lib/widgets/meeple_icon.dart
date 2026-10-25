import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MeepleIcon extends StatelessWidget {
  final Color color;
  final double size;

  const MeepleIcon({super.key, required this.color, this.size = 60});

  @override
  Widget build(BuildContext context) {
    // Obrys w kolorze kontrastowym (biały dla ciemnych mepli, czarny dla
    // jasnych), żeby mepel nie zlewał się z tłem.
    final outline = ThemeData.estimateBrightnessForColor(color) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;
    SvgPicture meeple(Color c, double scale) => SvgPicture.asset(
      'assets/icons/meeple.svg',
      width: size * scale,
      height: size * scale,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [meeple(outline, 1.08), meeple(color, 0.94)],
      ),
    );
  }
}
