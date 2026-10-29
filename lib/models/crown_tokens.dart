import 'player.dart';

/// Żetony dodatku „Król i Baron rabusiów".
///
/// - [king] – żeton Króla: ma go gracz z największym ukończonym miastem;
///   na koniec gry daje 1 pkt za każde ukończone miasto na planszy,
/// - [robber] – żeton Barona rabusiów: ma go gracz z najdłuższą ukończoną
///   drogą; na koniec gry daje 1 pkt za każdą ukończoną drogę na planszy.
///
/// Punkty liczy się za wszystkie ukończone budowle w całej grze (nie tylko
/// własne), po jednym punkcie za budowlę, bez względu na liczbę płytek.
enum CrownToken { king, robber }

/// Największa wielkość budowli, jaką da się wpisać przy przejęciu żetonu.
const int kMaxTokenSize = 99;

/// Kto aktualnie trzyma żeton i jak duża (w płytkach) jest budowla, dzięki
/// której go ma. Kolejne przejęcie wymaga budowli większej niż [size].
class TokenHolding {
  final String playerId;
  final int size;

  const TokenHolding(this.playerId, this.size);

  Map<String, dynamic> toJson() => {'playerId': playerId, 'size': size};

  static TokenHolding? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['playerId'];
    final size = json['size'];
    if (id is! String || size is! int) return null;
    return TokenHolding(id, size);
  }

  /// Gracz trzymający żeton wśród [players] (`null`, gdy już go nie ma).
  Player? holder(List<Player> players) {
    for (final p in players) {
      if (p.id == playerId) return p;
    }
    return null;
  }
}

/// Najmniejsza wielkość budowli, która pozwala przejąć żeton, czyli o 1 więcej
/// niż dotychczasowa (przy braku właściciela – 1).
int minTokenSize(TokenHolding? current) => (current?.size ?? 0) + 1;

/// Przejęcie żetonu przy jednym zatwierdzeniu punktów: stan przed (do
/// cofnięcia) i po.
class TokenChange {
  final CrownToken token;
  final TokenHolding? before;
  final TokenHolding after;

  const TokenChange(this.token, this.before, this.after);
}

/// Punkty końcowe za żetony: po 1 za każde ukończone miasto na planszy
/// (Król) i każdą ukończoną drogę (Baron rabusiów), dla ich właścicieli.
Map<Player, int> crownEndPoints({
  required Map<CrownToken, TokenHolding> tokens,
  required List<Player> players,
  required int cities,
  required int roads,
}) {
  final result = <Player, int>{};
  void add(CrownToken token, int count) {
    final holder = tokens[token]?.holder(players);
    if (holder == null || count <= 0) return;
    result[holder] = (result[holder] ?? 0) + count;
  }

  add(CrownToken.king, cities);
  add(CrownToken.robber, roads);
  return result;
}
