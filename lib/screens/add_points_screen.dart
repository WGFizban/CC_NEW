import 'package:flutter/material.dart';

import '../models/circus.dart';
import '../models/expansion.dart';
import '../models/fairy.dart';
import '../models/goods.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../models/scoring.dart';
import '../models/sheep.dart';
import '../models/standings.dart';
import '../widgets/confirm_action.dart';
import '../widgets/counter_stepper.dart';
import '../widgets/goods_widgets.dart';
import '../widgets/info_hint.dart';
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
  int _bridges = 0;
  int _castles = 0;
  int _vineyards = 0;
  bool _completed = true;

  /// Katedra (miasto), karczma (droga) lub świnka (pola).
  bool _bonus = false;
  bool _ringmaster = false;
  int _circusTiles = 0;
  bool _fairy = false;
  _Field _active = _Field.tiles;

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

  bool get _showRingmaster => _isFeature && _has(Expansion.circus);

  bool get _showFairy => _isFeature && _has(Expansion.princessDragon);

  bool get _ringmasterActive =>
      _type == ScoringType.ringmaster || (_showRingmaster && _ringmaster);

  bool get _usesKeypad => switch (_type) {
    ScoringType.goods || ScoringType.ringmaster => false,
    ScoringType.cloister => !_completed,
    _ => true,
  };

  /// Niedokończony klasztor to najwyżej 8 płytek (razem z nim samym);
  /// komplet 9 płytek to już klasztor ukończony.
  int get _tilesMax => _type == ScoringType.cloister ? 8 : 999;

  Map<Goods, int> get _goodsToAdd => _showGoods
      ? {
          for (final e in _goods.entries)
            if (e.value > 0) e.key: e.value,
        }
      : const {};

  int get _points => calculatePoints(
    _type,
    tiles: _tiles,
    banners: _banners,
    bridges: _type == ScoringType.road && _has(Expansion.bridgesCastlesBazaars)
        ? _bridges
        : 0,
    castles: _type == ScoringType.meadow && _has(Expansion.bridgesCastlesBazaars)
        ? _castles
        : 0,
    vineyards: _type == ScoringType.cloister && _has(Expansion.hillsSheep)
        ? _vineyards
        : 0,
    completed: _completed,
    bonus: _bonus,
    circusTiles: _ringmasterActive ? _circusTiles : 0,
    withFairy: _showFairy && _fairy,
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

  String _label(int points, Map<Goods, int> goods) {
    final parts = <String>[];
    if (points != 0) parts.add('+$points');
    for (final e in goods.entries) {
      parts.add('${e.key.displayName} ×${e.value}');
    }
    return '${widget.player.name}: ${_type.displayName} ${parts.join(', ')}';
  }

  void _confirm() {
    final points = _points;
    final goods = _goodsToAdd;
    final changes = <ScoreChange>[];
    if (goods.isNotEmpty && _goodsRecipient != widget.player) {
      // Surowce dostaje gracz, który domknął miasto, a punkty – punktujący.
      if (points != 0) changes.add(ScoreChange(widget.player, points));
      changes.add(ScoreChange(_goodsRecipient, 0, goods: goods));
    } else {
      changes.add(ScoreChange(widget.player, points, goods: goods));
    }
    Navigator.pop(context, ScoreEvent(_label(points, goods), changes));
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.player.color;
    final points = _points;
    final canConfirm = points > 0 || _goodsToAdd.isNotEmpty;

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
            if (_type != ScoringType.goods)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Wynik: $points pkt',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ..._buildInputs(),
                    if (_showFairy) ..._buildFairy(),
                    if (_showGoods) _buildGoods(),
                    if (_showRingmaster) ..._buildRingmaster(),
                    if (_usesKeypad) ...[
                      const SizedBox(height: 16),
                      NumberKeypad(onKey: _onKey),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ sekcje

  List<Widget> _buildInputs() {
    switch (_type) {
      case ScoringType.city:
        return [
          _valueBoxes([
            _valueBox('Płytki', _tiles, _Field.tiles),
            _valueBox('Sztandary', _banners, _Field.banners),
          ]),
          _check(
            'Katedra',
            _bonus,
            (v) => _bonus = v,
            hint:
                'Miasto z katedrą: 3 pkt za płytkę i sztandar. '
                'Nieukończone miasto z katedrą nie daje punktów.',
          ),
          _check('Ukończone miasto', _completed, (v) => _completed = v),
        ];

      case ScoringType.road:
        return [
          _valueBoxes([_valueBox('Płytki', _tiles, _Field.tiles)]),
          if (_has(Expansion.bridgesCastlesBazaars))
            _stepperRow(
              'Płytki z mostem',
              _bridges,
              (v) => _bridges = v,
              hint:
                  'Most punktuje jak płytka z drogą, ale płytka liczy się '
                  'tylko raz. Wpisz tu tylko te płytki z mostem, których '
                  'nie wliczyłeś w „Płytkach".',
            ),
          _check(
            'Karczma',
            _bonus,
            (v) => _bonus = v,
            hint:
                'Droga z karczmą: 2 pkt za płytkę. '
                'Nieukończona droga z karczmą nie daje punktów.',
          ),
          // Bez karczmy ukończona i nieukończona droga liczą się tak samo.
          if (_bonus)
            _check('Ukończona droga', _completed, (v) => _completed = v),
        ];

      case ScoringType.cloister:
        return [
          _check(
            'Niedokończony (punkty na koniec gry)',
            !_completed,
            (v) => _completed = !v,
            hint:
                'Na koniec gry niedokończony klasztor daje 1 pkt za każdą '
                'płytkę: klasztor i otaczające go płytki.',
          ),
          if (_completed) ...[
            const Text(
              'Ukończony klasztor = 9 pkt',
              style: TextStyle(fontSize: 20),
            ),
            if (_has(Expansion.hillsSheep))
              _stepperRow(
                'Winnice wokół klasztoru',
                _vineyards,
                (v) => _vineyards = v,
                max: kMaxVineyards,
                hint:
                    '$kVineyardPoints pkt za każdą winnicę na płytkach wokół '
                    'ukończonego klasztoru (najwyżej $kMaxVineyards).',
              ),
          ] else
            _valueBoxes([_valueBox('Płytki', _tiles, _Field.tiles)]),
        ];

      case ScoringType.meadow:
        return [
          _valueBoxes([_valueBox('Ukończone miasta', _tiles, _Field.tiles)]),
          if (_has(Expansion.bridgesCastlesBazaars))
            _stepperRow(
              'Zamki przy polu',
              _castles,
              (v) => _castles = v,
              max: 12,
              hint:
                  'Zamek przy polu jest wart 4 pkt zamiast 3, '
                  'a ze świnką 5 pkt, tak jak ukończone miasto.',
            ),
          _check(
            'Świnka',
            _bonus,
            (v) => _bonus = v,
            hint: 'Ze świnką każde ukończone miasto przy polu daje 4 pkt.',
          ),
        ];

      case ScoringType.castle:
        return [
          _valueBoxes([
            _valueBox(
              'Punkty ukończonej budowli',
              _tiles,
              _Field.tiles,
              hint:
                  'Zamek punktuje raz: przy pierwszej ukończonej budowli '
                  'sąsiadującej z zamkiem (jego dwie płytki oraz po dwie '
                  'płytki z lewej i prawej). Wpisz tyle punktów, ile dostała '
                  'ta budowla, a potem zdejmij ludka z zamku. '
                  'Zamek na końcu gry nie daje punktów.',
            ),
          ]),
        ];

      case ScoringType.ringmaster:
        return [
          _ringmasterTiles(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LabelWithHint(
              'Dyrektor punktuje zawsze',
              'Dyrektor cyrku dostaje punkty także wtedy, gdy nie masz '
                  'większości w budowli, oraz na koniec gry na polu lub '
                  'w nieukończonej budowli.',
            ),
          ),
        ];

      case ScoringType.fairy:
      case ScoringType.goods:
      case ScoringType.sheep:
      case ScoringType.bazaar:
      case ScoringType.circus:
      case ScoringType.pyramid:
        // Wróżka dopisuje 1 pkt od razu na liście graczy, a pozostałe typy
        // mają osobne ekrany lub (surowce) tylko sekcję surowców.
        return const [];
    }
  }

  List<Widget> _buildFairy() {
    return [
      _check(
        'Wróżka przy ludku (+$kFairyFeaturePoints pkt)',
        _fairy,
        (v) => _fairy = v,
        hint:
            'Jeśli wróżka stoi przy ludku w punktowanej budowli (miasto, '
            'droga, klasztor lub pole), jego właściciel dostaje '
            '$kFairyFeaturePoints pkt niezależnie od zwykłej punktacji. '
            'Dotyczy też punktowania na koniec gry.',
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
        isCity ? 'Surowce w mieście' : 'Surowce do dopisania',
        isCity
            ? 'Surowce dostaje gracz, który domknął miasto – '
                  'nawet bez ludka w mieście.'
            : 'Surowce dostaje wskazany gracz.',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(chosen.isEmpty ? 'brak' : chosen.join(' · ')),
      children: [
        GoodsCounters(
          values: _goods,
          maxFor: (g) => goodsRemaining(g, widget.players),
          onChanged: (g, v) => setState(() => _goods[g] = v),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(isCity ? 'Kupiec (domknął miasto):' : 'Surowce dla:'),
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
        'Dyrektor cyrku',
        _ringmaster,
        (v) => _ringmaster = v,
        hint:
            'Dyrektor cyrku dodaje $kRingmasterPointsPerTile pkt za każdą '
            'płytkę cyrku lub akrobatów, na której stoi lub która z nim '
            'sąsiaduje.',
      ),
      if (_ringmaster) _ringmasterTiles(),
    ];
  }

  Widget _ringmasterTiles() {
    return _stepperRow(
      'Płytki cyrku i akrobatów wokół dyrektora',
      _circusTiles,
      (v) => _circusTiles = v,
      max: kMaxRingmasterTiles,
      hint:
          '$kRingmasterPointsPerTile pkt za każdą płytkę cyrku lub '
          'akrobatów pod dyrektorem i wokół niego (obszar 3×3, '
          'najwyżej $kMaxRingmasterTiles).',
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
      onTap: () => setState(() => _active = field),
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
                color: isActive ? Colors.blueAccent : Colors.grey,
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
