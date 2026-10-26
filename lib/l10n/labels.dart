import '../models/circus.dart';
import '../models/expansion.dart';
import '../models/goods.dart';
import '../models/scoring.dart';
import 'app_localizations.dart';

/// Nazwy i opisy typów z modeli w aktualnym języku. Modele nie znają tekstów,
/// a tutaj każdy typ ma swój klucz w plikach `.arb`.

extension ExpansionLabels on Expansion {
  String title(AppLocalizations l) => switch (this) {
    Expansion.innsCathedrals => l.expInns,
    Expansion.tradersBuilders => l.expTraders,
    Expansion.princessDragon => l.expPrincess,
    Expansion.tower => l.expTower,
    Expansion.abbeyMayor => l.expAbbey,
    Expansion.bridgesCastlesBazaars => l.expBridges,
    Expansion.hillsSheep => l.expHills,
    Expansion.circus => l.expCircus,
    Expansion.goldMines => l.expGold,
    Expansion.monasteries => l.expMonasteries,
  };

  /// Opis dodatku (podpowiedź „?" w ustawieniach).
  String description(AppLocalizations l) => switch (this) {
    Expansion.innsCathedrals => l.expInnsDesc,
    Expansion.tradersBuilders => l.expTradersDesc,
    Expansion.princessDragon => l.expPrincessDesc,
    Expansion.tower => l.expTowerDesc,
    Expansion.abbeyMayor => l.expAbbeyDesc,
    Expansion.bridgesCastlesBazaars => l.expBridgesDesc,
    Expansion.hillsSheep => l.expHillsDesc,
    Expansion.circus => l.expCircusDesc,
    Expansion.goldMines => l.expGoldDesc,
    Expansion.monasteries => l.expMonasteriesDesc,
  };

  /// Nazwa z numerem, np. „4. Wieża" albo „Kopalnie złota (Mini dodatek 4)".
  String label(AppLocalizations l) => mini
      ? l.expansionMiniLabel(title(l), number)
      : l.expansionLabel(number, title(l));
}

extension ScoringTypeLabels on ScoringType {
  String title(AppLocalizations l) => switch (this) {
    ScoringType.city => l.scCity,
    ScoringType.road => l.scRoad,
    ScoringType.cloister => l.scCloister,
    ScoringType.meadow => l.scFarms,
    ScoringType.fairy => l.scFairy,
    ScoringType.sheep => l.scSheep,
    ScoringType.goods => l.scGoods,
    ScoringType.bazaar => l.scBazaar,
    ScoringType.circus => l.scCircus,
    ScoringType.pyramid => l.scAcrobats,
    ScoringType.ringmaster => l.scRingmaster,
    ScoringType.abbey => l.scAbbey,
    ScoringType.gold => l.scGold,
    ScoringType.tower => l.scTower,
    ScoringType.monastery => l.scMonastery,
  };
}

extension GoodsLabels on Goods {
  String title(AppLocalizations l) => switch (this) {
    Goods.wine => l.goodsWine,
    Goods.grain => l.goodsGrain,
    Goods.cloth => l.goodsCloth,
  };
}

extension CircusAnimalLabels on CircusAnimal {
  String title(AppLocalizations l) => switch (this) {
    CircusAnimal.elephant => l.animalElephant,
    CircusAnimal.lion => l.animalLion,
    CircusAnimal.bear => l.animalBear,
    CircusAnimal.seal => l.animalSeal,
    CircusAnimal.monkey => l.animalMonkey,
    CircusAnimal.flea => l.animalFlea,
  };
}
