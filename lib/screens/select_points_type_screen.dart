import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../models/expansion.dart';
import '../models/player.dart';
import '../models/scoring.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_layout.dart';
import '../widgets/auto_size_text.dart';
import '../widgets/game_dialogs.dart' show EndPhaseBadge;
import '../widgets/game_icon.dart';
import '../widgets/meeple_header.dart';
import '../widgets/scoring_app_bar.dart' show kCancelColor;

/// Wybór rodzaju punktacji. Zwraca wybrany [ScoringType] przez `Navigator.pop`.
class SelectPointsTypeScreen extends StatelessWidget {
  final Player player;

  /// Typy dostępne przy włączonych dodatkach.
  final List<ScoringType> types;

  /// Czy pokazywać tytuły dodatków nad kafelkami.
  final bool showGroupTitles;

  /// Czy każdy dodatek zaczyna się od nowej linii (inaczej kafelki płyną).
  final bool groupsOnNewLines;

  /// Punktowanie końcowe (po ostatniej płytce). W trakcie gry kafelek pola ma
  /// obrazek stodoły, bo tylko stodoła punktuje pole przed końcem gry.
  final bool endPhase;

  const SelectPointsTypeScreen({
    super.key,
    required this.player,
    required this.types,
    this.showGroupTitles = true,
    this.groupsOnNewLines = false,
    this.endPhase = false,
  });

  /// Typy pogrupowane według dodatku: gra podstawowa pierwsza, potem dodatki
  /// według numeracji, a mini dodatki na końcu.
  List<(String, List<ScoringType>)> _groups(AppLocalizations l) {
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
        (k?.title(l) ?? l.baseGame, groups[k]!),
    ];
  }

  /// Wysokość miejsca na tytuł grupy nad kafelkami (dwie linie).
  static const double _titleHeight = 40;
  static const double _gap = 12;

  /// Domyślnie grupy płyną jedna za drugą w tych samych rzędach (przy
  /// [groupsOnNewLines] każda zaczyna nową linię): dodatek z jednym
  /// kafelkiem zajmuje jedno miejsce i ma tytuł nad sobą, a większy (np. cyrk)
  /// zajmuje kilka. Kolejna grupa zaczyna się zaraz za ostatnim kafelkiem
  /// poprzedniej, jeśli w rzędzie jest jeszcze miejsce.
  Widget _buildFlow(BuildContext context, double width, AppLocalizations l) {
    // Co najmniej trzy kolumny (telefon w pionie); na szerszym ekranie przybywa
    // kolumn zamiast rozciągania kafelków.
    final cols = ((width + _gap) / (130 + _gap)).floor().clamp(3, 12);
    final tile = (width - _gap * (cols - 1)) / cols;
    final primary = Theme.of(context).colorScheme.primary;

    Widget chunk(String? title, List<ScoringType> types) {
      final w = types.length * tile + (types.length - 1) * _gap;
      return SizedBox(
        width: w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              SizedBox(
                // Tytuł jest wyśrodkowany nad pierwszym kafelkiem grupy.
                width: tile,
                height: _titleHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  ),
                ),
              ),
            Wrap(
              spacing: _gap,
              children: [
                for (final type in types)
                  SizedBox(
                    width: tile,
                    height: tile,
                    child: _TypeButton(
                      type: type,
                      barnBadge: !endPhase && type == ScoringType.meadow,
                      onTap: () => Navigator.pop(context, type),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    final chunks = <Widget>[];
    for (final (title, group) in _groups(l)) {
      for (var i = 0; i < group.length; i += cols) {
        chunks.add(
          chunk(
            i == 0 && showGroupTitles ? title : null,
            group.sublist(i, (i + cols).clamp(0, group.length)),
          ),
        );
      }
      // Pusty element na całą szerokość wymusza początek kolejnego dodatku
      // w nowej linii.
      if (groupsOnNewLines) chunks.add(SizedBox(width: width));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: _gap,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: chunks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = player.color;
    // W poziomie na telefonie wysokość jest mała, więc oszczędzamy miejsce na
    // kafelki: bez osobnego nagłówka „Wybierz rodzaj punktacji”.
    final compact = MediaQuery.sizeOf(context).height < 480;

    return Scaffold(
      // Ramka w kolorze gracza obejmuje cały ekran, razem z tytułem;
      // poza nią kolor gracza występuje tylko w meplach.
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  visibleOn(color, Theme.of(context).scaffoldBackgroundColor),
              width: 4,
            ),
          ),
          padding: EdgeInsets.all(compact ? 8 : 16),
          child: ContentWidth(
            child: Column(
            children: [
              MeepleHeader(
                color: color,
                size: compact ? 32 : 44,
                child: AppBarTitle(
                  // Niski ekran: tytuł w jednym wierszu, żeby zostało miejsce
                  // na kafelki.
                  compact
                      ? l.addPointsTitle(player.name).replaceAll('\n', ' ')
                      : l.addPointsTitle(player.name),
                  maxLines: compact ? 1 : 2,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: compact ? 8 : 16),
            if (endPhase) ...[
              EndPhaseBadge(l.endPhaseLabel),
              SizedBox(height: compact ? 8 : 12),
            ],
            if (!compact) ...[
              Text(
                l.chooseScoring,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => ListView(
                  children: [_buildFlow(context, c.maxWidth, l)],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: kCancelColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size.fromHeight(compact ? 40 : 52),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(l.cancel),
              ),
            ),
          ],
        ),
        ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final ScoringType type;
  final VoidCallback onTap;

  /// Ikona pola ze stodołą w rogu (pole w trakcie gry).
  final bool barnBadge;

  const _TypeButton({
    required this.type,
    required this.onTap,
    this.barnBadge = false,
  });

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
                  child: FittedBox(
                    child: GameIcon(
                      barnBadge
                          ? 'assets/icons/game/meadow_barn.svg'
                          : type.iconAsset,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  type.title(context.l10n),
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
