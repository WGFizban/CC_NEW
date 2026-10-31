import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import 'expansion.dart';
import 'gold.dart';
import 'goods.dart';
import 'history_entry.dart';
import 'player.dart';
import 'scoring.dart';
import 'standings.dart';
import 'summary.dart';

/// Kolumna tabeli podsumowania: nazwa oraz (opcjonalnie) rodzaj punktacji
/// albo surowiec, z którego bierze się ikona kolumny.
class SummaryColumn {
  final String title;
  final ScoringType? type;
  final Goods? goods;

  const SummaryColumn(this.title, {this.type, this.goods});
}

/// Wiersz tabeli podsumowania: gracz i wartości w kolejności kolumn
/// (ostatnia to wynik łączny).
class SummaryRow {
  final Player player;
  final List<int> values;

  const SummaryRow(this.player, this.values);

  int get total => values.last;
}

/// Tabela podsumowania gry: punkty każdego gracza według rodzaju punktacji,
/// z premią za surowce, wartością złota i wynikiem łącznym. Wiersze są
/// posortowane od zwycięzcy. Używana na ekranie podsumowania i w PDF-ie.
class SummaryTable {
  /// Kolumny bez kolumny z nazwą gracza; ostatnia to wynik łączny.
  final List<SummaryColumn> columns;
  final List<SummaryRow> rows;

  const SummaryTable(this.columns, this.rows);

  /// Największa wartość w kolumnie [column] (do wyróżnienia najlepszych).
  int best(int column) => rows.isEmpty
      ? 0
      : rows.map((r) => r.values[column]).reduce((a, b) => a > b ? a : b);

  factory SummaryTable.build({
    required AppLocalizations l,
    required List<Player> players,
    required List<HistoryEntry> log,
    required Set<Expansion> expansions,
  }) {
    final byType = pointsByType(log, players);
    // Surowce i złoto nie dają punktów w trakcie gry – mają osobne kolumny
    // z premią i wartością złota, żeby wiersze sumowały się do wyniku.
    final types = [
      for (final t in ScoringType.availableFor(expansions))
        if (t != ScoringType.goods &&
            t != ScoringType.gold &&
            t != ScoringType.crown)
          t,
    ];
    final showGoods = expansions.contains(Expansion.tradersBuilders);
    final showGold = expansions.contains(Expansion.goldMines);
    final hasOther = players.any((p) => (byType[p.id]?[null] ?? 0) != 0);
    final goodsTypes = showGoods ? Goods.values : const <Goods>[];

    final scores = {for (final p in players) p: finalScore(p, players)};
    final ranking = [...players]
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    int goodsPart(Player p, Goods g) =>
        goodsLeaders(g, players).contains(p) ? kGoodsBonus : 0;

    List<int> values(Player p) => [
      for (final t in types) byType[p.id]?[t] ?? 0,
      for (final g in goodsTypes) goodsPart(p, g),
      if (showGold) goldPoints(p.gold),
      if (hasOther) byType[p.id]?[null] ?? 0,
      scores[p]!,
    ];

    return SummaryTable(
      [
        for (final t in types) SummaryColumn(t.title(l), type: t),
        for (final g in goodsTypes)
          SummaryColumn(g.title(l), goods: g),
        if (showGold)
          SummaryColumn(ScoringType.gold.title(l), type: ScoringType.gold),
        if (hasOther) SummaryColumn(l.other),
        SummaryColumn(l.colTotal),
      ],
      [for (final p in ranking) SummaryRow(p, values(p))],
    );
  }
}
