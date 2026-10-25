import 'package:flutter/material.dart';

import '../l10n/tr.dart';
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
    final goldText = gold.entries
        .map((e) => '${e.key.name} ×${e.value}')
        .join(', ');
    if (_type == ScoringType.gold) {
      return '${tr('Złoto', 'Gold')}: $goldText';
    }

    final parts = <String>[];
    final mine = distribution[widget.player] ?? 0;
    if (mine != 0) parts.add('+$mine');
    for (final e in goods.entries) {
      parts.add('${e.key.displayName} ×${e.value}');
    }
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
        ? '${widget.player.name} (${tr('zamek', 'castle')} ×$_scorerCastles)'
        : _scorerExtraCastles > 0
        ? '${widget.player.name} (+ ${tr('zamek', 'castle')} '
              '×$_scorerExtraCastles)'
        : widget.player.name;
    return [
      '$scorer: ${_type.displayName} ${parts.join(', ')}',
      if (shared.isNotEmpty)
        '${tr('wspólnie', 'shared')}: ${shared.join(', ')}',
      if (castles.isNotEmpty)
        '${tr('zamki', 'castles')}: ${castles.join(', ')}',
      if (goldText.isNotEmpty) '${tr('złoto', 'gold')}: $goldText',
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
        category: _type.displayName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.player.color;
    final distribution = _distribution;
    final points = distribution[widget.player] ?? 0;
    final canConfirm =
        distribution.values.any((v) => v > 0) ||
        _goodsToAdd.isNotEmpty ||
        _goldToAdd.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.player.name} — ${_type.displayName}'),
        backgroundColor: color.withValues(alpha: 0.2),
        actions: [ConfirmAction(onPressed: canConfirm ? _confirm : null)],
      ),
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: color, width: 4)),
        child: Column(
          children: [
            // Wynik jest przypięty u góry, żeby nie znikał przy przewijaniu.
            if (_type != ScoringType.goods && _type != ScoringType.gold)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      '${tr('Wynik', 'Score')}: $points ${tr('pkt', 'pts')}',
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
                        tooltip: tr('Zwiń klawiaturę', 'Collapse keypad'),
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
    switch (_type) {
      case ScoringType.city:
        return [
          _valueBoxes([
            _valueBox(tr('Płytki', 'Tiles'), _tiles, _Field.tiles),
            _valueBox(tr('Sztandary', 'Pennants'), _banners, _Field.banners),
          ]),
          if (_has(Expansion.innsCathedrals))
            _check(
              tr('Katedra', 'Cathedral'),
              _bonus,
              (v) {
                _bonus = v;
                // Nieukończone miasto z katedrą nie daje punktów, więc
                // takiego punktowania po prostu się nie dopisuje.
                if (v) _completed = true;
              },
              hint: tr(
                'Miasto z katedrą: 3 pkt za płytkę i sztandar. '
                    'Nieukończone miasto z katedrą nie daje punktów, '
                    'więc nie ma czego dopisywać.',
                'City with a cathedral: 3 pts per tile and pennant. '
                    'An unfinished city with a cathedral scores nothing, '
                    'so there is nothing to add.',
              ),
            ),
          if (!_bonus)
            _check(
              tr('Ukończone miasto', 'Completed city'),
              _completed,
              (v) => _completed = v,
            ),
        ];

      case ScoringType.road:
        return [
          _valueBoxes([_valueBox(tr('Płytki', 'Tiles'), _tiles, _Field.tiles)]),
          // Bez karczmy ukończona i nieukończona droga liczą się tak samo,
          // a nieukończona z karczmą nie daje punktów (nie dopisujemy jej).
          if (_has(Expansion.innsCathedrals))
            _check(
              tr('Karczma', 'Inn'),
              _bonus,
              (v) => _bonus = v,
              hint: tr(
                'Droga z karczmą: 2 pkt za płytkę. '
                    'Nieukończona droga z karczmą nie daje punktów, '
                    'więc nie ma czego dopisywać.',
                'Road with an inn: 2 pts per tile. '
                    'An unfinished road with an inn scores nothing, '
                    'so there is nothing to add.',
              ),
            ),
        ];

      case ScoringType.cloister:
      case ScoringType.abbey:
        final isAbbey = _type == ScoringType.abbey;
        final noun = isAbbey
            ? tr('opactwo', 'abbey')
            : tr('klasztor', 'cloister');
        final nounGen = isAbbey
            ? tr('opactwa', 'abbey')
            : tr('klasztoru', 'cloister');
        return [
          _check(
            tr(
              'Niedokończone (punkty na koniec gry)',
              'Unfinished (end-of-game points)',
            ),
            !_completed,
            (v) => _completed = !v,
            hint: tr(
              'Na koniec gry niedokończone $noun daje 1 pkt za każdą '
                  'płytkę: $noun i otaczające je płytki.',
              'At the end of the game an unfinished $noun gives 1 pt per '
                  'tile: the $noun and the tiles around it.',
            ),
          ),
          if (_completed) ...[
            Text(
              tr('Ukończone $noun = 9 pkt', 'Completed $noun = 9 pts'),
              style: const TextStyle(fontSize: 20),
            ),
            if (_has(Expansion.hillsSheep))
              _stepperRow(
                tr('Winnice wokół $nounGen', 'Vineyards around the $noun'),
                _vineyards,
                (v) => _vineyards = v,
                max: kMaxVineyards,
                hint: tr(
                  '$kVineyardPoints pkt za każdą winnicę na płytkach wokół '
                      'ukończonego $nounGen (najwyżej $kMaxVineyards).',
                  '$kVineyardPoints pts for each vineyard on the tiles '
                      'around a completed $noun (at most $kMaxVineyards).',
                ),
              ),
          ] else
            _valueBoxes([_valueBox(tr('Płytki', 'Tiles'), _tiles, _Field.tiles)]),
        ];

      case ScoringType.meadow:
        return [
          _valueBoxes([
            _valueBox(
              tr('Ukończone miasta', 'Completed cities'),
              _tiles,
              _Field.tiles,
            ),
          ]),
          if (_has(Expansion.bridgesCastlesBazaars))
            _stepperRow(
              tr('Zamki przy polu', 'Castles next to the farm'),
              _castles,
              (v) => _castles = v,
              max: 12,
              hint: tr(
                'Zamek przy polu jest wart 4 pkt zamiast 3, '
                    'a ze świnką 5 pkt, tak jak ukończone miasto.',
                'A castle next to the farm is worth 4 pts instead of 3, '
                    'or 5 with a pig, like a completed city.',
              ),
            ),
          if (_has(Expansion.abbeyMayor)) _buildBarnChoice(),
          if (_farmActive != FarmScoring.barnOwner)
            _check(
              tr('Świnka', 'Pig'),
              _bonus,
              (v) => _bonus = v,
              hint: tr(
                'Ze świnką każde ukończone miasto przy polu daje 4 pkt '
                    '(przy polu połączonym ze stodołą 2 pkt zamiast 1).',
                'With a pig each completed city next to the farm gives '
                    '4 pts (2 pts instead of 1 on a farm joined to a barn).',
              ),
            ),
        ];

      case ScoringType.ringmaster:
        return [
          _ringmasterTiles(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LabelWithHint(
              tr('Dyrektor punktuje zawsze', 'Ringmaster always scores'),
              tr(
                'Dyrektor cyrku dostaje punkty także wtedy, gdy nie masz '
                    'większości w budowli, oraz na koniec gry na polu lub '
                    'w nieukończonej budowli.',
                'The ringmaster scores even when you do not have the '
                    'majority in the feature, and at the end of the game on '
                    'a farm or in an unfinished feature.',
              ),
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
    final labels = {
      FarmScoring.normal: tr('Zwykłe', 'Normal'),
      FarmScoring.barnJoined: tr('Połączone ze stodołą', 'Joined to a barn'),
      FarmScoring.barnOwner: tr('Właściciel stodoły', 'Barn owner'),
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
                  tr('Stodoła', 'Barn'),
                  tr(
                    'Zwykłe: punktowanie pola na koniec gry albo w chwili '
                        'postawienia stodoły (3 pkt za miasto). Połączone ze '
                        'stodołą: rolnicy na polu, które właśnie połączono z '
                        'polem ze stodołą, dostają 1 pkt za miasto (2 ze '
                        'świnką). Właściciel stodoły na koniec gry: 4 pkt za '
                        'miasto i 5 za zamek, bez świnki; każda stodoła na '
                        'połączonym polu dostaje pełną punktację.',
                    'Normal: scoring the farm at the end of the game or when '
                        'the barn is placed (3 pts per city). Joined to a '
                        'barn: farmers on a farm that was just joined to the '
                        'barn farm get 1 pt per city (2 with a pig). Barn '
                        'owner at the end of the game: 4 pts per city and 5 '
                        'per castle, no pig; each barn on the joined farm '
                        'gets the full score.',
                  ),
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
        onlyGold
            ? tr('Sztabki złota do dopisania', 'Gold bars to add')
            : tr('Sztabki złota', 'Gold bars'),
        tr(
          'Sztabki z płytek ukończonej budowli dostaje gracz z przewagą; przy '
              'remisie dzielą się nimi według kolejności. Rolnicy złota nie '
              'dostają. Na koniec gry im więcej sztabek, tym więcej warta '
              'każda: 1–3 po 1 pkt, 4–6 po 2, 7–9 po 3, od 10 po 4.',
          'Gold bars from the tiles of a completed feature go to the player '
              'with the majority; on a tie they are shared in turn order. '
              'Farmers get no gold. At the end of the game the more bars you '
              'hold, the more each is worth: 1–3 bars 1 pt each, 4–6 2 pts, '
              '7–9 3 pts, 10+ 4 pts.',
        ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(chosen.isEmpty ? tr('brak', 'none') : chosen.join(' · ')),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${tr('W puli', 'In supply')}: ${goldRemaining(widget.players)} / $kGoldSupply',
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
    return [
      _check(
        tr('Punkty jako zamek', 'Points as a castle'),
        _scorerCastle,
        (v) => _scorerCastle = v,
        hint: tr(
          'Zaznacz, gdy nikt nie miał mepla w tej budowli, ale '
              '${widget.player.name} ma przy niej zamek: dostaje punkty '
              'ukończonej budowli (za każdy swój zamek).',
          'Check this when nobody had a meeple in this feature but '
              '${widget.player.name} has a castle next to it: they get the '
              'points of the completed feature (for each castle they own).',
        ),
      ),
      if (_scorerCastle)
        _stepperRow(
          tr(
            'Liczba zamków gracza ${widget.player.name}',
            '${widget.player.name}\'s castles',
          ),
          _scorerCastles,
          (v) => _scorerCastles = v,
          min: 1,
          max: kMaxCastlesPerFeature,
        ),
    ];
  }

  /// Punkty wspólne (i zamki): wskazani gracze dostają te same punkty.
  Widget _buildSharing() {
    final castleOk = _castleOk;
    final chosen = [
      for (final e in _shares.entries)
        castleOk && e.value.castle
            ? '${e.key.name} (${tr('zamek', 'castle')} ×${e.value.castles})'
            : e.key.name,
      if (_castleMode)
        tr(
          '${widget.player.name} (punktujący, jako zamek ×$_scorerCastles)',
          '${widget.player.name} (scoring, as a castle ×$_scorerCastles)',
        )
      else if (_scorerExtraCastles > 0)
        tr(
          '${widget.player.name} (punktujący, ma zamek ×$_scorerExtraCastles)',
          '${widget.player.name} (scoring, has a castle '
              '×$_scorerExtraCastles)',
        ),
    ];

    return ExpansionTile(
      // Zwinięta domyślnie; wybrani gracze widać w podtytule.
      initiallyExpanded: false,
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: EdgeInsets.zero,
      title: LabelWithHint(
        castleOk && _type.supportsCastle
            ? tr('Punkty wspólne / zamki', 'Shared points / castles')
            : tr('Punkty wspólne', 'Shared points'),
        tr(
          'Wskaż graczy, którzy dostają te same punkty (np. dzielą budowlę '
              'przy remisie). Wróżka i dyrektor cyrku liczą się tylko '
              'punktującemu.'
              '${castleOk ? ' Dla gracza możesz wybrać „Zamek": dostaje wtedy '
                  'punkty budowli za każdy swój zamek przy niej, '
                  'a nie ze współdzielenia. Punktujący ma tu opcję „ma zamek": '
                  'dostaje swoje punkty i dodatkowo punkty za zamek '
                  '(punkty tylko jako zamek to pole „Punkty jako zamek").' : ''}',
          'Pick the players who get the same points (e.g. who share the '
              'feature on a tie). The fairy and the ringmaster count only '
              'for the scoring player.'
              '${castleOk ? ' For a player you can choose "Castle": they '
                  'then get the feature points for each castle they own next '
                  'to it, instead of sharing. The scoring player has the '
                  '"has a castle" option here: they get their own points plus '
                  'the castle points (points only as a castle are the '
                  '"Points as a castle" box).' : ''}',
        ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(chosen.isEmpty ? tr('brak', 'none') : chosen.join(' · ')),
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
    return Column(
      children: [
        CheckboxListTile(
          secondary: MeepleIcon(color: widget.player.color, size: 28),
          title: Text(
            tr(
              '${widget.player.name} (punktujący) ma zamek',
              '${widget.player.name} (scoring) has a castle',
            ),
          ),
          value: _scorerHasCastle,
          onChanged: (v) => setState(() => _scorerHasCastle = v ?? false),
        ),
        if (_scorerHasCastle)
          _stepperRow(
            tr('Liczba zamków', 'Number of castles'),
            _scorerHasCastles,
            (v) => _scorerHasCastles = v,
            min: 1,
            max: kMaxCastlesPerFeature,
          ),
      ],
    );
  }

  Widget _shareRow(Player p) {
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
                  ButtonSegment(
                    value: false,
                    label: Text(tr('Współdzieli', 'Shares')),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(tr('Zamek', 'Castle')),
                  ),
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
            tr('Liczba zamków gracza ${p.name}', '${p.name}\'s castles'),
            share.castles,
            (v) => _shares[p] = share.copyWith(castles: v),
            min: 1,
            max: kMaxCastlesPerFeature,
          ),
      ],
    );
  }

  List<Widget> _buildFairy() {
    return [
      _check(
        tr(
          'Wróżka przy meplu (+$kFairyFeaturePoints pkt)',
          'Fairy next to a meeple (+$kFairyFeaturePoints pts)',
        ),
        _fairy,
        (v) => _fairy = v,
        hint: tr(
          'Jeśli wróżka stoi przy meplu w punktowanej budowli (miasto, '
              'droga, klasztor lub pole), jego właściciel dostaje '
              '$kFairyFeaturePoints pkt niezależnie od zwykłej punktacji. '
              'Dotyczy też punktowania na koniec gry.',
          'If the fairy stands next to a meeple in the scored feature '
              '(city, road, cloister or farm), its owner gets '
              '$kFairyFeaturePoints pts regardless of the normal scoring. '
              'This also applies to end-of-game scoring.',
        ),
      ),
    ];
  }

  /// Surowce w mieście. Sekcja jest zwijana, bo zajmuje dużo miejsca.
  Widget _buildGoods() {
    final isCity = _type == ScoringType.city;
    final chosen = [
      for (final e in _goodsToAdd.entries)
        '${e.key.displayName} ×${e.value}',
    ];

    return ExpansionTile(
      initiallyExpanded: !isCity,
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: EdgeInsets.zero,
      title: LabelWithHint(
        isCity
            ? tr('Surowce w mieście', 'Goods in the city')
            : tr('Surowce do dopisania', 'Goods to add'),
        isCity
            ? tr(
                'Surowce dostaje gracz, który domknął miasto – '
                    'nawet bez mepla w mieście.',
                'The goods go to the player who completed the city – '
                    'even without a meeple in the city.',
              )
            : tr(
                'Surowce dostaje wskazany gracz.',
                'The goods go to the chosen player.',
              ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(chosen.isEmpty ? tr('brak', 'none') : chosen.join(' · ')),
      children: [
        GoodsCounters(
          values: _goods,
          maxFor: (g) => goodsRemaining(g, widget.players),
          onChanged: (g, v) => setState(() => _goods[g] = v),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            isCity
                ? tr('Kupiec (domknął miasto):', 'Trader (completed the city):')
                : tr('Surowce dla:', 'Goods for:'),
          ),
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
    return [
      _check(
        tr('Dyrektor cyrku', 'Ringmaster'),
        _ringmaster,
        (v) => _ringmaster = v,
        hint: tr(
          'Dyrektor cyrku dodaje $kRingmasterPointsPerTile pkt za każdą '
              'płytkę cyrku lub akrobatów, na której stoi lub która z nim '
              'sąsiaduje.',
          'The ringmaster adds $kRingmasterPointsPerTile pts for each '
              'circus or acrobat tile he stands on or that is next to him.',
        ),
      ),
      if (_ringmaster) _ringmasterTiles(),
    ];
  }

  Widget _ringmasterTiles() {
    return _stepperRow(
      tr(
        'Płytki cyrku i akrobatów wokół dyrektora',
        'Circus and acrobat tiles around the ringmaster',
      ),
      _circusTiles,
      (v) => _circusTiles = v,
      max: kMaxRingmasterTiles,
      hint: tr(
        '$kRingmasterPointsPerTile pkt za każdą płytkę cyrku lub '
            'akrobatów pod dyrektorem i wokół niego (obszar 3×3, '
            'najwyżej $kMaxRingmasterTiles).',
        '$kRingmasterPointsPerTile pts for each circus or acrobat tile '
            'under and around the ringmaster (a 3×3 area, at most '
            '$kMaxRingmasterTiles).',
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
