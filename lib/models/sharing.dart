import 'player.dart';

/// Najwięcej zamków jednego gracza przy jednej budowli.
const int kMaxCastlesPerFeature = 4;

/// Skąd gracz dostaje punkty budowli, przy której nie jest punktującym.
///
/// - współdzielenie: te same punkty co punktujący (np. remis o większość),
/// - zamek: punkty budowli za każdy zamek gracza stojący przy niej,
/// - oba naraz ([alsoShares] przy zamku): gracz współdzieli budowlę
///   (np. ma w niej mepla i ma remis) *i* ma przy niej zamki, więc dostaje
///   punkty budowli raz za współdzielenie plus za każdy zamek.
class PointsShare {
  final bool castle;
  final int castles;

  /// Ma sens tylko przy [castle]: gracz dodatkowo współdzieli budowlę.
  final bool alsoShares;

  const PointsShare({
    this.castle = false,
    this.castles = 1,
    this.alsoShares = false,
  });

  PointsShare copyWith({bool? castle, int? castles, bool? alsoShares}) =>
      PointsShare(
        castle: castle ?? this.castle,
        castles: castles ?? this.castles,
        alsoShares: alsoShares ?? this.alsoShares,
      );

  /// Punkty gracza przy [base] punktach budowli.
  int pointsFor(int base) {
    if (!castle) return base;
    return base * castles + (alsoShares ? base : 0);
  }
}

/// Dzieli punkty budowli między graczy. Zwraca punkty każdego gracza
/// (punktujący jest pierwszy).
///
/// - [base] – punkty budowli (to samo dostają współdzielący),
/// - [extras] – premie przypisane do mepla punktującego (wróżka, dyrektor
///   cyrku); dostaje je tylko punktujący, i to tylko wtedy, gdy nie punktuje
///   jako zamek (zamek nie ma tam mepla),
/// - [scorerAsCastle] / [scorerCastles] – punktujący dostaje punkty tylko
///   jako właściciel zamków (nikt nie miał w budowli mepla),
/// - [scorerExtraCastles] – punktujący ma mepla w budowli *i dodatkowo* zamki
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
