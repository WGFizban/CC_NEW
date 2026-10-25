import 'player.dart';

/// Okup za uwięzionego mepla („Wieża"): tyle punktów płaci wykupujący temu,
/// kto trzyma jeńca. Okup za dużego mepla nie jest podwajany.
const int kRansomPoints = 3;

/// Czy gracz może wykupić mepla: musi mieć na planszy co najmniej
/// [kRansomPoints] punktów, bo znacznik nie cofnie się poniżej zera.
bool canAffordRansom(Player buyer) => buyer.points >= kRansomPoints;
