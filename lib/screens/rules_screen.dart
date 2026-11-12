import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../widgets/adaptive_layout.dart';
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
    Expansion.flyingMachines => l.rulesFlyingMachines,
    Expansion.mageWitch => l.rulesMageWitch,
    Expansion.goldMines => l.rulesGold,
    Expansion.monasteries => l.rulesMonasteries,
    Expansion.germanCastles => l.rulesGermanCastles,
    Expansion.germanCathedrals => l.rulesGermanCathedrals,
  };

  static String _parts(AppLocalizations l, Expansion e) => switch (e) {
    Expansion.innsCathedrals => l.rulesPartsInns,
    Expansion.tradersBuilders => l.rulesPartsTraders,
    Expansion.princessDragon => l.rulesPartsPrincess,
    Expansion.tower => l.rulesPartsTower,
    Expansion.abbeyMayor => l.rulesPartsAbbey,
    Expansion.kingRobber => l.rulesPartsKingRobber,
    Expansion.bridgesCastlesBazaars => l.rulesPartsBridges,
    Expansion.hillsSheep => l.rulesPartsHills,
    Expansion.circus => l.rulesPartsCircus,
    Expansion.flyingMachines => l.rulesPartsFlyingMachines,
    Expansion.mageWitch => l.rulesPartsMageWitch,
    Expansion.goldMines => l.rulesPartsGold,
    Expansion.monasteries => l.rulesPartsMonasteries,
    Expansion.germanCastles => l.rulesPartsGermanCastles,
    Expansion.germanCathedrals => l.rulesPartsGermanCathedrals,
  };

  /// Oficjalna wiki z zasadami, na której opieramy punktację.
  static final Uri _wikiUrl = Uri.parse('https://wikicarpedia.com/');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final expansions = [...Expansion.values]
      ..sort((a, b) {
        if (a.mini != b.mini) return a.mini ? 1 : -1;
        return a.number.compareTo(b.number);
      });

    Widget section(
      String title,
      String body, {
      String? parts,
      bool open = false,
    }) {
      return ExpansionTile(
        initiallyExpanded: open,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body, style: const TextStyle(height: 1.4)),
          if (parts != null) ...[
            const SizedBox(height: 12),
            Text(
              l.rulesPartsTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(parts, style: const TextStyle(height: 1.4)),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.rulesTitle)),
      body: ContentWidth(child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.rulesMenuHint),
          ),
          section(
            l.baseGame,
            l.rulesBase,
            parts: l.rulesPartsBase,
            open: true,
          ),
          for (final e in expansions)
            section(e.title(l), _rules(l, e), parts: _parts(l, e)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l.rulesPartsNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l.rulesMoreTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(l.rulesMoreBody, style: const TextStyle(height: 1.4)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: Text(l.rulesMoreLink),
                onPressed: () => launchUrl(
                  _wikiUrl,
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
