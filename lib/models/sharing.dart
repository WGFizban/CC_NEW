import 'player.dart';

/// Najwięcej zamków jednego gracza przy jednej budowli.
const int kMaxCastlesPerFeature = 4;

/// Skąd gracz dostaje punkty budowli, przy której nie jest punktującym.
///
/// - współdzielenie: te same punkty co punktujący (np. remis o większość),
/// - zamek: punkty budowli za każdy zamek gracza stojący przy niej.
class PointsShare {
  final bool castle;
  final int castles;

  const PointsShare({this.castle = false, this.castles = 1});

  PointsShare copyWith({bool? castle, int? castles}) =>
      PointsShare(castle: castle ?? this.castle, castles: castles ?? this.castles);

  /// Punkty gracza przy [base] punktach budowli.
  int pointsFor(int base) => castle ? base * castles : base;
}

/// Dzieli punkty budowli między graczy. Zwraca punkty każdego gracza
/// (punktujący jest pierwszy).
///
/// - [base] – punkty budowli (to samo dostają współdzielący),
/// - [extras] – premie przypisane do ludka punktującego (wróżka, dyrektor
///   cyrku); dostaje je tylko punktujący, i to tylko wtedy, gdy nie punktuje
///   jako zamek (zamek nie ma tam ludka),
/// - [scorerAsCastle] / [scorerCastles] – punktujący dostaje punkty tylko
///   jako właściciel zamków (nikt nie miał w budowli ludka),
/// - [scorerExtraCastles] – punktujący ma ludka w budowli *i dodatkowo* zamki
///   przy niej: dostaje swoje punkty plus punkty budowli za każdy zamek
///   (nie łączy się z [scorerAsCastle]),
/// - [others] – pozostali gracze i sposób, w jaki dostają punkty.
Map<Player, int> splitPoints({
  required Player scorer,
  required int base,
  int extras = 0,
  bool scorerAsCastle = false,
  int scorerCastles = 1,
  int scorerExtraCastles = 0,
  Map<Player, PointsShare> others = const {},
}) {
  final result = <Player, int>{
    scorer: scorerAsCastle
        ? base * scorerCastles
        : base + extras + base * scorerExtraCastles,
  };
  for (final e in others.entries) {
    if (e.key == scorer) continue;
    result[e.key] = e.value.pointsFor(base);
  }
  return result;
}
