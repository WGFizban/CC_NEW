import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../models/circus.dart';
import '../models/expansion.dart';
import '../models/fairy.dart';
import '../models/gold.dart';
import '../models/goods.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../models/scoring.dart';
import '../models/sharing.dart';
import '../models/sheep.dart';
import '../models/standings.dart';
import '../widgets/confirm_action.dart';
import '../widgets/counter_stepper.dart';
import '../widgets/game_icon.dart';
import '../widgets/goods_widgets.dart';
import '../widgets/info_hint.dart';
import '../widgets/meeple_icon.dart';
import '../widgets/number_keypad.dart';
import '../widgets/player_picker.dart';

enum _Field { tiles, banners }

/// Ekran liczenia punktów za miasto, drogę, klasztor, pola, zamek, surowce
/// i dyrektora cyrku. Zwraca [ScoreEvent] przez `Navigator.pop` (albo `null`,
/// gdy użytkownik wyjdzie bez zatwierdzenia). Zatwierdza fajka w pasku.
class AddPointsScreen extends StatefulWidget {
  final Player player;
  final List<Player> players;
  final ScoringType type;
  final Set<Expansion> expansions;

  const AddPointsScreen({
    super.key,
    required this.player,
    required this.players,
    required this.type,
    required this.expansions,
  });

  @override
  State<AddPointsScreen> createState() => _AddPointsScreenState();
}

class _AddPointsScreenState extends State<AddPointsScreen> {
  int _tiles = 0;
  int _banners = 0;
  int _castles = 0;
  int _vineyards = 0;
  bool _completed = true;

  /// Katedra (miasto), karczma (droga) lub świnka (pola).
  bool _bonus = false;
  bool _ringmaster = false;
  int _circusTiles = 0;
  bool _fairy = false;
  _Field _active = _Field.tiles;

  /// Pozostali gracze, którzy dostają punkty tej budowli (wspólnie lub z zamku).
  final Map<Player, PointsShare> _shares = {};

  /// Punktujący dostaje punkty tylko jako właściciel zamków.
  bool _scorerCastle = false;
  int _scorerCastles = 1;

  /// Punktujący ma mepla w budowli i dodatkowo zamki przy niej: dostaje swoje
  /// punkty plus punkty budowli za każdy zamek.
  bool _scorerHasCastle = false;
  int _scorerHasCastles = 1;

  /// Sposób punktowania pola (stodoła, dodatek „Opactwo i burmistrz").
  FarmScoring _farm = FarmScoring.normal;

  /// Sztabki złota (minidodatek „Kopalnie złota") dla graczy.
  final Map<Player, int> _gold = {};

  /// Klawiatura numeryczna jest wysuwana; zwija się na życzenie.
  bool _keypadOpen = true;

  final Map<Goods, int> _goods = {for (final g in Goods.values) g: 0};
  late Player _goodsRecipient = widget.player;

  ScoringType get _type => widget.type;

  bool _has(Expansion e) => widget.expansions.contains(e);

  bool get _isFeature => _type.isFeature;

  bool get _showGoods =>
      _type == ScoringType.goods ||
      (_type == ScoringType.city &&
          _completed &&
          _has(Expansion.tradersBuilders));

  bool get _showGold =>
      _type == ScoringType.gold ||
      (_type.supportsGold && _completed && _has(Expansion.goldMines));

  FarmScoring get _farmActive =>
      _type == ScoringType.meadow && _has(Expansion.abbeyMayor)
      ? _farm
      : FarmScoring.normal;

  /// Gracze, którym można dopisać złoto: wszyscy (ekran „Złoto") albo
  /// punktujący i wskazani gracze z punktów wspólnych.
  List<Player> get _goldPlayers => _type == ScoringType.gold
      ? widget.players
      : [widget.player, ..._shares.keys];

  Map<Player, int> get _goldToAdd => _showGold
      ? {
          for (final p in _goldPlayers)
            if ((_gold[p] ?? 0) > 0) p: _gold[p]!,
        }
      : const {};

  /// Ile sztabek zostało jeszcze do rozdania (poza już wybranymi).
  int get _goldAvailable =>
      goldRemaining(widget.players) -
      _goldToAdd.values.fold<int>(0, (a, b) => a + b);

  /// Zamek może punktować przy tej budowli (tylko ukończonej).
  bool get _castleOk =>
      _type.supportsCastle &&
      _completed &&
      _has(Expansion.bridgesCastlesBazaars);

  bool get _castleMode => _castleOk && _scorerCastle;

  /// Liczba zamków punktującego liczonych *oprócz* jego własnych punktów.
  int get _scorerExtraCastles =>
      _castleOk && !_scorerCastle && _scorerHasCastle ? _scorerHasCastles : 0;

  bool get _keypadVisible => _usesKeypad && _keypadOpen;

  /// Wróżka i dyrektor cyrku są przy meplu, a właściciel zamku go nie ma.
  bool get _showRingmaster =>
      _isFeature && _has(Expansion.circus) && !_castleMode;

  bool get _showFairy =>
      _isFeature && _has(Expansion.princessDragon) && !_castleMode;

  bool get _showSharing =>
      _isFeature &&
      (widget.players.length > 1 || _castleOk);

  List<Player> get _otherPlayers => [
    for (final p in widget.players)
      if (p != widget.player) p,
  ];

  bool get _ringmasterActive =>
      _type == ScoringType.ringmaster || (_showRingmaster && _ringmaster);

  bool get _usesKeypad => switch (_type) {
    ScoringType.goods || ScoringType.ringmaster || ScoringType.gold => false,
    ScoringType.cloister || ScoringType.abbey => !_completed,
    _ => true,
  };

  /// Niedokończony klasztor to najwyżej 8 płytek (razem z nim samym);
  /// komplet 9 płytek to już klasztor ukończony.
  int get _tilesMax =>
      _type == ScoringType.cloister || _type == ScoringType.abbey ? 8 : 999;

  Map<Goods, int> get _goodsToAdd => _showGoods
      ? {
          for (final e in _goods.entries)
            if (e.value > 0) e.key: e.value,
        }
      : const {};

  int get _points => _calc(circusTiles: _ringmasterActive ? _circusTiles : 0, fairy: _showFairy && _fairy);

  /// Punkty budowli bez premii przy meplu (wróżka, dyrektor cyrku) – to dostają
  /// współdzielący i właściciele zamków.
  int get _basePoints => _calc(circusTiles: 0, fairy: false);

  /// Punkty każdego gracza po podziale (punktujący jest pierwszy).
  Map<Player, int> get _distribution {
    if (!_isFeature) return {widget.player: _points};
    return splitPoints(
      scorer: widget.player,
      base: _basePoints,
      extras: _points - _basePoints,
      scorerAsCastle: _castleMode,
      scorerCastles: _scorerCastles,
      scorerExtraCastles: _scorerExtraCastles,
      others: {
        for (final e in _shares.entries)
          e.key: _castleOk ? e.value : e.value.copyWith(castle: false),
      },
    );
  }

  int _calc({required int circusTiles, required bool fairy}) => calculatePoints(
    _type,
    tiles: _tiles,
    banners: _banners,
    castles: _type == ScoringType.meadow && _has(Expansion.bridgesCastlesBazaars)
        ? _castles
        : 0,
    vineyards:
        (_type == ScoringType.cloister || _type == ScoringType.abbey) &&
            _has(Expansion.hillsSheep)
        ? _vineyards
        : 0,
    completed: _completed,
    bonus: _bonus,
    farm: _farmActive,
    circusTiles: circusTiles,
    withFairy: fairy,
  );

  void _onKey(String key) {
    setState(() {
      if (_active == _Field.banners && _type == ScoringType.city) {
        _banners = applyKey(_banners, key);
      } else {
        _tiles = applyKey(_tiles, key, max: _tilesMax);
      }
    });
  }

  String _label(
    Map<Player, int> distribution,
    Map<Goods, int> goods,
    Map<Player, int> gold,
  ) {
    final l = context.l10n;
    final goldText = gold.entries
        .map((e) => '${e.key.name} ×${e.value}')
        .join(', ');
    if (_type == ScoringType.gold) return '${l.scGold}: $goldText';

    final goodsText = [
      for (final e in goods.entries) '${e.key.title(l)} ×${e.value}',
    ];
    // Ekran surowców jest neutralny: zdarzenie opisuje odbiorcę surowców.
    if (_type == ScoringType.goods) {
      return '${l.scGoods}: ${_goodsRecipient.name} ${goodsText.join(', ')}';
    }

    final parts = <String>[];
    final mine = distribution[widget.player] ?? 0;
    if (mine != 0) parts.add('+$mine');
    parts.addAll(goodsText);
    final shared = <String>[];
    final castles = <String>[];
    for (final e in _shares.entries) {
      if (_castleOk && e.value.castle) {
        castles.add('${e.key.name} ×${e.value.castles}');
      } else {
        shared.add(e.key.name);
      }
    }
    final scorer = _castleMode
        ? '${widget.player.name} (${l.wordCastle} ×$_scorerCastles)'
        : _scorerExtraCastles > 0
        ? '${widget.player.name} (+ ${l.wordCastle} ×$_scorerExtraCastles)'
        : widget.player.name;
    return [
      '$scorer: ${_type.title(l)} ${parts.join(', ')}',
      if (shared.isNotEmpty) '${l.wordShared}: ${shared.join(', ')}',
      if (castles.isNotEmpty) '${l.wordCastles}: ${castles.join(', ')}',
      if (goldText.isNotEmpty) '${l.wordGold}: $goldText',
    ].join(' · ');
  }

  void _confirm() {
    final distribution = _distribution;
    final goods = _goodsToAdd;
    final gold = _goldToAdd;
    // Surowce dostaje gracz, który domknął miasto, a punkty – punktujący
    // (i ewentualnie pozostali gracze z podziału). Złoto dostają wskazani gracze.
    final recipient = goods.isEmpty ? null : _goodsRecipient;
    final totals = <Player, int>{...distribution};
    if (recipient != null) totals.putIfAbsent(recipient, () => 0);
    for (final p in gold.keys) {
      totals.putIfAbsent(p, () => 0);
    }
    final changes = [
      for (final e in totals.entries)
        if (e.value != 0 || e.key == recipient || gold.containsKey(e.key))
          ScoreChange(
            e.key,
            e.value,
            goods: e.key == recipient ? goods : const {},
            gold: gold[e.key] ?? 0,
          ),
    ];
    Navigator.pop(
      context,
      ScoreEvent(
        _label(distribution, goods, gold),
        changes,
        category: _type.title(context.l10n),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = widget.player.color;
    // Surowce i złoto to zdarzenia wspólne (odbiorcę wybiera się na ekranie),
    // więc ekran jest neutralny, jak bazar: bez imienia i koloru gracza.
    final neutral = _type == ScoringType.goods || _type == ScoringType.gold;
    final distribution = _distribution;
    final points = distribution[widget.player] ?? 0;
    final canConfirm =
        distribution.values.any((v) => v > 0) ||
        _goodsToAdd.isNotEmpty ||
        _goldToAdd.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          neutral
              ? _type.title(l)
              : '${widget.player.name} — ${_type.title(l)}',
        ),
        backgroundColor: neutral ? null : color.withValues(alpha: 0.2),
        actions: [ConfirmAction(onPressed: canConfirm ? _confirm : null)],
      ),
      body: Container(
        decoration: neutral
            ? null
            : BoxDecoration(border: Border.all(color: color, width: 4)),
        child: Column(
          children: [
            // Wynik jest przypięty u góry, żeby nie znikał przy przewijaniu.
            if (!neutral)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      l.scoreLabel(points),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (distribution.length > 1)
                      Text(
                        [
                          for (final e in distribution.entries)
                            if (e.key != widget.player)
                              '${e.key.name} +${e.value}',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
            Expanded(
              // Stuknięcie w puste miejsce zwija klawiaturę. Kontrolki
              // (pola, checkboxy) obsługują stuknięcie same i jej nie chowają.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _keypadVisible
                    ? () => setState(() => _keypadOpen = false)
                    : null,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ..._buildInputs(),
                      if (_castleOk) ..._buildCastleMode(),
                      if (_showFairy) ..._buildFairy(),
                      if (_showRingmaster) ..._buildRingmaster(),
                      if (_showSharing) _buildSharing(),
                      if (_showGold) _buildGold(),
                      if (_showGoods) _buildGoods(),
                    ],
                  ),
                ),
              ),
            ),
            _buildKeypadPanel(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ sekcje

  /// Klawiatura przypięta do dołu ekranu. Wysuwa się po wejściu na ekran i po
  /// stuknięciu w pole (płytki, sztandary); przycisk w prawym górnym rogu
  /// panelu ją zwija.
  Widget _buildKeypadPanel() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: _keypadVisible
          ? Material(
              elevation: 8,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: context.l10n.collapseKeypad,
                        visualDensity: VisualDensity.compact,
                        iconSize: 24,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: () => setState(() => _keypadOpen = false),
                      ),
                    ),
                    NumberKeypad(onKey: _onKey),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }

  List<Widget> _buildInputs() {
    final l = context.l10n;
    switch (_type) {
      case ScoringType.city:
        return [
          _valueBoxes([
            _valueBox(l.tiles, _tiles, _Field.tiles),
            _valueBox(l.pennants, _banners, _Field.banners),
          ]),
          if (_has(Expansion.innsCathedrals))
            _check(
              l.cathedral,
              _bonus,
              (v) {
                _bonus = v;
                // Nieukończone miasto z katedrą nie daje punktów, więc
                // takiego punktowania po prostu się nie dopisuje.
                if (v) _completed = true;
              },
              hint: l.cathedralHint,
            ),
          if (!_bonus)
            _check(l.completedCity, _completed, (v) => _completed = v),
        ];

      case ScoringType.road:
        return [
          _valueBoxes([_valueBox(l.tiles, _tiles, _Field.tiles)]),
          // Bez karczmy ukończona i nieukończona droga liczą się tak samo,
          // a nieukończona z karczmą nie daje punktów (nie dopisujemy jej).
          if (_has(Expansion.innsCathedrals))
            _check(
              l.inn,
              _bonus,
              (v) => _bonus = v,
              hint: l.innHint,
            ),
        ];

      case ScoringType.cloister:
      case ScoringType.abbey:
        final isAbbey = _type == ScoringType.abbey;
        return [
          // Jak „Ukończone miasto": zaznaczone = ukończony. Punkty za ukończony
          // (9) i niedokończony (1 za płytkę) opisuje podpowiedź.
          _check(
            isAbbey ? l.completedAbbey : l.completedCloister,
            _completed,
            (v) => _completed = v,
            hint: isAbbey ? l.abbeyHint : l.cloisterHint,
          ),
          if (_completed) ...[
            if (_has(Expansion.hillsSheep))
              _stepperRow(
                isAbbey ? l.vineyardsAbbey : l.vineyardsCloister,
                _vineyards,
                (v) => _vineyards = v,
                max: kMaxVineyards,
                hint: isAbbey
                    ? l.vineyardsAbbeyHint(kVineyardPoints, kMaxVineyards)
                    : l.vineyardsCloisterHint(kVineyardPoints, kMaxVineyards),
              ),
          ] else
            _valueBoxes([_valueBox(l.tiles, _tiles, _Field.tiles)]),
        ];

      case ScoringType.meadow:
        return [
          _valueBoxes([
            _valueBox(l.completedCities, _tiles, _Field.tiles),
          ]),
          if (_has(Expansion.bridgesCastlesBazaars))
            _stepperRow(
              l.castlesNearFarm,
              _castles,
              (v) => _castles = v,
              max: 12,
              hint: l.castlesNearFarmHint,
            ),
          if (_has(Expansion.abbeyMayor)) _buildBarnChoice(),
          if (_farmActive != FarmScoring.barnOwner)
            _check(
              l.pig,
              _bonus,
              (v) => _bonus = v,
              hint: l.pigHint,
            ),
        ];

      case ScoringType.ringmaster:
        return [
          _ringmasterTiles(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LabelWithHint(
              l.ringmasterAlways,
              l.ringmasterAlwaysHint,
            ),
          ),
        ];

      case ScoringType.fairy:
      case ScoringType.goods:
      case ScoringType.gold:
      case ScoringType.sheep:
      case ScoringType.bazaar:
      case ScoringType.circus:
      case ScoringType.pyramid:
      case ScoringType.tower:
        // Wróżka dopisuje 1 pkt od razu na liście graczy, a pozostałe typy
        // mają osobne ekrany lub (surowce) tylko sekcję surowców.
        return const [];
    }
  }

  /// Wybór sposobu punktowania pola przy stodole.
  Widget _buildBarnChoice() {
    final l = context.l10n;
    final labels = {
      FarmScoring.normal: l.farmNormal,
      FarmScoring.barnJoined: l.farmJoined,
      FarmScoring.barnOwner: l.farmBarnOwner,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GameIcon('assets/icons/game/barn.svg', size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: LabelWithHint(
                  l.barn,
                  l.barnHint,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final e in labels.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _farm == e.key,
                  onSelected: (_) => setState(() {
                    _farm = e.key;
                    if (e.key == FarmScoring.barnOwner) _bonus = false;
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sztabki złota z ukończonej budowli (minidodatek „Kopalnie złota").
  Widget _buildGold() {
    final l = context.l10n;
    final chosen = [
      for (final e in _goldToAdd.entries) '${e.key.name} ×${e.value}',
    ];
    final onlyGold = _type == ScoringType.gold;

    return ExpansionTile(
      initiallyExpanded: onlyGold,
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: EdgeInsets.zero,
      title: LabelWithHint(
        onlyGold ? l.goldBarsToAdd : l.goldBars,
        l.goldHint,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(chosen.isEmpty ? l.none : chosen.join(' · ')),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l.inSupply(goldRemaining(widget.players), kGoldSupply),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final p in _goldPlayers) _goldRow(p),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _goldRow(Player p) {
    final value = _gold[p] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const GameIcon('assets/icons/game/gold.svg', size: 30),
          const SizedBox(width: 8),
          MeepleIcon(color: p.color, size: 22),
          const SizedBox(width: 6),
          Expanded(child: Text(p.name)),
          CounterStepper(
            value: value,
            max: value + _goldAvailable,
            onChanged: (v) => setState(() => _gold[p] = v),
          ),
        ],
      ),
    );
  }

  /// „Punkty jako zamek": nikt nie miał w budowli mepla, a zamek stoi przy
  /// niej – punktujący dostaje punkty jako jego właściciel.
  List<Widget> _buildCastleMode() {
    final l = context.l10n;
    return [
      _check(
        l.pointsAsCastle,
        _scorerCastle,
        (v) => _scorerCastle = v,
        hint: l.pointsAsCastleHint(widget.player.name),
      ),
      if (_scorerCastle)
        _stepperRow(
          l.castlesOf(widget.player.name),
          _scorerCastles,
          (v) => _scorerCastles = v,
          min: 1,
          max: kMaxCastlesPerFeature,
        ),
    ];
  }

  /// Punkty wspólne (i zamki): wskazani gracze dostają te same punkty.
  Widget _buildSharing() {
    final l = context.l10n;
    final castleOk = _castleOk;
    final chosen = [
      for (final e in _shares.entries)
        castleOk && e.value.castle
            ? l.chosenCastle(e.key.name, e.value.castles)
            : e.key.name,
      if (_castleMode)
        l.chosenScorerAsCastle(widget.player.name, _scorerCastles)
      else if (_scorerExtraCastles > 0)
        l.chosenScorerHasCastle(widget.player.name, _scorerExtraCastles),
    ];

    return ExpansionTile(
      // Zwinięta domyślnie; wybrani gracze widać w podtytule.
      initiallyExpanded: false,
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: EdgeInsets.zero,
      title: LabelWithHint(
        castleOk && _type.supportsCastle
            ? l.sharedPointsCastles
            : l.sharedPoints,
        l.sharedHint + (castleOk ? l.sharedHintCastle : ''),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(chosen.isEmpty ? l.none : chosen.join(' · ')),
      children: [
        if (castleOk && !_scorerCastle) _scorerCastleRow(),
        for (final p in _otherPlayers) _shareRow(p),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Punktujący ma mepla w budowli i dodatkowo zamek przy niej: dostaje swoje
  /// punkty oraz punkty za zamek (inaczej niż „Punkty jako zamek").
  Widget _scorerCastleRow() {
    final l = context.l10n;
    return Column(
      children: [
        CheckboxListTile(
          secondary: MeepleIcon(color: widget.player.color, size: 28),
          title: Text(l.scorerHasCastle(widget.player.name)),
          value: _scorerHasCastle,
          onChanged: (v) => setState(() => _scorerHasCastle = v ?? false),
        ),
        if (_scorerHasCastle)
          _stepperRow(
            l.castlesCount,
            _scorerHasCastles,
            (v) => _scorerHasCastles = v,
            min: 1,
            max: kMaxCastlesPerFeature,
          ),
      ],
    );
  }

  Widget _shareRow(Player p) {
    final l = context.l10n;
    final share = _shares[p];
    return Column(
      children: [
        CheckboxListTile(
          secondary: MeepleIcon(color: p.color, size: 28),
          title: Text(p.name),
          value: share != null,
          onChanged: (v) => setState(() {
            if (v == true) {
              _shares[p] = const PointsShare();
            } else {
              _shares.remove(p);
            }
          }),
        ),
        if (share != null && _castleOk)
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(l.sharesSegment)),
                  ButtonSegment(value: true, label: Text(l.castleSegment)),
                ],
                selected: {share.castle},
                onSelectionChanged: (s) => setState(
                  () => _shares[p] = share.copyWith(castle: s.first),
                ),
              ),
            ),
          ),
        if (share != null && _castleOk && share.castle)
          _stepperRow(
            l.castlesOf(p.name),
            share.castles,
            (v) => _shares[p] = share.copyWith(castles: v),
            min: 1,
            max: kMaxCastlesPerFeature,
          ),
      ],
    );
  }

  List<Widget> _buildFairy() {
    final l = context.l10n;
    return [
      _check(
        l.fairyOption(kFairyFeaturePoints),
        _fairy,
        (v) => _fairy = v,
        hint: l.fairyHint(kFairyFeaturePoints),
      ),
    ];
  }

  /// Surowce. W mieście to zwijana sekcja (surowce dostaje ten, kto domknął
  /// miasto). Na osobnym ekranie surowców jest to zwykły, neutralny formularz
  /// jak w bazarze: najpierw wybierasz, kto dostaje surowce, potem liczniki.
  Widget _buildGoods() {
    final l = context.l10n;
    final isCity = _type == ScoringType.city;
    final chosen = [
      for (final e in _goodsToAdd.entries) '${e.key.title(l)} ×${e.value}',
    ];
    final counters = GoodsCounters(
      values: _goods,
      maxFor: (g) => goodsRemaining(g, widget.players),
      onChanged: (g, v) => setState(() => _goods[g] = v),
    );

    if (!isCity) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabelWithHint(
            l.goodsWho,
            l.goodsOtherHint,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          PlayerPicker(
            players: widget.players,
            selected: _goodsRecipient,
            onSelected: (p) => setState(() => _goodsRecipient = p),
          ),
          const SizedBox(height: 16),
          counters,
        ],
      );
    }

    return ExpansionTile(
      initiallyExpanded: false,
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: EdgeInsets.zero,
      title: LabelWithHint(
        l.goodsInCity,
        l.goodsCityHint,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(chosen.isEmpty ? l.none : chosen.join(' · ')),
      children: [
        counters,
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(l.traderCompleted),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: PlayerPicker(
            players: widget.players,
            selected: _goodsRecipient,
            onSelected: (p) => setState(() => _goodsRecipient = p),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  List<Widget> _buildRingmaster() {
    final l = context.l10n;
    return [
      _check(
        l.scRingmaster,
        _ringmaster,
        (v) => _ringmaster = v,
        hint: l.ringmasterHint(kRingmasterPointsPerTile),
      ),
      if (_ringmaster) _ringmasterTiles(),
    ];
  }

  Widget _ringmasterTiles() {
    final l = context.l10n;
    return _stepperRow(
      l.ringmasterTiles,
      _circusTiles,
      (v) => _circusTiles = v,
      max: kMaxRingmasterTiles,
      hint: l.ringmasterTilesHint(
        kRingmasterPointsPerTile,
        kMaxRingmasterTiles,
      ),
    );
  }

  // ----------------------------------------------------------- widgety

  Widget _check(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? hint,
  }) {
    return CheckboxListTile(
      title: hint == null ? Text(title) : LabelWithHint(title, hint),
      value: value,
      onChanged: (v) => setState(() => onChanged(v ?? false)),
    );
  }

  Widget _stepperRow(
    String label,
    int value,
    ValueChanged<int> onChanged, {
    int min = 0,
    int max = 99,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: hint == null ? Text(label) : LabelWithHint(label, hint),
          ),
          CounterStepper(
            value: value,
            min: min,
            max: max,
            onChanged: (v) => setState(() => onChanged(v)),
          ),
        ],
      ),
    );
  }

  Widget _valueBoxes(List<Widget> boxes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: widget.player.color, width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: boxes,
      ),
    );
  }

  Widget _valueBox(String label, int value, _Field field, {String? hint}) {
    final isActive = _active == field;
    return GestureDetector(
      onTap: () => setState(() {
        _active = field;
        _keypadOpen = true;
      }),
      child: Column(
        children: [
          hint == null
              ? Text(label, textAlign: TextAlign.center)
              : LabelWithHint(label, hint),
          const SizedBox(height: 8),
          Container(
            width: 100,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                width: isActive ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$value', style: const TextStyle(fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }
}
