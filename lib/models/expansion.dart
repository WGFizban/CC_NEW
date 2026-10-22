/// Dodatki do gry obsługiwane przez aplikację.
enum Expansion {
  tradersBuilders(
    'Kupcy i budowniczowie',
    'Surowce (wino, żyto, sukno) i premia 10 pkt dla prowadzącego, '
        'liczona na bieżąco.',
  ),
  princessDragon(
    'Księżniczka i smok',
    'Wróżka: 1 pkt na początku tury i 3 pkt przy punktowaniu budowli '
        'z jej ludkiem.',
  ),
  bridgesCastlesBazaars(
    'Mosty, zamki i bazary',
    'Mosty na drogach, punktacja zamków, zamki na polach i licytacje '
        'na bazarach.',
  ),
  circus(
    'Cyrk objazdowy',
    'Punktacja cyrku (żetony zwierząt), piramidy akrobatów '
        'i dyrektor cyrku.',
  ),
  hillsSheep(
    'Wzgórza i owce',
    'Stada owiec z żetonów 1–4 owce, w granicach limitów z gry.',
  );

  const Expansion(this.displayName, this.description);

  final String displayName;
  final String description;
}
