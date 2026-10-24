import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/score_event.dart';
import '../widgets/confirm_action.dart';
import '../widgets/info_hint.dart';
import '../widgets/number_keypad.dart';
import '../widgets/player_picker.dart';

enum _Deal { buy, sell, solo }

/// Rozliczenie licytacji na bazarze.
///
/// Wybierający płytkę ([_chooser]) może ją kupić od najwyżej licytującego
/// (płaci mu cenę) albo mu ją sprzedać (dostaje cenę). Jeśli licytował tylko
/// on sam, płaci cenę, a nikt nie zyskuje. Wynik może spaść poniżej zera.
class BazaarScreen extends StatefulWidget {
  final Player player;
  final List<Player> players;

  const BazaarScreen({super.key, required this.player, required this.players});

  @override
  State<BazaarScreen> createState() => _BazaarScreenState();
}

class _BazaarScreenState extends State<BazaarScreen> {
  late Player _chooser = widget.player;
  Player? _bidder;
  _Deal _deal = _Deal.buy;
  int _price = 0;

  bool get _needsBidder => _deal != _Deal.solo;

  bool get _canConfirm =>
      _price > 0 && (!_needsBidder || (_bidder != null && _bidder != _chooser));

  String get _description {
    final bidder = _bidder?.name ?? 'licytujący';
    return switch (_deal) {
      _Deal.buy => '${_chooser.name} płaci $_price pkt, a $bidder je dostaje.',
      _Deal.sell =>
        '${_chooser.name} dostaje $_price pkt, a $bidder je płaci.',
      _Deal.solo =>
        '${_chooser.name} płaci $_price pkt, nikt nie zyskuje.',
    };
  }

  void _confirm() {
    final bidder = _bidder;
    final List<ScoreChange> changes;
    final String label;
    switch (_deal) {
      case _Deal.buy:
        changes = [
          ScoreChange(_chooser, -_price),
          if (bidder != null) ScoreChange(bidder, _price),
        ];
        label = 'Bazar: ${_chooser.name} kupuje od ${bidder?.name} za $_price';
      case _Deal.sell:
        changes = [
          ScoreChange(_chooser, _price),
          if (bidder != null) ScoreChange(bidder, -_price),
        ];
        label =
            'Bazar: ${_chooser.name} sprzedaje ${bidder?.name} za $_price';
      case _Deal.solo:
        changes = [ScoreChange(_chooser, -_price)];
        label = 'Bazar: ${_chooser.name} płaci $_price (jedyny licytujący)';
    }
    Navigator.pop(context, ScoreEvent(label, changes, category: 'Bazar'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bazar – licytacja'),
        actions: [ConfirmAction(onPressed: _canConfirm ? _confirm : null)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Kto wybierał płytkę?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          PlayerPicker(
            players: widget.players,
            selected: _chooser,
            onSelected: (p) => setState(() {
              _chooser = p;
              if (_bidder == p) _bidder = null;
            }),
          ),
          const SizedBox(height: 16),
          const LabelWithHint(
            'Jak rozliczono licytację?',
            'Kupuje: wybierający płaci najwyżej licytującemu. '
                'Sprzedaje: najwyżej licytujący płaci wybierającemu. '
                'Jedyny: licytował tylko wybierający – płaci, a nikt nie '
                'zyskuje. Wynik może spaść poniżej zera.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<_Deal>(
            segments: const [
              ButtonSegment(value: _Deal.buy, label: Text('Kupuje')),
              ButtonSegment(value: _Deal.sell, label: Text('Sprzedaje')),
              ButtonSegment(value: _Deal.solo, label: Text('Jedyny')),
            ],
            selected: {_deal},
            onSelectionChanged: (s) => setState(() => _deal = s.first),
          ),
          if (_needsBidder) ...[
            const SizedBox(height: 16),
            const Text(
              'Kto zaoferował najwyższą cenę?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            PlayerPicker(
              players: widget.players,
              selected: _bidder,
              exclude: _chooser,
              onSelected: (p) => setState(() => _bidder = p),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Cena: $_price pkt',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text(_description, textAlign: TextAlign.center)),
          const SizedBox(height: 12),
          NumberKeypad(
            onKey: (key) =>
                setState(() => _price = applyKey(_price, key, max: 9999)),
          ),
        ],
      ),
    );
  }
}
