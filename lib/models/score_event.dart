import 'circus.dart';
import 'goods.dart';
import 'player.dart';
import 'scoring.dart';

/// Zmiana wyniku jednego gracza: punkty i/lub surowce.
class ScoreChange {
  final Player player;
  final int points;
  final Map<Goods, int> goods;

  /// Sztabki złota (minidodatek „Kopalnie złota").
  final int gold;

  const ScoreChange(
    this.player,
    this.points, {
    this.goods = const {},
    this.gold = 0,
  });
}

/// Jedno zatwierdzenie punktów. Może dotyczyć wielu graczy naraz
/// (cyrk, piramida, bazar) i da się je w całości cofnąć.
class ScoreEvent {
  final String label;
  final List<ScoreChange> changes;

  /// Żeton zwierzęcia zużyty przy punktowaniu cyrku (jeśli to było ono).
  final CircusAnimal? animal;

  /// Rodzaj punktacji (np. „Miasto"), używany w historii i podsumowaniu gry.
  final String? category;

  /// Rodzaj punktacji; w historii jego ikona zastępuje opis zdarzenia.
  final ScoringType? type;

  const ScoreEvent(
    this.label,
    this.changes, {
    this.animal,
    this.category,
    this.type,
  });

  void apply() => _shift(1);

  void revert() => _shift(-1);

  void _shift(int sign) {
    for (final change in changes) {
      change.player.points += sign * change.points;
      change.player.gold += sign * change.gold;
      change.goods.forEach((goods, count) {
        change.player.goods[goods] =
            change.player.goodsOf(goods) + sign * count;
      });
    }
  }
}
