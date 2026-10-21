/// Surowce z dodatku „Kupcy i budowniczowie".
enum Goods {
  wine('Wino', 9),
  grain('Żyto', 6),
  cloth('Sukno', 5);

  const Goods(this.displayName, this.supply);

  final String displayName;

  /// Liczba żetonów tego surowca w grze (razem 20).
  final int supply;
}
