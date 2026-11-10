import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/expansion.dart';
import '../models/fairy.dart';
import '../models/monastery.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../models/scoring.dart';
import '../theme/app_colors.dart';
import '../widgets/info_hint.dart';
import '../widgets/number_keypad.dart';
import '../widgets/meeple_header.dart';
import '../widgets/meeple_icon.dart';
import '../widgets/adaptive_layout.dart';
import '../widgets/scoring_app_bar.dart';

/// Punkty opata z klasztoru liniowego (dodatek „Klasztory niemieckie
/// i holenderskie"): jedno pole z klawiaturą na punkty końcowe.
class MonasteryScreen extends StatefulWidget {
  final Player player;
  final List<Player> players;
  final Set<Expansion> expansions;

  const MonasteryScreen({
    super.key,
    required this.player,
    this.players = const [],
    this.expansions = const {},
  });

  @override
  State<MonasteryScreen> createState() => _MonasteryScreenState();
}

class _MonasteryScreenState extends State<MonasteryScreen> {
  int _line = 0;
  bool _fairy = false;

  /// Gracze, którzy dostają te same punkty (maszyny latające: kilku opatów
  /// w jednym klasztorze).
  final Set<Player> _shared = {};

  bool get _showSharing =>
      widget.expansions.contains(Expansion.flyingMachines) &&
      _others.isNotEmpty;

  List<Player> get _others => [
    for (final p in widget.players)
      if (p != widget.player) p,
  ];

  bool get _showFairy => widget.expansions.contains(Expansion.princessDragon);

  /// Punkty opata plus 3 pkt za wróżkę przy jego meplu.
  int get _points =>
      _line + (_showFairy && _fairy ? kFairyFeaturePoints : 0);

  void _confirm() {
    final l = context.l10n;
    final sharing = [
      for (final p in _others)
        if (_showSharing && _shared.contains(p)) p,
    ];
    Navigator.pop(
      context,
      ScoreEvent(
        l.monasteryEventLabel(widget.player.name, _points) +
            (sharing.isEmpty
                ? ''
                : ' · ${l.wordShared}: ${sharing.map((p) => p.name).join(', ')}'),
        [
          ScoreChange(widget.player, _points),
          // Wróżka stoi przy jednym meplu, więc współdzielący jej nie mają.
          for (final p in sharing) ScoreChange(p, _line),
        ],
        category: l.scMonastery,
        type: ScoringType.monastery,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = widget.player.color;
    final frameColor =
        visibleOn(color, Theme.of(context).scaffoldBackgroundColor);
    final frameSide = BorderSide(color: frameColor, width: 4);

    return Scaffold(
      bottomNavigationBar: scoringBottomBar(
        context,
        onConfirm: _points > 0 ? _confirm : null,
        frameColor: frameColor,
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: frameSide,
            left: frameSide,
            right: frameSide,
          ),
        ),
        child: KeypadLayout(
          form: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LabelWithHint(
                l.monasteryPointsLabel,
                l.monasteryHint,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              MeepleHeader(
                color: color,
                size: 48,
                child: Text(
                  '$_points',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_showFairy)
                CheckboxListTile(
                  title: LabelWithHint(
                    l.fairyOption,
                    l.fairyHint(kFairyFeaturePoints),
                  ),
                  value: _fairy,
                  onChanged: (v) => setState(() => _fairy = v ?? false),
                ),
              if (_showSharing)
                ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: EdgeInsets.zero,
                  title: LabelWithHint(
                    l.sharedPoints,
                    l.monasterySharedHint,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    for (final p in _others)
                      CheckboxListTile(
                        secondary: MeepleIcon(color: p.color, size: 28),
                        title: Text(p.name),
                        value: _shared.contains(p),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _shared.add(p);
                          } else {
                            _shared.remove(p);
                          }
                        }),
                      ),
                  ],
                ),
            ],
          ),
          keypad: (side) => keypadBlock(
            side: side,
            onKey: (k) => setState(
              () => _line = applyKey(_line, k, max: kMaxMonasteryPoints),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
