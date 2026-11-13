import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import 'info_hint.dart';
import 'meeple_icon.dart';

/// Ikona kończąca grę (ta sama na przycisku i w komunikacie o starcie).
const IconData kEndGameIcon = Icons.sports_score;

/// Ikona przycisku przechodzącego do podsumowania (po punktowaniu końcowym).
const IconData kSummaryIcon = Icons.emoji_events;

/// Wyraźna plakietka „Punktowanie końcowe", żeby w tej fazie nie pomylić ekranów
/// z punktowaniem w trakcie gry.
class EndPhaseBadge extends StatelessWidget {
  final String text;

  /// Opis fazy w dymku przy znaczniku (np. na ekranie graczy).
  final String? hint;

  const EndPhaseBadge(this.text, {this.hint, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(kEndGameIcon, size: 20, color: scheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
          if (hint != null) InfoHint(hint!, title: text),
        ],
      ),
    );
  }
}

/// Ostrzeżenie z wyborem „Wróć” / „Dodaj mimo to”. Zwraca `true`, gdy
/// użytkownik mimo wszystko zatwierdza.
Future<bool> warnAndAsk(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.goBack),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.addAnyway),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Okno z pytaniem i odpowiedziami Tak / Nie. Zwraca `true` po „Tak".
Future<bool> askYesNo(
  BuildContext context, {
  required String title,
  String? message,
}) async {
  final l = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.no),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.yes),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Kwadratowy przycisk z ikoną, wyglądający jak przycisk na ekranie gry.
Widget fabLookalike(BuildContext context, IconData icon) => Container(
  padding: const EdgeInsets.all(4),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.primaryContainer,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Icon(icon, size: 22),
);

/// Komunikat o rozpoczęciu gry z grafiką przycisku kończącego grę.
Future<void> showGameStartedNote(BuildContext context) {
  final l = context.l10n;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l.gameStartedTitle, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${l.gameStartedBefore} '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: fabLookalike(ctx, kEndGameIcon),
              ),
              TextSpan(text: ' ${l.gameStartedEnd}\n\n${l.gameStartedAfter}'),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.ok),
        ),
      ],
    ),
  );
}

/// Sposób rozpoczęcia nowej gry.
enum NewGameChoice {
  /// Ci sami gracze, wyzerowane punkty.
  samePlayers,

  /// Lista graczy od zera.
  newPlayers,
}

/// Okno nowej gry z trzema przyciskami: Anuluj, ci sami gracze i nowi gracze.
/// Zwraca `null` po anulowaniu.
Future<NewGameChoice?> askNewGame(BuildContext context) {
  final l = context.l10n;
  return showDialog<NewGameChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.newGameTitle),
      content: SingleChildScrollView(child: Text(l.newGameChoiceBody)),
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(ctx, NewGameChoice.samePlayers),
          child: Text(l.newGameSamePlayers),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, NewGameChoice.newPlayers),
          child: Text(l.newGameNewPlayers),
        ),
      ],
    ),
  );
}

/// Odpowiedź w oknie rozpoczęcia gry.
enum StartChoice { start, cancel, expansions }

/// Pytanie o rozpoczęcie gry z przyciskiem przejścia do wyboru dodatków.
Future<StartChoice> askStartGame(
  BuildContext context, {
  required String expansionsList,
}) async {
  final l = context.l10n;
  final result = await showDialog<StartChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.startGameQuestion),
      content: SingleChildScrollView(
        child: Text(l.startGameBody(expansionsList)),
      ),
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(ctx, StartChoice.expansions),
          icon: const Icon(Icons.extension),
          label: Text(l.modifyExpansions),
        ),
        TextButton.icon(
          onPressed: () => Navigator.pop(ctx, StartChoice.cancel),
          icon: MeepleIcon(
            color: Theme.of(ctx).colorScheme.primary,
            size: 22,
          ),
          label: Text(l.backToEdit),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, StartChoice.start),
          child: Text(l.startGame),
        ),
      ],
    ),
  );
  return result ?? StartChoice.cancel;
}
