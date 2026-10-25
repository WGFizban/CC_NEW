import 'package:flutter/material.dart';

import '../l10n/tr.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../models/tower.dart';
import '../widgets/confirm_action.dart';
import '../widgets/info_hint.dart';
import '../widgets/player_picker.dart';

/// Wykup uwięzionego mepla z dodatku „Wieża".
///
/// Wykupujący ([_buyer]) płaci [kRansomPoints] punkty temu, kto trzyma jeńca
/// ([_holder]). Wymiana mepel za mepel odbywa się bez aplikacji. Wykupu nie
/// zatwierdzisz, gdy wykupujący nie ma wymaganych punktów.
class TowerScreen extends StatefulWidget {
  final Player player;
  final List<Player> players;

  const TowerScreen({super.key, required this.player, required this.players});

  @override
  State<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends State<TowerScreen> {
  late Player _buyer = widget.player;
  Player? _holder;

  bool get _affordable => canAffordRansom(_buyer);

  bool get _canConfirm => _holder != null && _holder != _buyer && _affordable;

  void _confirm() {
    final holder = _holder;
    if (holder == null) return;
    Navigator.pop(
      context,
      ScoreEvent(
        tr(
          'Wieża: ${_buyer.name} wykupuje mepla od ${holder.name} '
              '(−$kRansomPoints)',
          'Tower: ${_buyer.name} buys back a meeple from ${holder.name} '
              '(−$kRansomPoints)',
        ),
        [
          ScoreChange(_buyer, -kRansomPoints),
          ScoreChange(holder, kRansomPoints),
        ],
        category: tr('Wieża', 'Tower'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final holderName = _holder?.name ?? tr('właściciel jeńca', 'the holder');
    final pts = tr('pkt', 'pts');

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Wieża – wykup mepla', 'Tower – ransom a meeple')),
        actions: [ConfirmAction(onPressed: _canConfirm ? _confirm : null)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr('Kto wykupuje mepla?', 'Who is buying back a meeple?'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          PlayerPicker(
            players: widget.players,
            selected: _buyer,
            onSelected: (p) => setState(() {
              _buyer = p;
              if (_holder == p) _holder = null;
            }),
          ),
          const SizedBox(height: 16),
          LabelWithHint(
            tr('Od kogo wykupuje?', 'Whose prisoner is it?'),
            tr(
              'Okup za uwięzionego mepla to zawsze $kRansomPoints pkt – '
                  'także za dużego mepla (nie jest podwajany).\n'
                  'Można wykupić: zwykłego mepla, dużego mepla, wóz '
                  'i burmistrza.\n'
                  'Nie można wykupić budowniczego ani świni – nie da się ich '
                  'uwięzić.\n'
                  'Wykup robisz w swojej turze, jeden na turę; wykupionego '
                  'mepla możesz od razu wystawić.\n'
                  'Gdy dwaj gracze trzymają sobie nawzajem po jednym '
                  'jeńcu, wymiana mepel za mepel odbywa się automatycznie, '
                  'bez aplikacji.\n'
                  'Bez $kRansomPoints punktów nie możesz wykupić mepla.',
              'The ransom for a captured meeple is always $kRansomPoints '
                  'pts – also for a big meeple (it is not doubled).\n'
                  'You can buy back: a normal meeple, a big meeple, a wagon '
                  'and a mayor.\n'
                  'You cannot buy back a builder or a pig – they cannot be '
                  'captured.\n'
                  'You buy back on your own turn, once per turn; the freed '
                  'meeple can be deployed right away.\n'
                  'When two players hold one of each other\'s meeples, the '
                  'meeple-for-meeple swap happens automatically, without the '
                  'app.\n'
                  'Without $kRansomPoints points you cannot buy a meeple back.',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          PlayerPicker(
            players: widget.players,
            selected: _holder,
            exclude: _buyer,
            onSelected: (p) => setState(() => _holder = p),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${tr('Okup', 'Ransom')}: $kRansomPoints $pts',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              tr(
                '${_buyer.name} płaci $kRansomPoints pkt, a $holderName '
                    'je dostaje.',
                '${_buyer.name} pays $kRansomPoints pts and $holderName '
                    'receives them.',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (!_affordable)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                tr(
                  '${_buyer.name} ma tylko ${_buyer.points} pkt – do wykupu '
                      'potrzeba $kRansomPoints.',
                  '${_buyer.name} has only ${_buyer.points} pts – '
                      '$kRansomPoints are needed to buy back a meeple.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
