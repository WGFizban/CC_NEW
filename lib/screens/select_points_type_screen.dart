import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/scoring.dart';
import '../theme/app_colors.dart';
import '../widgets/game_icon.dart';

/// Wybór rodzaju punktacji. Zwraca wybrany [ScoringType] przez `Navigator.pop`.
class SelectPointsTypeScreen extends StatelessWidget {
  final Player player;

  /// Typy dostępne przy włączonych dodatkach.
  final List<ScoringType> types;

  const SelectPointsTypeScreen({
    super.key,
    required this.player,
    required this.types,
  });

  @override
  Widget build(BuildContext context) {
    final color = player.color;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dodaj punkty: ${player.name}'),
        backgroundColor: color,
        foregroundColor: foregroundOn(color),
      ),
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: color, width: 4)),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Wybierz rodzaj punktacji:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final type in types)
                    _TypeButton(
                      type: type,
                      onTap: () => Navigator.pop(context, type),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final ScoringType type;
  final VoidCallback onTap;

  const _TypeButton({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black26, width: 2),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kBrandColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: FittedBox(child: GameIcon(type.iconAsset, size: 64)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  type.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
