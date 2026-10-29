import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/l10n.dart';
import '../models/crown_tokens.dart';
import '../models/player.dart';
import 'counter_stepper.dart';
import 'info_hint.dart';
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

/// Grafika żetonu: Król (korona w tarczy) i Baron rabusiów (mieszek i
/// sztylet na tle drogi).
Widget tokenIcon(CrownToken token, {double size = 24}) => SvgPicture.asset(
  switch (token) {
    CrownToken.king => 'assets/icons/game/token_king.svg',
    CrownToken.robber => 'assets/icons/game/token_robber.svg',
  },
  width: size,
  height: size,
);

/// Okno przejęcia żetonu: wielkość budowli i gracz, który żeton przejmuje.
/// Zwraca zmianę żetonu albo `null` po „Anuluj".
///
/// - Z ustalonym [token] i [fixedSize] (przejęcie przy punktowaniu ukończonej
///   budowli) wielkość jest narzucona i nie da się jej zmienić.
/// - Z [token] = `null` (kafelek „Król/Rabuś") okno ma przełącznik Król/Rabuś
///   i licznik +/-, który nie zejdzie poniżej wielkości potrzebnej do
///   przejęcia żetonu.
Future<TokenChange?> showTokenDialog(
  BuildContext context, {
  CrownToken? token,
  required Map<CrownToken, TokenHolding> tokens,
  required List<Player> players,
  required Player scorer,
  int? fixedSize,
}) {
  return showDialog<TokenChange>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _TokenDialog(
      token: token,
      tokens: tokens,
      players: players,
      scorer: scorer,
      fixedSize: fixedSize,
    ),
  );
}

class _TokenDialog extends StatefulWidget {
  final CrownToken? token;
  final Map<CrownToken, TokenHolding> tokens;
  final List<Player> players;
  final Player scorer;
  final int? fixedSize;

  const _TokenDialog({
    required this.token,
    required this.tokens,
    required this.players,
    required this.scorer,
    required this.fixedSize,
  });

  @override
  State<_TokenDialog> createState() => _TokenDialogState();
}

class _TokenDialogState extends State<_TokenDialog> {
  late CrownToken _token = widget.token ?? CrownToken.king;
  late int _size;
  late Player _taker;

  bool get _choose => widget.token == null;
  TokenHolding? get _current => widget.tokens[_token];

  /// Najmniejsza wielkość, która pozwala przejąć żeton (o 1 większa niż
  /// u obecnego właściciela).
  int get _min => minTokenSize(_current).clamp(1, kMaxTokenSize);

  @override
  void initState() {
    super.initState();
    _size = widget.fixedSize ?? _min;
    _taker = widget.scorer;
  }

  void _pickToken(CrownToken token) => setState(() {
    _token = token;
    _size = _min;
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final current = _current;
    final holder = current?.holder(widget.players);
    final isKing = _token == CrownToken.king;

    return AlertDialog(
      title: Row(
        children: [
          tokenIcon(_token, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _choose ? l.crownTransferTitle : tokenName(context, _token),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_choose) ...[
              Text(l.tokenWhich),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<CrownToken>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: CrownToken.king,
                      icon: tokenIcon(CrownToken.king, size: 22),
                      label: Text(l.tokenKingShort),
                    ),
                    ButtonSegment(
                      value: CrownToken.robber,
                      icon: tokenIcon(CrownToken.robber, size: 22),
                      label: Text(l.tokenRobberShort),
                    ),
                  ],
                  selected: {_token},
                  onSelectionChanged: (s) => _pickToken(s.first),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                      l.tokenCurrentValue(holder.name, current!.size),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (_choose) ...[
              LabelWithHint(
                isKing ? l.tokenSizeKing : l.tokenSizeRobber,
                isKing ? l.tokenMinHintKing(_min) : l.tokenMinHintRobber(_min),
              ),
              const SizedBox(height: 4),
              Center(
                child: CounterStepper(
                  value: _size,
                  min: _min,
                  max: kMaxTokenSize,
                  onChanged: (v) => setState(() => _size = v),
                ),
              ),
            ] else ...[
              Text(isKing ? l.tokenSizeKing : l.tokenSizeRobber),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '$_size',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            TokenChange(_token, _current, TokenHolding(_taker.id, _size)),
          ),
          child: Text(l.confirm),
        ),
      ],
    );
  }
}
