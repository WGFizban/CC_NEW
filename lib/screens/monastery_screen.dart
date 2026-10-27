import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/monastery.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../models/scoring.dart';
import '../theme/app_colors.dart';
import '../widgets/info_hint.dart';
import '../widgets/number_keypad.dart';
import '../widgets/meeple_header.dart';
import '../widgets/scoring_app_bar.dart';

/// Punkty opata z klasztoru liniowego (dodatek „Klasztory niemieckie
/// i holenderskie"): jedno pole z klawiaturą na punkty końcowe.
class MonasteryScreen extends StatefulWidget {
  final Player player;

  const MonasteryScreen({super.key, required this.player});

  @override
  State<MonasteryScreen> createState() => _MonasteryScreenState();
}

class _MonasteryScreenState extends State<MonasteryScreen> {
  int _points = 0;

  void _confirm() {
    final l = context.l10n;
    Navigator.pop(
      context,
      ScoreEvent(
        l.monasteryEventLabel(widget.player.name, _points),
        [ScoreChange(widget.player, _points)],
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
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
                ],
              ),
            ),
            NumberKeypad(
              onKey: (k) => setState(
                () => _points = applyKey(_points, k, max: kMaxMonasteryPoints),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      ),
    );
  }
}
