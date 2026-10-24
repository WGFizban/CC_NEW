/// Dodatki do gry obsługiwane przez aplikację.
enum Expansion {
  innsCathedrals(
    'Karczmy i katedry',
    'Katedra w mieście (3 pkt za płytkę) i karczma przy drodze '
        '(2 pkt za płytkę). Nieukończone budowle z nimi nie dają punktów.',
  ),
  tradersBuilders(
    'Kupcy i budowniczowie',
    'Surowce (wino, żyto, sukno) i premia 10 pkt dla prowadzącego, '
        'liczona na bieżąco.',
  ),
  abbeyMayor(
    'Opactwo i burmistrz',
    'Opactwo (punktuje jak klasztor), burmistrz w mieście (siła równa '
        'sztandarom) i stodoła na polach.',
  ),
  princessDragon(
    'Księżniczka i smok',
    'Wróżka: 1 pkt na początku tury i 3 pkt przy punktowaniu budowli '
        'z jej ludkiem.',
  ),
  bridgesCastlesBazaars(
    'Mosty, zamki i bazary',
    'Punktacja zamków, zamki na polach i licytacje '
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
  ),
  goldMines(
    'Kopalnie złota',
    'Sztabki złota za ukończone budowle; na koniec gry im więcej sztabek, '
        'tym więcej warta każda (1–4 pkt).',
  );

  const Expansion(this.displayName, this.description);

  final String displayName;
  final String description;
}
