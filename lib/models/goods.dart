/// Surowce z dodatku „Kupcy i budowniczowie".
enum Goods {
  wine(9),
  grain(6),
  cloth(5);

  const Goods(this.supply);

  /// Liczba żetonów tego surowca w grze (razem 20).
  final int supply;
}
