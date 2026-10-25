import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Pasek ekranu punktowania: po lewej przycisk „Anuluj", po prawej
/// „Zatwierdź" (wyszarzony, gdy [onConfirm] jest `null`), bez tytułu.
AppBar scoringAppBar(
  BuildContext context, {
  required VoidCallback? onConfirm,
  Color? backgroundColor,
  Color? foregroundColor,
}) {
  final l = context.l10n;
  return AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    leadingWidth: 130,
    leading: Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor,
            side: BorderSide(
              color: foregroundColor ?? Theme.of(context).colorScheme.outline,
            ),
            shape: const StadiumBorder(),
          ),
          child: Text(l.cancel),
        ),
      ),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilledButton.icon(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E9E44),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.black12,
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.check),
          label: Text(l.confirm),
        ),
      ),
    ],
  );
}
