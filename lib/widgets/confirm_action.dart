import 'package:flutter/material.dart';

/// Duża fajka zatwierdzająca w prawym górnym rogu paska (`AppBar.actions`).
/// Gdy [onPressed] jest `null`, przycisk jest wyszarzony.
class ConfirmAction extends StatelessWidget {
  final VoidCallback? onPressed;

  const ConfirmAction({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton.filled(
        onPressed: onPressed,
        tooltip: 'Zatwierdź',
        iconSize: 30,
        icon: const Icon(Icons.check),
      ),
    );
  }
}
