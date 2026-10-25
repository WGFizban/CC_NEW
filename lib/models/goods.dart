import '../l10n/tr.dart';

/// Surowce z dodatku „Kupcy i budowniczowie".
enum Goods {
  wine('Wino', 'Wine', 9),
  grain('Żyto', 'Grain', 6),
  cloth('Sukno', 'Cloth', 5);

  const Goods(this._pl, this._en, this.supply);

  final String _pl;
  final String _en;

  /// Nazwa surowca w aktualnym języku.
  String get displayName => tr(_pl, _en);

  /// Liczba żetonów tego surowca w grze (razem 20).
  final int supply;
}
