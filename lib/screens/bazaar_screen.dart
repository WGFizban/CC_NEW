import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../models/scoring.dart';
import '../widgets/scoring_app_bar.dart';
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
    final l = context.l10n;
    final bidder = _bidder?.name ?? l.theBidder;
    return switch (_deal) {
      _Deal.buy => l.bazaarBuyDesc(_chooser.name, _price, bidder),
      _Deal.sell => l.bazaarSellDesc(_chooser.name, _price, bidder),
      _Deal.solo => l.bazaarSoleDesc(_chooser.name, _price),
    };
  }

  void _confirm() {
    final l = context.l10n;
    final bidder = _bidder;
    final bidderName = bidder?.name ?? '';
    final List<ScoreChange> changes;
    final String label;
    switch (_deal) {
      case _Deal.buy:
        changes = [
          ScoreChange(_chooser, -_price),
          if (bidder != null) ScoreChange(bidder, _price),
        ];
        label = l.bazaarBuyLabel(_chooser.name, bidderName, _price);
      case _Deal.sell:
        changes = [
          ScoreChange(_chooser, _price),
          if (bidder != null) ScoreChange(bidder, -_price),
        ];
        label = l.bazaarSellLabel(_chooser.name, bidderName, _price);
      case _Deal.solo:
        changes = [ScoreChange(_chooser, -_price)];
        label = l.bazaarSoleLabel(_chooser.name, _price);
    }
    Navigator.pop(
      context,
      ScoreEvent(
        label,
        changes,
        category: l.scBazaar,
        type: ScoringType.bazaar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      bottomNavigationBar: scoringBottomBar(
        context,
        onConfirm: _canConfirm ? _confirm : null,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l.whoPickedTile,
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
            l.auctionSettledQ,
            l.auctionHint,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<_Deal>(
            segments: [
              ButtonSegment(
                value: _Deal.buy,
                label: Text(l.dealBuys),
              ),
              ButtonSegment(
                value: _Deal.sell,
                label: Text(l.dealSells),
              ),
              ButtonSegment(
                value: _Deal.solo,
                label: Text(l.dealSole),
              ),
            ],
            selected: {_deal},
            onSelectionChanged: (s) => setState(() => _deal = s.first),
          ),
          if (_needsBidder) ...[
            const SizedBox(height: 16),
            Text(
              l.whoOfferedHighest,
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
              l.priceValue(_price),
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
      ),
    );
  }
}
