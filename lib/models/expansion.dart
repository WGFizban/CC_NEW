import '../l10n/tr.dart';

/// Dodatki do gry obsługiwane przez aplikację, w kolejności numeracji
/// z instrukcji (mini dodatki na końcu).
enum Expansion {
  innsCathedrals(
    1,
    pl: 'Karczmy i katedry',
    en: 'Inns & Cathedrals',
    descPl:
        'Katedra w mieście (3 pkt za płytkę) i karczma przy drodze '
        '(2 pkt za płytkę). Nieukończone budowle z nimi nie dają punktów.',
    descEn:
        'Cathedral in a city (3 pts per tile) and inn on a road '
        '(2 pts per tile). Unfinished features with them score nothing.',
  ),
  tradersBuilders(
    2,
    pl: 'Kupcy i budowniczowie',
    en: 'Traders & Builders',
    descPl:
        'Surowce (wino, żyto, sukno) i premia 10 pkt dla prowadzącego, '
        'liczona na bieżąco.',
    descEn:
        'Goods (wine, grain, cloth) and a 10 pt bonus for the leader, '
        'counted live.',
  ),
  princessDragon(
    3,
    pl: 'Księżniczka i smok',
    en: 'The Princess & the Dragon',
    descPl:
        'Wróżka: 1 pkt na początku tury i 3 pkt przy punktowaniu budowli '
        'z jej meplem.',
    descEn:
        'Fairy: 1 pt at the start of the turn and 3 pts when a feature '
        'with its meeple is scored.',
  ),
  tower(
    4,
    pl: 'Wieża',
    en: 'The Tower',
    descPl:
        'Wykup uwięzionego mepla: płacisz 3 pkt temu, kto go trzyma. '
        'Wymiana mepel za mepel odbywa się bez aplikacji.',
    descEn:
        'Buying back a captured meeple: you pay 3 pts to whoever holds it. '
        'Meeple-for-meeple swaps happen without the app.',
  ),
  abbeyMayor(
    5,
    pl: 'Opactwo i burmistrz',
    en: 'Abbey & Mayor',
    descPl: 'Opactwo (punktuje jak klasztor) i stodoła na polach.',
    descEn: 'Abbey (scores like a cloister) and the barn on farms.',
  ),
  bridgesCastlesBazaars(
    8,
    pl: 'Mosty, zamki i bazary',
    en: 'Bridges, Castles & Bazaars',
    descPl:
        'Punktacja zamków, zamki na polach i licytacje '
        'na bazarach.',
    descEn: 'Castle scoring, castles on farms and bazaar auctions.',
  ),
  hillsSheep(
    9,
    pl: 'Owce i wzgórza',
    en: 'Hills & Sheep',
    descPl: 'Stada owiec z żetonów 1–4 owce, w granicach limitów z gry.',
    descEn: 'Flocks made of 1–4 sheep tokens, within the limits of the game.',
  ),
  circus(
    10,
    pl: 'Cyrk objazdowy',
    en: 'Under the Big Top',
    descPl:
        'Punktacja cyrku (żetony zwierząt), piramidy akrobatów '
        'i dyrektor cyrku.',
    descEn:
        'Circus scoring (animal tokens), acrobat pyramids and the '
        'ringmaster.',
  ),
  goldMines(
    4,
    mini: true,
    pl: 'Kopalnie złota',
    en: 'Gold Mines',
    descPl:
        'Sztabki złota za ukończone budowle; na koniec gry im więcej sztabek, '
        'tym więcej warta każda (1–4 pkt).',
    descEn:
        'Gold bars for completed features; at the end of the game the more '
        'bars you hold, the more each is worth (1–4 pts).',
  );

  const Expansion(
    this.number, {
    this.mini = false,
    required String pl,
    required String en,
    required String descPl,
    required String descEn,
  }) : _pl = pl,
       _en = en,
       _descPl = descPl,
       _descEn = descEn;

  /// Numer z instrukcji (osobna numeracja dla mini dodatków).
  final int number;

  /// Czy to mini dodatek.
  final bool mini;

  final String _pl;
  final String _en;
  final String _descPl;
  final String _descEn;

  /// Nazwa dodatku w aktualnym języku.
  String get displayName => tr(_pl, _en);

  /// Opis dodatku (podpowiedź „?" w ustawieniach).
  String get description => tr(_descPl, _descEn);

  /// Nazwa z numerem, np. „4. Wieża" albo „Kopalnie złota (Mini dodatek 4)".
  String get label => mini
      ? '$displayName (${tr('Mini dodatek', 'Mini expansion')} $number)'
      : '$number. $displayName';
}
