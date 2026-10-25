import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

/// Czerwień przycisków „Anuluj".
const Color kCancelColor = Color(0xFFC62828);

/// Pasek ekranu punktowania: po lewej przycisk „Anuluj", po prawej
/// „Zatwierdź" (wyszarzony, gdy [onConfirm] jest `null`), bez tytułu.
AppBar scoringAppBar(
  BuildContext context, {
  required VoidCallback? onConfirm,
  Color? backgroundColor,
  Color? foregroundColor,
}) {
  final l = context.l10n;
  // Obwódka w kolorze kontrastowym do tła paska, żeby czerwony i zielony
  // przycisk nie znikały na tle w podobnym kolorze (np. zielony gracz).
  final barColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
  final edge = BorderSide(color: foregroundOn(barColor), width: 2);
  return AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    leadingWidth: 130,
    leading: Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: kCancelColor,
            foregroundColor: Colors.white,
            side: edge,
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
            side: edge,
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.check),
          label: Text(l.confirm),
        ),
      ),
    ],
  );
}
