import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/crown_tokens.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';
import '../widgets/meeple_icon.dart';
import '../widgets/number_keypad.dart';
import '../widgets/scoring_app_bar.dart';
import '../widgets/token_dialogs.dart';

/// Liczba ukończonych zamków i dróg na całej planszy (na koniec gry).
typedef CrownCounts = ({int cities, int roads});

/// Największa wpisywana liczba ukończonych budowli.
const int kMaxCrownCount = 99;

/// Ekran na koniec gry z dodatkiem „Król i Baron rabusiów": ile ukończonych
/// zamków i dróg jest na całej planszy (także cudzych). Właściciel żetonu
/// Króla dostaje po punkcie za zamek, właściciel żetonu Barona rabusiów za
/// drogę. Pyta tylko o te żetony, które ktoś ma. Zwraca [CrownCounts] albo
/// `null` po „Anuluj".
class CrownEndScreen extends StatefulWidget {
  final Player? king;
  final Player? robber;

  const CrownEndScreen({super.key, required this.king, required this.robber});

  @override
  State<CrownEndScreen> createState() => _CrownEndScreenState();
}

class _CrownEndScreenState extends State<CrownEndScreen> {
  int _cities = 0;
  int _roads = 0;
  late CrownToken _active = widget.king != null
      ? CrownToken.king
      : CrownToken.robber;

  int _valueOf(CrownToken t) => t == CrownToken.king ? _cities : _roads;

  void _onKey(String key) {
    setState(() {
      final v = applyKey(_valueOf(_active), key, max: kMaxCrownCount);
      if (_active == CrownToken.king) {
        _cities = v;
      } else {
        _roads = v;
      }
    });
  }

  void _confirm() =>
      Navigator.pop<CrownCounts>(context, (cities: _cities, roads: _roads));

  Widget _field(CrownToken token, Player holder) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final active = _active == token;
    final label = token == CrownToken.king
        ? l.crownCityTiles
        : l.crownRoadTiles;
    return GestureDetector(
      onTap: () => setState(() => _active = token),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: playerCardColor(context),
          border: Border.all(
            color: active ? scheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: Row(
          children: [
            tokenIcon(token, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      MeepleIcon(color: holder.color, size: 20),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          holder.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_valueOf(token)}',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Neutralna ramka (kolor wierszy graczy), jak na innych ekranach
    // wspólnych dla wielu graczy.
    final frameColor = playerCardColor(context);
    final frameSide = BorderSide(color: frameColor, width: 4);

    return Scaffold(
      bottomNavigationBar: scoringBottomBar(
        context,
        frameColor: frameColor,
        onConfirm: _confirm,
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: frameSide, left: frameSide, right: frameSide),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      l.crownEndTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(l.crownEndBody),
                    const SizedBox(height: 4),
                    Text(
                      l.crownCountHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    if (widget.king != null)
                      _field(CrownToken.king, widget.king!),
                    if (widget.robber != null)
                      _field(CrownToken.robber, widget.robber!),
                  ],
                ),
              ),
              NumberKeypad(onKey: _onKey),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
