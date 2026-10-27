import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

/// Czerwień przycisków „Anuluj".
const Color kCancelColor = Color(0xFFC62828);

/// Zieleń przycisku „Zatwierdź".
const Color kConfirmColor = Color(0xFF2E9E44);

/// Dolny pasek ekranu punktowania: po lewej „Anuluj", po prawej „Zatwierdź"
/// (przygaszony, gdy [onConfirm] jest `null`), bez tytułu.
///
/// Ustawiany jako `Scaffold.bottomNavigationBar`, więc leży pod treścią,
/// a klawiatura numeryczna w treści ekranu wysuwa się nad nim i go nie
/// zasłania. Przyciski są w zasięgu kciuka na telefonie.
Widget scoringBottomBar(
  BuildContext context, {
  required VoidCallback? onConfirm,
  Color? backgroundColor,
  Color? foregroundColor,
}) {
  final l = context.l10n;
  final barColor =
      backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer;
  // Kolor czytelny na tle paska; z niego wynikają też obwódka i stan
  // nieaktywny, żeby przyciski nie znikały na żadnym kolorze gracza
  // ani w żadnym motywie.
  final onBar = foregroundColor ?? foregroundOn(barColor);
  final edge = BorderSide(color: onBar, width: 2);
  const buttonSize = Size.fromHeight(48);

  return Material(
    color: barColor,
    elevation: 8,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: kCancelColor,
                  foregroundColor: Colors.white,
                  side: edge,
                  minimumSize: buttonSize,
                  shape: const StadiumBorder(),
                ),
                child: Text(l.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: kConfirmColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: onBar.withValues(alpha: 0.14),
                  disabledForegroundColor: onBar.withValues(alpha: 0.75),
                  side: onConfirm == null
                      ? edge.copyWith(color: onBar.withValues(alpha: 0.75))
                      : edge,
                  minimumSize: buttonSize,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.check),
                label: Text(l.confirm),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
