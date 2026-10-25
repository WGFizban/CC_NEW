import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../models/scoring.dart';
import '../models/tower.dart';
import '../widgets/auto_size_text.dart';
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
        context.l10n.towerEventLabel(_buyer.name, holder.name, kRansomPoints),
        [
          ScoreChange(_buyer, -kRansomPoints),
          ScoreChange(holder, kRansomPoints),
        ],
        category: context.l10n.scTower,
        type: ScoringType.tower,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final holderName = _holder?.name ?? l.towerHolderDefault;

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(l.towerTitle),
        actions: [ConfirmAction(onPressed: _canConfirm ? _confirm : null)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l.towerWhoBuys,
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
            l.towerFromWhom,
            l.towerHint(kRansomPoints),
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
              l.ransomValue(kRansomPoints),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l.towerDesc(_buyer.name, kRansomPoints, holderName),
              textAlign: TextAlign.center,
            ),
          ),
          if (!_affordable)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l.towerShort(_buyer.name, _buyer.points, kRansomPoints),
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
