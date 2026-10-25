import 'package:flutter/material.dart';

/// Tekst, który zmniejsza czcionkę (do [minFontSize]), aż zmieści się w
/// [maxLines] liniach. Zawija się na znakach nowej linii.
class AutoSizeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final double minFontSize;
  final TextAlign? textAlign;

  const AutoSizeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.minFontSize = 10,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(
      builder: (context, constraints) {
        var size = base.fontSize ?? 14;
        if (constraints.maxWidth.isFinite) {
          while (size > minFontSize &&
              _lines(base.copyWith(fontSize: size), constraints.maxWidth) >
                  maxLines) {
            size -= 1;
          }
        }
        return Text(
          text,
          style: base.copyWith(fontSize: size),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
        );
      },
    );
  }

  int _lines(TextStyle s, double width) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: s),
      textDirection: TextDirection.ltr,
      textAlign: textAlign ?? TextAlign.start,
    )..layout(maxWidth: width);
    final n = painter.computeLineMetrics().length;
    painter.dispose();
    return n;
  }
}

/// Tytuł paska aplikacji, który mieści się także na małych ekranach.
class AppBarTitle extends StatelessWidget {
  final String text;
  final int maxLines;

  final TextAlign? textAlign;

  const AppBarTitle(
    this.text, {
    super.key,
    this.maxLines = 2,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    // Kolor bierzemy z paska (DefaultTextStyle), żeby tekst był czytelny na
    // tle w dowolnym kolorze; ustawiamy tylko rozmiar i grubość.
    return AutoSizeText(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      maxLines: maxLines,
      minFontSize: 12,
      textAlign: textAlign,
    );
  }
}
