import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/scoring.dart';

enum _Field { tiles, banners }

/// Ekran liczenia punktów. Zwraca liczbę punktów przez `Navigator.pop`
/// (albo `null`, gdy użytkownik wyjdzie bez zatwierdzenia).
class AddPointsScreen extends StatefulWidget {
  final Player player;
  final ScoringType type;

  const AddPointsScreen({super.key, required this.player, required this.type});

  @override
  State<AddPointsScreen> createState() => _AddPointsScreenState();
}

class _AddPointsScreenState extends State<AddPointsScreen> {
  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['C', '0', '<'],
  ];

  int _tiles = 0;
  int _banners = 0;
  bool _completed = true;

  /// Katedra (miasto), karczma (droga) lub świnka (pola).
  bool _bonus = false;
  _Field _active = _Field.tiles;

  int get _points => calculatePoints(
    widget.type,
    tiles: _tiles,
    banners: _banners,
    completed: _completed,
    bonus: _bonus,
  );

  void _onKeyTap(String key) {
    int update(int value) => switch (key) {
      'C' => 0,
      '<' => value ~/ 10,
      _ => math.min(value * 10 + int.parse(key), 999),
    };
    setState(() {
      if (_active == _Field.banners) {
        _banners = update(_banners);
      } else {
        _tiles = update(_tiles);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.player.color;
    final points = _points;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.player.name} — ${widget.type.displayName}'),
        backgroundColor: color.withValues(alpha: 0.2),
      ),
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: color, width: 4)),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ..._buildInputs(),
              const SizedBox(height: 20),
              Text(
                'Wynik: $points pkt',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildKeyboard(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: points > 0
                    ? () => Navigator.pop(context, points)
                    : null,
                child: const Text('Zatwierdź'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInputs() {
    switch (widget.type) {
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
          if (_completed)
            const Text(
              'Ukończony klasztor = 9 pkt',
              style: TextStyle(fontSize: 20),
            )
          else
            _valueBoxes([_valueBox('Płytki', _tiles, _Field.tiles)]),
        ];

      case ScoringType.meadow:
        return [
          _valueBoxes([_valueBox('Ukończone miasta', _tiles, _Field.tiles)]),
          _check('Świnka', _bonus, (v) => _bonus = v),
        ];

      case ScoringType.fairy:
      case ScoringType.sheep:
        return [
          _valueBoxes([_valueBox('Punkty', _tiles, _Field.tiles)]),
        ];
    }
  }

  Widget _check(String title, bool value, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: (v) => setState(() => onChanged(v ?? false)),
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
          Text(label),
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

  Widget _buildKeyboard() {
    return Column(
      children: [
        for (final row in _keys)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final key in row)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: ElevatedButton(
                    onPressed: () => _onKeyTap(key),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: Text(key),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
