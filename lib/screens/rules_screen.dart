import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../models/expansion.dart';

/// Skrót zasad punktowania w sekcjach: gra podstawowa i kolejne dodatki.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  static String _rules(AppLocalizations l, Expansion e) => switch (e) {
    Expansion.innsCathedrals => l.rulesInns,
    Expansion.tradersBuilders => l.rulesTraders,
    Expansion.princessDragon => l.rulesPrincess,
    Expansion.tower => l.rulesTower,
    Expansion.abbeyMayor => l.rulesAbbey,
    Expansion.kingRobber => l.rulesKingRobber,
    Expansion.bridgesCastlesBazaars => l.rulesBridges,
    Expansion.hillsSheep => l.rulesHills,
    Expansion.circus => l.rulesCircus,
    Expansion.goldMines => l.rulesGold,
    Expansion.monasteries => l.rulesMonasteries,
    Expansion.germanCastles => l.rulesGermanCastles,
    Expansion.germanCathedrals => l.rulesGermanCathedrals,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final expansions = [...Expansion.values]
      ..sort((a, b) {
        if (a.mini != b.mini) return a.mini ? 1 : -1;
        return a.number.compareTo(b.number);
      });

    Widget section(String title, String body, {bool open = false}) {
      return ExpansionTile(
        initiallyExpanded: open,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(body, style: const TextStyle(height: 1.4))],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.rulesTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.rulesMenuHint),
          ),
          section(l.baseGame, l.rulesBase, open: true),
          for (final e in expansions) section(e.title(l), _rules(l, e)),
        ],
      ),
    );
  }
}
