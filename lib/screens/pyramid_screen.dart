import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/tr.dart';
import '../models/circus.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../widgets/confirm_action.dart';
import '../widgets/info_hint.dart';
import '../widgets/player_counter_tile.dart';
import '../widgets/pyramid_view.dart';

enum _PyramidMode { completed, endGame }

/// Punktowanie akrobatów.
///
/// - **Ukończona piramida**: trzech mepli (dowolnych kolorów) na płytce
///   akrobatów. Każdy akrobata daje właścicielowi 5 pkt i wraca do puli.
///   Piramidę można podliczyć, nawet nie mając w niej akrobaty.
/// - **Koniec gry**: każdy akrobata na planszy daje 5 pkt, niezależnie od
///   wielkości piramidy.
class PyramidScreen extends StatefulWidget {
  final List<Player> players;

  const PyramidScreen({super.key, required this.players});

  @override
  State<PyramidScreen> createState() => _PyramidScreenState();
}

class _PyramidScreenState extends State<PyramidScreen> {
  /// Każdy gracz ma 7 mepli, więc tylu akrobatów może mieć najwyżej.
  static const _maxPerPlayer = 7;

  _PyramidMode _mode = _PyramidMode.completed;
  late final Map<Player, int> _acrobats = {
    for (final p in widget.players) p: 0,
  };

  int get _total => _acrobats.values.fold(0, (a, b) => a + b);

  bool get _isCompleted => _mode == _PyramidMode.completed;

  int _maxFor(Player p) {
    if (!_isCompleted) return _maxPerPlayer;
    final others = _total - (_acrobats[p] ?? 0);
    return math.max(0, math.min(kPyramidSize - others, _maxPerPlayer));
  }

  List<Color?> get _slots {
    final colors = <Color?>[];
    for (final p in widget.players) {
      for (var i = 0; i < (_acrobats[p] ?? 0); i++) {
        colors.add(p.color);
      }
    }
    while (colors.length < kPyramidSize) {
      colors.add(null);
    }
    return colors.take(kPyramidSize).toList();
  }

  bool get _canConfirm =>
      _isCompleted ? _total == kPyramidSize : _total > 0;

  void _setMode(_PyramidMode mode) {
    setState(() {
      _mode = mode;
      for (final p in widget.players) {
        _acrobats[p] = 0;
      }
    });
  }

  void _confirm() {
    final changes = [
      for (final p in widget.players)
        if ((_acrobats[p] ?? 0) > 0)
          ScoreChange(p, acrobatPoints(_acrobats[p] ?? 0)),
    ];
    Navigator.pop(
      context,
      ScoreEvent(
        _isCompleted
            ? tr('Piramida akrobatów', 'Acrobat pyramid')
            : tr('Akrobaci (koniec gry)', 'Acrobats (end of game)'),
        changes,
        category: tr('Akrobaci', 'Acrobats'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Akrobaci', 'Acrobats')),
        actions: [ConfirmAction(onPressed: _canConfirm ? _confirm : null)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<_PyramidMode>(
            segments: [
              ButtonSegment(
                value: _PyramidMode.completed,
                label: Text(tr('Ukończona piramida', 'Completed pyramid')),
              ),
              ButtonSegment(
                value: _PyramidMode.endGame,
                label: Text(tr('Koniec gry', 'End of game')),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => _setMode(s.first),
          ),
          const SizedBox(height: 12),
          LabelWithHint(
            _isCompleted
                ? tr(
                    'Czyje są trzy meple w piramidzie?',
                    'Whose are the three meeples in the pyramid?',
                  )
                : tr(
                    'Ilu akrobatów ma każdy gracz?',
                    'How many acrobats does each player have?',
                  ),
            _isCompleted
                ? tr(
                    'Każdy akrobata w ukończonej piramidzie daje właścicielowi '
                        '$kAcrobatPoints pkt i wraca do puli. Piramidę możesz '
                        'podliczyć, nawet jeśli nie masz w niej akrobaty.',
                    'Each acrobat in a completed pyramid gives its owner '
                        '$kAcrobatPoints pts and returns to the supply. You '
                        'can score the pyramid even without an acrobat in it.',
                  )
                : tr(
                    'Na koniec gry każdy akrobata na planszy daje '
                        '$kAcrobatPoints pkt, także w niedokończonej piramidzie.',
                    'At the end of the game each acrobat on the board gives '
                        '$kAcrobatPoints pts, even in an unfinished pyramid.',
                  ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (_isCompleted) ...[
            const SizedBox(height: 12),
            Center(child: PyramidView(slots: _slots)),
          ],
          const SizedBox(height: 12),
          for (final p in widget.players)
            PlayerCounterTile(
              player: p,
              value: _acrobats[p] ?? 0,
              max: _maxFor(p),
              caption: '= ${acrobatPoints(_acrobats[p] ?? 0)} ${tr('pkt', 'pts')}',
              onChanged: (v) => setState(() => _acrobats[p] = v),
            ),
          if (_isCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${tr('Meple w piramidzie', 'Meeples in the pyramid')}: '
                '$_total / $kPyramidSize',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
