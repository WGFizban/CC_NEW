import 'package:flutter/material.dart';

/// Mała ikona „?" z podpowiedzią. Na telefonie podpowiedź pokazuje się po
/// dotknięciu, a na komputerze także po najechaniu myszą.
class InfoHint extends StatelessWidget {
  final String message;

  const InfoHint(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      waitDuration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
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
            child: InfoHint(hint),
          ),
        ],
      ),
      style: style,
    );
  }
}
