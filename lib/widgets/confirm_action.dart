import 'package:flutter/material.dart';

import '../l10n/tr.dart';

/// Duża fajka zatwierdzająca w prawym górnym rogu paska (`AppBar.actions`).
/// Jest zielona, żeby wyróżniała się w pasku. Gdy [onPressed] jest `null`,
/// przycisk jest wyszarzony.
class ConfirmAction extends StatelessWidget {
  final VoidCallback? onPressed;

  const ConfirmAction({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF2E9E44),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black12,
        ),
        tooltip: tr('Zatwierdź', 'Confirm'),
        iconSize: 30,
        icon: const Icon(Icons.check),
      ),
    );
  }
}
