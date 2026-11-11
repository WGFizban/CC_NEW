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
import '../widgets/player_label.dart';
import '../widgets/player_picker.dart';
import '../widgets/meeple_header.dart';
import '../widgets/meeple_icon.dart';
import '../widgets/adaptive_layout.dart';
import '../widgets/scoring_app_bar.dart';

/// Punkty opata z klasztoru niemieckiego lub holenderskiego (dodatek „Klasztory niemieckie
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
  final _keypadOpen = ValueNotifier<bool>(true);

  /// Wróżka przy meplu innego gracza (maszyny latające: kilku opatów w jednym
  /// klasztorze); `null` = przy meplu punktującego.
  Player? _fairyOwner;

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

  bool get _fairyOn => _showFairy && _fairy;

  /// Wskazanie właściciela wróżki ma sens tylko przy kilku opatach.
  bool get _pickFairyOwner => _fairyOn && _showSharing;

  bool get _fairyForScorer => !_pickFairyOwner || _fairyOwner == null;

  /// Punkty opata plus 3 pkt za wróżkę, jeśli stoi przy jego meplu.
  int get _points => _line + (_fairyOn && _fairyForScorer ? kFairyFeaturePoints : 0);

  bool get _canConfirm => _line + (_fairyOn ? kFairyFeaturePoints : 0) > 0;

  @override
  void dispose() {
    _keypadOpen.dispose();
    super.dispose();
  }

  List<Player> get _sharing => [
    for (final p in _others)
      if (_showSharing && _shared.contains(p)) p,
  ];

  /// Punkty każdego gracza (punktujący pierwszy): opat, współdzielący
  /// i właściciel wróżki stojącej przy cudzym meplu.
  Map<Player, int> get _distribution {
    final owner = _pickFairyOwner ? _fairyOwner : null;
    final points = <Player, int>{
      widget.player: _points,
      for (final p in _sharing) p: _line,
    };
    if (owner != null) {
      points[owner] = (points[owner] ?? 0) + kFairyFeaturePoints;
    }
    return points;
  }

  void _confirm() {
    final l = context.l10n;
    final sharing = _sharing;
    final owner = _pickFairyOwner ? _fairyOwner : null;
    Navigator.pop(
      context,
      ScoreEvent(
        l.monasteryEventLabel(widget.player.name, _points) +
            (sharing.isEmpty
                ? ''
                : ' · ${l.wordShared}: ${sharing.map((p) => p.name).join(', ')}') +
            (owner == null ? '' : ' · ${l.scFairy}: ${owner.name}'),
        [for (final e in _distribution.entries) ScoreChange(e.key, e.value)],
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
    final distribution = _distribution;

    return Scaffold(
      bottomNavigationBar: scoringBottomBar(
        context,
        onConfirm: _canConfirm ? _confirm : null,
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
        child: CollapsibleKeypadLayout(
          open: _keypadOpen,
          onKey: (k) => setState(
            () => _line = applyKey(_line, k, max: kMaxMonasteryPoints),
          ),
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
              // Stuknięcie w wynik wysuwa klawiaturę.
              GestureDetector(
                onTap: () => _keypadOpen.value = true,
                child: MeepleHeader(
                  color: color,
                  size: 48,
                  child: Column(
                    children: [
                      Text(
                        '$_points',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (distribution.length > 1)
                        // Pod wynikiem: mepel w kolorze gracza i jego punkty
                        // z podziału (współdzielenie, wróżka), jak na innych
                        // ekranach punktowania.
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: PlayerLabels(
                            alignment: WrapAlignment.center,
                            items: [
                              for (final e in distribution.entries)
                                if (e.key != widget.player)
                                  (
                                    player: e.key,
                                    text: '${e.key.name} +${e.value}',
                                  ),
                            ],
                            empty: '',
                          ),
                        ),
                    ],
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
              // Wróżka może stać przy meplu innego opata.
              if (_pickFairyOwner) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Text(l.fairyOwner),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PlayerPicker(
                      players: widget.players,
                      selected: _fairyOwner ?? widget.player,
                      onSelected: (p) => setState(
                        () => _fairyOwner = p == widget.player ? null : p,
                      ),
                    ),
                  ),
                ),
              ],
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
                  // Wybrani gracze widać w podtytule także po zwinięciu.
                  subtitle: PlayerLabels(
                    items: [
                      for (final p in _sharing) (player: p, text: p.name),
                    ],
                    empty: l.none,
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
        ),
      ),
      ),
    );
  }
}
