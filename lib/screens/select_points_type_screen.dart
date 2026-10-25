import 'package:flutter/material.dart';

import '../l10n/tr.dart';
import '../models/expansion.dart';
import '../models/player.dart';
import '../models/scoring.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
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

  /// Typy pogrupowane według dodatku: gra podstawowa pierwsza, potem dodatki
  /// według numeracji, a mini dodatki na końcu.
  List<(String, List<ScoringType>)> _groups() {
    final groups = <Expansion?, List<ScoringType>>{};
    for (final t in types) {
      (groups[t.expansion] ??= []).add(t);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == null || b == null) return a == null ? (b == null ? 0 : -1) : 1;
        if (a.mini != b.mini) return a.mini ? 1 : -1;
        return a.number.compareTo(b.number);
      });
    return [
      for (final k in keys)
        (k?.displayName ?? tr('Gra podstawowa', 'Base game'), groups[k]!),
    ];
  }

  List<Widget> _buildGroup(
    BuildContext context,
    String title,
    List<ScoringType> group,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final type in group)
            _TypeButton(type: type, onTap: () => Navigator.pop(context, type)),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final color = player.color;

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr('Dodaj punkty', 'Add points')}: ${player.name}'),
        backgroundColor: color,
        foregroundColor: foregroundOn(color),
      ),
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: color, width: 4)),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              tr('Wybierz rodzaj punktacji:', 'Choose what to score:'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  for (final group in _groups())
                    ..._buildGroup(context, group.$1, group.$2),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('Anuluj', 'Cancel')),
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
          border: Border.all(color: outlineSoft(context), width: 2),
          color: tileSurfaceColor(context),
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
