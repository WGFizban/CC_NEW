import 'player.dart';

/// Siła gracza w mieście, do ustalenia przewagi (kto dostaje punkty).
///
/// Zwykły ludek (także wóz) ma siłę 1, duży ludek 2, a burmistrz tyle, ile
/// sztandarów jest w mieście (bez sztandarów – 0, czyli niczego nie liczy).
int cityStrength({
  int knights = 0,
  bool bigFollower = false,
  bool mayor = false,
  int banners = 0,
}) => knights + (bigFollower ? 2 : 0) + (mayor ? banners : 0);

/// Gracze z największą, niezerową siłą; przy remisie wszyscy remisujący.
List<Player> majorityHolders(Map<Player, int> strengths) {
  var best = 0;
  for (final v in strengths.values) {
    if (v > best) best = v;
  }
  if (best == 0) return const [];
  return [
    for (final e in strengths.entries)
      if (e.value == best) e.key,
  ];
}
