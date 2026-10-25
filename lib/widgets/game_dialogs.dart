import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Ikona kończąca grę (ta sama na przycisku i w komunikacie o starcie).
const IconData kEndGameIcon = Icons.sports_score;

/// Okno z pytaniem i odpowiedziami Tak / Nie. Zwraca `true` po „Tak".
Future<bool> askYesNo(
  BuildContext context, {
  required String title,
  String? message,
}) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.no),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.yes),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Komunikat o rozpoczęciu gry z grafiką przycisku kończącego grę.
Future<void> showGameStartedNote(BuildContext context) {
  final l = context.l10n;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      content: SingleChildScrollView(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${l.gameStartedBefore} '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(kEndGameIcon, size: 22),
                ),
              ),
              TextSpan(text: '\n\n${l.gameStartedAfter}'),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.ok),
        ),
      ],
    ),
  );
}
