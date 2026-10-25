import 'package:flutter/material.dart';

import '../l10n/tr.dart';
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
    final bidder = _bidder?.name ?? tr('licytujący', 'the bidder');
    return switch (_deal) {
      _Deal.buy => tr(
        '${_chooser.name} płaci $_price pkt, a $bidder je dostaje.',
        '${_chooser.name} pays $_price pts and $bidder receives them.',
      ),
      _Deal.sell => tr(
        '${_chooser.name} dostaje $_price pkt, a $bidder je płaci.',
        '${_chooser.name} receives $_price pts and $bidder pays them.',
      ),
      _Deal.solo => tr(
        '${_chooser.name} płaci $_price pkt, nikt nie zyskuje.',
        '${_chooser.name} pays $_price pts, nobody gains.',
      ),
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
        label = tr(
          'Bazar: ${_chooser.name} kupuje od ${bidder?.name} za $_price',
          'Bazaar: ${_chooser.name} buys from ${bidder?.name} for $_price',
        );
      case _Deal.sell:
        changes = [
          ScoreChange(_chooser, _price),
          if (bidder != null) ScoreChange(bidder, -_price),
        ];
        label = tr(
          'Bazar: ${_chooser.name} sprzedaje ${bidder?.name} za $_price',
          'Bazaar: ${_chooser.name} sells to ${bidder?.name} for $_price',
        );
      case _Deal.solo:
        changes = [ScoreChange(_chooser, -_price)];
        label = tr(
          'Bazar: ${_chooser.name} płaci $_price (jedyny licytujący)',
          'Bazaar: ${_chooser.name} pays $_price (sole bidder)',
        );
    }
    Navigator.pop(context, ScoreEvent(label, changes, category: tr('Bazar', 'Bazaar')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Bazar – licytacja', 'Bazaar – auction')),
        actions: [ConfirmAction(onPressed: _canConfirm ? _confirm : null)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr('Kto wybierał płytkę?', 'Who picked the tile?'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          LabelWithHint(
            tr('Jak rozliczono licytację?', 'How was the auction settled?'),
            tr(
              'Kupuje: wybierający płaci najwyżej licytującemu. '
                  'Sprzedaje: najwyżej licytujący płaci wybierającemu. '
                  'Jedyny: licytował tylko wybierający – płaci, a nikt nie '
                  'zyskuje. Wynik może spaść poniżej zera.',
              'Buys: the chooser pays the highest bidder. '
                  'Sells: the highest bidder pays the chooser. '
                  'Sole: only the chooser bid – they pay and nobody gains. '
                  'The score can drop below zero.',
            ),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<_Deal>(
            segments: [
              ButtonSegment(
                value: _Deal.buy,
                label: Text(tr('Kupuje', 'Buys')),
              ),
              ButtonSegment(
                value: _Deal.sell,
                label: Text(tr('Sprzedaje', 'Sells')),
              ),
              ButtonSegment(
                value: _Deal.solo,
                label: Text(tr('Jedyny', 'Sole')),
              ),
            ],
            selected: {_deal},
            onSelectionChanged: (s) => setState(() => _deal = s.first),
          ),
          if (_needsBidder) ...[
            const SizedBox(height: 16),
            Text(
              tr('Kto zaoferował najwyższą cenę?', 'Who offered the highest price?'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              '${tr('Cena', 'Price')}: $_price ${tr('pkt', 'pts')}',
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
