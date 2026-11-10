/// Pionki magiczne z minidodatku „Mag i Wiedźma". Stoją na nieukończonej
/// drodze lub mieście i zmieniają punkty tej budowli; nigdy nie stoją razem
/// na jednej budowli.
enum MagicPawn {
  /// Fioletowy mag: +1 pkt za każdą płytkę drogi lub miasta.
  mage('assets/icons/game/mage.svg'),

  /// Pomarańczowa wiedźma: połowa punktów drogi lub miasta, zaokrąglona
  /// w górę.
  witch('assets/icons/game/witch.svg');

  const MagicPawn(this.iconAsset);

  /// Ikona SVG z zestawu gry.
  final String iconAsset;
}

/// Punkty drogi lub miasta po działaniu pionka magicznego.
///
/// [base] to punkty budowli po karczmie, katedrze i katedrze niemieckiej,
/// [tiles] – płytki drogi lub miasta (sztandary się nie liczą).
///
/// - mag dodaje po 1 pkt za płytkę, także do nieukończonej drogi z karczmą
///   lub miasta z katedrą (które same dają wtedy 0),
/// - wiedźma dzieli punkty przez 2 z zaokrągleniem w górę.
///
/// Premie osobne od budowli (zamki niemieckie, wróżka, dyrektor cyrku) liczy
/// się już po tej zmianie i nie są przez nią zmieniane.
int applyMagic(MagicPawn? pawn, {required int base, required int tiles}) {
  switch (pawn) {
    case MagicPawn.mage:
      return base + tiles;
    case MagicPawn.witch:
      return (base + 1) ~/ 2;
    case null:
      return base;
  }
}
