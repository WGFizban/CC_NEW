import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../widgets/adaptive_layout.dart';
import '../l10n/labels.dart';
import '../models/expansion.dart';
import '../widgets/info_hint.dart';

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

  static String? _parts(AppLocalizations l, Expansion e) => switch (e) {
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
    Expansion.germanCathedrals => null,
  };

  /// Liczba płytek w dodatku (wg klasycznych wydań), pokazywana w tytule.
  static int _tiles(Expansion e) => switch (e) {
    Expansion.innsCathedrals => 18,
    Expansion.tradersBuilders => 24,
    Expansion.princessDragon => 30,
    Expansion.tower => 18,
    Expansion.abbeyMayor => 12,
    Expansion.kingRobber => 10,
    Expansion.bridgesCastlesBazaars => 12,
    Expansion.hillsSheep => 18,
    Expansion.circus => 20,
    Expansion.flyingMachines => 8,
    Expansion.mageWitch => 8,
    Expansion.goldMines => 8,
    Expansion.monasteries => 6,
    Expansion.germanCastles => 6,
    Expansion.germanCathedrals => 6,
  };

  /// Rozdział elementów na gracza jako mała tabelka (pierwszy wiersz: liczba
  /// graczy, kolejne: element i jego liczba na gracza).
  static _PartsTable? _table(AppLocalizations l, Expansion e) => switch (e) {
    Expansion.tower => _PartsTable(
      header: const ['2', '3', '4', '5', '6'],
      rows: [(l.rulesTableFloors, const ['10', '9', '7', '6', '5'])],
    ),
    Expansion.bridgesCastlesBazaars => _PartsTable(
      header: const ['2–4', '5–6'],
      rows: [
        (l.rulesTableBridges, const ['3', '2']),
        (l.rulesTableCastles, const ['3', '2']),
      ],
    ),
    Expansion.germanCastles => _PartsTable(
      header: const ['2–3', '4–6'],
      rows: [(l.rulesTableCastles, const ['2', '1'])],
    ),
    _ => null,
  };

  /// Oficjalna wiki z zasadami, na której opieramy punktację.
  static final Uri _wikiUrl = Uri.parse('https://wikicarpedia.com/car/Main_Page');

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
      _PartsTable? table,
      bool open = false,
    }) {
      return ExpansionTile(
        initiallyExpanded: open,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elementy są pierwsze, przed zasadami, i wyróżnione tłem.
          if (parts != null || table != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.rulesPartsTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (parts != null)
                    Text(parts, style: const TextStyle(height: 1.4)),
                  if (table != null) ...[
                    const SizedBox(height: 8),
                    _PartsTableView(
                      table: table,
                      playersLabel: l.rulesTablePlayers,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(body, style: const TextStyle(height: 1.4)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.rulesTitle)),
      body: ContentWidth(child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LabelWithHint(l.rulesMenuHint, l.rulesPartsNote),
          ),
          section(
            l.rulesBaseTitle,
            l.rulesBase,
            parts: l.rulesPartsBase,
            open: true,
          ),
          for (final e in expansions)
            section(
              '${e.title(l)} (${l.tilesCount(_tiles(e))})',
              _rules(l, e),
              parts: _parts(l, e),
              table: _table(l, e),
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

/// Dane małej tabelki rozdziału elementów na gracza.
class _PartsTable {
  /// Liczby graczy (nagłówki kolumn).
  final List<String> header;

  /// Wiersze: nazwa elementu i jego liczba na gracza w każdej kolumnie.
  final List<(String, List<String>)> rows;

  const _PartsTable({required this.header, required this.rows});
}

class _PartsTableView extends StatelessWidget {
  final _PartsTable table;
  final String playersLabel;

  const _PartsTableView({required this.table, required this.playersLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = BorderSide(color: theme.colorScheme.outlineVariant);
    Widget cell(String text, {bool bold = false, bool start = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            text,
            textAlign: start ? TextAlign.start : TextAlign.center,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        );

    return Align(
      alignment: Alignment.centerLeft,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder(
          top: border,
          bottom: border,
          left: border,
          right: border,
          horizontalInside: border,
          verticalInside: border,
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
            ),
            children: [
              cell(playersLabel, bold: true, start: true),
              for (final h in table.header) cell(h, bold: true),
            ],
          ),
          for (final (label, values) in table.rows)
            TableRow(
              children: [
                cell(label, start: true),
                for (final v in values) cell(v),
              ],
            ),
        ],
      ),
    );
  }
}
