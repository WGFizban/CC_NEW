import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/crown_tokens.dart';
import '../models/player.dart';
import 'counter_stepper.dart';
import 'meeple_icon.dart';
import 'player_picker.dart';

/// Nazwa żetonu w aktualnym języku.
String tokenName(BuildContext context, CrownToken token) {
  final l = context.l10n;
  return switch (token) {
    CrownToken.king => l.tokenKing,
    CrownToken.robber => l.tokenRobber,
  };
}

/// Ikona żetonu (tymczasowa, z zestawu Material; docelowa grafika po
/// decyzji).
IconData tokenIcon(CrownToken token) => switch (token) {
  CrownToken.king => Icons.workspace_premium,
  CrownToken.robber => Icons.visibility_off,
};

/// Okno przejęcia żetonu: nowa wielkość budowli (zawsze większa od
/// zapamiętanej) i gracz, który żeton przejmuje. Zwraca zmianę żetonu albo
/// `null` po „Bez żetonu".
Future<TokenChange?> showTokenDialog(
  BuildContext context, {
  required CrownToken token,
  required List<Player> players,
  required Player scorer,
  TokenHolding? current,
  int suggestedSize = 0,
}) {
  return showDialog<TokenChange>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _TokenDialog(
      token: token,
      players: players,
      scorer: scorer,
      current: current,
      suggestedSize: suggestedSize,
    ),
  );
}

class _TokenDialog extends StatefulWidget {
  final CrownToken token;
  final List<Player> players;
  final Player scorer;
  final TokenHolding? current;
  final int suggestedSize;

  const _TokenDialog({
    required this.token,
    required this.players,
    required this.scorer,
    required this.current,
    required this.suggestedSize,
  });

  @override
  State<_TokenDialog> createState() => _TokenDialogState();
}

class _TokenDialogState extends State<_TokenDialog> {
  late int _size;
  late Player _taker;

  int get _min => minTokenSize(widget.current);

  @override
  void initState() {
    super.initState();
    _size = widget.suggestedSize.clamp(_min, kMaxTokenSize);
    _taker = widget.scorer;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final holder = widget.current?.holder(widget.players);
    final isKing = widget.token == CrownToken.king;

    return AlertDialog(
      title: Row(
        children: [
          Icon(tokenIcon(widget.token)),
          const SizedBox(width: 8),
          Expanded(child: Text(tokenName(context, widget.token))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (holder == null)
              Text(l.tokenNobody)
            else
              Row(
                children: [
                  Text('${l.tokenCurrent} '),
                  MeepleIcon(color: holder.color, size: 22),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      l.tokenCurrentValue(holder.name, widget.current!.size),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Text(isKing ? l.tokenSizeKing : l.tokenSizeRobber),
            const SizedBox(height: 4),
            Center(
              child: CounterStepper(
                value: _size,
                min: _min,
                max: kMaxTokenSize,
                onChanged: (v) => setState(() => _size = v),
              ),
            ),
            Center(
              child: Text(
                l.tokenMustExceed(_min),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            Text(l.tokenWho),
            const SizedBox(height: 4),
            PlayerPicker(
              players: widget.players,
              selected: _taker,
              onSelected: (p) => setState(() => _taker = p),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.tokenSkip),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            TokenChange(
              widget.token,
              widget.current,
              TokenHolding(_taker.id, _size),
            ),
          ),
          child: Text(l.confirm),
        ),
      ],
    );
  }
}

/// Liczba płytek w zamkniętych miastach i drogach na koniec gry.
typedef CrownTiles = ({int cityTiles, int roadTiles});

/// Okno na koniec gry: ile płytek jest w zamkniętych miastach i zamkniętych
/// drogach (po 1 punkcie za płytkę dostaje właściciel odpowiedniego żetonu).
/// Pyta tylko o te żetony, które ktoś ma. Zwraca `null` po „Anuluj".
Future<CrownTiles?> askCrownTiles(
  BuildContext context, {
  required Player? king,
  required Player? robber,
}) {
  return showDialog<CrownTiles>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _CrownTilesDialog(king: king, robber: robber),
  );
}

class _CrownTilesDialog extends StatefulWidget {
  final Player? king;
  final Player? robber;

  const _CrownTilesDialog({required this.king, required this.robber});

  @override
  State<_CrownTilesDialog> createState() => _CrownTilesDialogState();
}

class _CrownTilesDialogState extends State<_CrownTilesDialog> {
  final _city = TextEditingController();
  final _road = TextEditingController();

  @override
  void dispose() {
    _city.dispose();
    _road.dispose();
    super.dispose();
  }

  int _value(TextEditingController c) => int.tryParse(c.text) ?? 0;

  Widget _field(
    BuildContext context, {
    required CrownToken token,
    required Player holder,
    required String label,
    required TextEditingController controller,
  }) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tokenIcon(token), size: 18),
              const SizedBox(width: 6),
              Text(
                tokenName(context, token),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              MeepleIcon(color: holder.color, size: 20),
              const SizedBox(width: 4),
              Flexible(child: Text(holder.name)),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(
              labelText: label,
              hintText: '0',
              helperText: l.crownTilesHelper,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.crownEndTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.crownEndBody),
            if (widget.king != null)
              _field(
                context,
                token: CrownToken.king,
                holder: widget.king!,
                label: l.crownCityTiles,
                controller: _city,
              ),
            if (widget.robber != null)
              _field(
                context,
                token: CrownToken.robber,
                holder: widget.robber!,
                label: l.crownRoadTiles,
                controller: _road,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            cityTiles: _value(_city),
            roadTiles: _value(_road),
          )),
          child: Text(l.confirm),
        ),
      ],
    );
  }
}
