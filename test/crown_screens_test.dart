import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/l10n/app_localizations.dart';
import 'package:cc_new/models/crown_tokens.dart';
import 'package:cc_new/models/player.dart';
import 'package:cc_new/screens/crown_end_screen.dart';
import 'package:cc_new/widgets/counter_stepper.dart';
import 'package:cc_new/widgets/token_dialogs.dart';

Player _p(String name) => Player(name: name, color: const Color(0xFF1D27EA));

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('pl'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

void main() {
  testWidgets('ekran końcowy: klawiatura wpisuje liczby do wybranego pola', (
    tester,
  ) async {
    // Wysoki ekran, żeby oba pola zmieściły się nad klawiaturą.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.reset);
    CrownCounts? result;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.push<CrownCounts>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CrownEndScreen(
                        king: _p('Ala'),
                        robber: _p('Bob'),
                      ),
                    ),
                  );
                },
                child: const Text('otwórz'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('otwórz'));
    await tester.pumpAndSettle();

    expect(find.text('Ukończone zamki'), findsOneWidget);
    expect(find.text('Ukończone drogi'), findsOneWidget);

    // Domyślnie aktywne jest pole Króla (zamki): 1, 2 -> 12.
    await tester.tap(find.widgetWithText(ElevatedButton, '1'));
    await tester.tap(find.widgetWithText(ElevatedButton, '2'));
    await tester.pump();
    // Przełączenie na drogi i wpisanie 7.
    await tester.tap(find.text('Ukończone drogi'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, '7'));
    await tester.pump();

    await tester.tap(find.text('Zatwierdź'));
    await tester.pumpAndSettle();

    expect(result, (cities: 12, roads: 7));
  });

  testWidgets('okno żetonu przy punktowaniu: wielkość jest narzucona', (
    tester,
  ) async {
    TokenChange? result;
    final ala = _p('Ala');
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showTokenDialog(
                    context,
                    token: CrownToken.king,
                    tokens: const {},
                    players: [ala],
                    scorer: ala,
                    fixedSize: 5,
                  );
                },
                child: const Text('otwórz'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('otwórz'));
    await tester.pumpAndSettle();

    // Brak licznika +/-: wielkość jest tylko wyświetlona.
    expect(find.byType(CounterStepper), findsNothing);
    expect(find.text('5'), findsOneWidget);

    await tester.tap(find.text('Zatwierdź'));
    await tester.pumpAndSettle();
    expect(result?.token, CrownToken.king);
    expect(result?.after.size, 5);
  });

  testWidgets('przekazanie żetonu: przełącznik Król/Rabuś zmienia minimum', (
    tester,
  ) async {
    final ala = _p('Ala');
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showTokenDialog(
                  context,
                  tokens: {CrownToken.robber: TokenHolding(ala.id, 6)},
                  players: [ala],
                  scorer: ala,
                ),
                child: const Text('otwórz'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('otwórz'));
    await tester.pumpAndSettle();

    expect(tester.widget<CounterStepper>(find.byType(CounterStepper)).min, 1);
    await tester.tap(find.text('Rabuś'));
    await tester.pumpAndSettle();
    expect(tester.widget<CounterStepper>(find.byType(CounterStepper)).min, 7);
  });
}
