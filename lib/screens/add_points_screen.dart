import 'package:flutter/material.dart';

import '../models/circus.dart';
import '../models/expansion.dart';
import '../models/goods.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../models/scoring.dart';
import '../models/sheep.dart';
import '../models/standings.dart';
import '../widgets/counter_stepper.dart';
import '../widgets/goods_widgets.dart';
import '../widgets/number_keypad.dart';
import '../widgets/player_picker.dart';

enum _Field { tiles, banners }

/// Ekran liczenia punktów za miasto, drogę, klasztor, pola, wróżkę, zamek,
/// surowce i dyrektora cyrku. Zwraca [ScoreEvent] przez `Navigator.pop`
/// (albo `null`, gdy użytkownik wyjdzie bez zatwierdzenia).
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
  _Field _active = _Field.tiles;

  final Map<Goods, int> _goods = {for (final g in Goods.values) g: 0};
  late Player _goodsRecipient = widget.player;

  ScoringType get _type => widget.type;

  bool _has(Expansion e) => widget.expansions.contains(e);

  bool get _isFeature =>
      _type == ScoringType.city ||
      _type == ScoringType.road ||
      _type == ScoringType.cloister ||
      _type == ScoringType.meadow;

  bool get _showGoods =>
      _type == ScoringType.goods ||
      (_type == ScoringType.city &&
          _completed &&
          _has(Expansion.tradersBuilders));

  bool get _showRingmaster => _isFeature && _has(Expansion.circus);

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
      ),
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: color, width: 4)),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ..._buildInputs(),
              if (_showGoods) ..._buildGoods(),
              if (_showRingmaster) ..._buildRingmaster(),
              const SizedBox(height: 12),
              if (_type != ScoringType.goods)
                Text(
                  'Wynik: $points pkt',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (_usesKeypad) ...[
                const SizedBox(height: 16),
                NumberKeypad(onKey: _onKey),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: canConfirm ? _confirm : null,
                child: const Text('Zatwierdź'),
              ),
            ],
          ),
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
          _check('Katedra', _bonus, (v) => _bonus = v),
          _check('Ukończone miasto', _completed, (v) => _completed = v),
        ];

      case ScoringType.road:
        return [
          _valueBoxes([_valueBox('Płytki', _tiles, _Field.tiles)]),
          if (_has(Expansion.bridgesCastlesBazaars))
            _stepperRow(
              'Płytki z mostem (tylko te, których nie wliczyłeś wyżej)',
              _bridges,
              (v) => _bridges = v,
            ),
          _check('Karczma', _bonus, (v) => _bonus = v),
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
          ),
          if (_completed) ...[
            const Text(
              'Ukończony klasztor = 9 pkt',
              style: TextStyle(fontSize: 20),
            ),
            if (_has(Expansion.hillsSheep))
              _stepperRow(
                'Winnice wokół klasztoru (po $kVineyardPoints pkt)',
                _vineyards,
                (v) => _vineyards = v,
                max: kMaxVineyards,
              ),
          ] else
            _valueBoxes([_valueBox('Płytki', _tiles, _Field.tiles)]),
        ];

      case ScoringType.meadow:
        return [
          _valueBoxes([_valueBox('Ukończone miasta', _tiles, _Field.tiles)]),
          if (_has(Expansion.bridgesCastlesBazaars))
            _stepperRow(
              'Zamki przy polu (po 4 pkt, ze świnką po 5)',
              _castles,
              (v) => _castles = v,
              max: 12,
            ),
          _check('Świnka', _bonus, (v) => _bonus = v),
        ];

      case ScoringType.fairy:
        return [
          _valueBoxes([_valueBox('Punkty', _tiles, _Field.tiles)]),
        ];

      case ScoringType.castle:
        return [
          _valueBoxes([
            _valueBox('Punkty ukończonej budowli', _tiles, _Field.tiles),
          ]),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Zamek punktuje raz – przy pierwszej ukończonej budowli '
              'sąsiadującej z zamkiem (dwie płytki zamku oraz po dwie '
              'płytki z lewej i z prawej). Wpisz tyle punktów, ile dostała '
              'ta budowla; potem zdejmij ludka z zamku. Zamek na końcu gry '
              'nie daje punktów.',
              textAlign: TextAlign.center,
            ),
          ),
        ];

      case ScoringType.ringmaster:
        return [
          _ringmasterTiles(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Dyrektor punktuje zawsze, także gdy nie masz większości '
              'w budowli, oraz na koniec gry na polu lub w nieukończonej '
              'budowli.',
              textAlign: TextAlign.center,
            ),
          ),
        ];

      case ScoringType.goods:
      case ScoringType.sheep:
      case ScoringType.bazaar:
      case ScoringType.circus:
      case ScoringType.pyramid:
        // Te typy mają osobne ekrany lub (surowce) tylko sekcję surowców.
        return const [];
    }
  }

  List<Widget> _buildGoods() {
    final isCity = _type == ScoringType.city;
    return [
      const SizedBox(height: 8),
      Text(
        isCity
            ? 'Surowce w mieście (za ukończone miasto)'
            : 'Surowce do dopisania',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      GoodsCounters(
        values: _goods,
        maxFor: (g) => goodsRemaining(g, widget.players),
        onChanged: (g, v) => setState(() => _goods[g] = v),
      ),
      const SizedBox(height: 8),
      Text(
        isCity
            ? 'Surowce dostaje gracz, który domknął miasto – '
                  'nawet bez ludka w mieście:'
            : 'Surowce dla:',
      ),
      const SizedBox(height: 4),
      PlayerPicker(
        players: widget.players,
        selected: _goodsRecipient,
        onSelected: (p) => setState(() => _goodsRecipient = p),
      ),
    ];
  }

  List<Widget> _buildRingmaster() {
    return [
      _check('Dyrektor cyrku', _ringmaster, (v) => _ringmaster = v),
      if (_ringmaster) _ringmasterTiles(),
    ];
  }

  Widget _ringmasterTiles() {
    return _stepperRow(
      'Płytki cyrku i akrobatów pod i wokół dyrektora (po 2 pkt)',
      _circusTiles,
      (v) => _circusTiles = v,
      max: kMaxRingmasterTiles,
    );
  }

  // ----------------------------------------------------------- widgety

  Widget _check(String title, bool value, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: (v) => setState(() => onChanged(v ?? false)),
    );
  }

  Widget _stepperRow(
    String label,
    int value,
    ValueChanged<int> onChanged, {
    int max = 99,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
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

  Widget _valueBox(String label, int value, _Field field) {
    final isActive = _active == field;
    return GestureDetector(
      onTap: () => setState(() => _active = field),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center),
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
