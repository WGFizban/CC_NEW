import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Pokazuje podpowiedź jako dymek przy elemencie [context] (jak tooltip), który
/// zostaje na ekranie, dopóki użytkownik nie zamknie go przyciskiem „×" albo
/// nie stuknie w inne miejsce ekranu.
void showHintBubble(
  BuildContext context, {
  required String message,
  String? title,
}) {
  final overlay = Overlay.of(context);
  final box = context.findRenderObject() as RenderBox?;
  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
  if (box == null || overlayBox == null || !box.attached) {
    showHintDialog(context, message: message, title: title);
    return;
  }
  final anchor = box.localToGlobal(Offset.zero, ancestor: overlayBox);
  final anchorRect = anchor & box.size;
  final screen = overlayBox.size;
  final theme = Theme.of(context);

  late final OverlayEntry entry;
  void close() => entry.remove();

  entry = OverlayEntry(
    builder: (ctx) {
      const margin = 12.0;
      final width = screen.width - 2 * margin;
      // Dymek pod elementem, a gdy brakuje miejsca – nad nim.
      final below = anchorRect.bottom < screen.height * 0.55;
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: close,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: margin,
            width: width,
            top: below ? anchorRect.bottom + 4 : null,
            bottom: below ? null : screen.height - anchorRect.top + 4,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.inverseSurface,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screen.height * 0.45),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            message,
                            style: TextStyle(
                              color: theme.colorScheme.onInverseSurface,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: close,
                        tooltip: ctx.l10n.close,
                        icon: Icon(
                          Icons.close,
                          color: theme.colorScheme.onInverseSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  overlay.insert(entry);
}

/// Podpowiedź jako okno nad ekranem (zamykane przyciskiem). Używane, gdy nie
/// ma elementu, przy którym można pokazać dymek.
Future<void> showHintDialog(
  BuildContext context, {
  required String message,
  String? title,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: title == null ? null : Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.l10n.close),
        ),
      ],
    ),
  );
}

/// Mała ikona „?" otwierająca okno z podpowiedzią.
class InfoHint extends StatelessWidget {
  final String message;
  final String? title;

  const InfoHint(this.message, {super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () => showHintBubble(context, message: message, title: title),
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.help_outline,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Podpis z podpowiedzią „?" obok.
class LabelWithHint extends StatelessWidget {
  final String label;
  final String hint;
  final TextStyle? style;

  const LabelWithHint(this.label, this.hint, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    // Tekst z wbudowanym widżetem zawija się sam i nie wymaga ograniczonej
    // szerokości (w przeciwieństwie do Row z Flexible).
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: label),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: InfoHint(hint, title: label),
          ),
        ],
      ),
      style: style,
    );
  }
}
