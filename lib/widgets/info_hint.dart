import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Pokazuje podpowiedź jako okno nad ekranem, które użytkownik zamyka sam.
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
      onTap: () => showHintDialog(context, message: message, title: title),
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
