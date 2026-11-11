import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/l10n/app_localizations.dart';
import 'package:cc_new/models/player.dart';
import 'package:cc_new/models/scoring.dart';
import 'package:cc_new/models/expansion.dart';
import 'package:cc_new/screens/add_points_screen.dart';
import 'package:cc_new/screens/select_points_type_screen.dart';
import 'package:cc_new/widgets/adaptive_layout.dart';
import 'package:cc_new/widgets/number_keypad.dart';

Player _p(String name) => Player(name: name, color: const Color(0xFF1D27EA));

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('pl'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

Widget _cityScreen() => _app(
  AddPointsScreen(
    player: _p('Ala'),
    players: [_p('Ala'), _p('Bob')],
    type: ScoringType.city,
    expansions: const {},
  ),
);

/// Przełącznik pól na klawiaturze (nie pole „Sztandary” nad nią).
Finder _switchSegment(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is SegmentedButton),
  matching: find.text(label),
);

void main() {
  test('useSideKeypad: tylko szeroki i niski ekran', () {
    bool side(double w, double h) =>
        useSideKeypad(BoxConstraints(maxWidth: w, maxHeight: h));
    expect(side(400, 800), isFalse); // telefon w pionie
    expect(side(800, 400), isTrue); // telefon w poziomie
    expect(side(900, 1200), isFalse); // tablet w pionie
    expect(side(1280, 800), isTrue); // tablet w poziomie
    expect(side(500, 300), isFalse); // za wąski na panel z boku
  });

  testWidgets('klawiatura mieści się w niskim panelu bez przepełnienia', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: kSideKeypadWidth,
            height: 200,
            child: Center(child: NumberKeypad(onKey: (_) {})),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('poziom: klawiatura stoi obok formularza, bez przepełnienia', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_cityScreen());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Formularz i klawiatura są jednocześnie na ekranie.
    expect(find.text('Płytki'), findsWidgets);
    expect(find.text('7'), findsOneWidget);
    // Panel z boku jest zawsze widoczny, więc nie ma przycisku zwijania.
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });

  testWidgets('pion: klawiatura pod formularzem da się zwinąć', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_cityScreen());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();
    expect(find.text('7'), findsNothing);
  });

  for (final (name, size) in [
    ('pion', const Size(400, 800)),
    ('poziom', const Size(800, 360)),
  ]) {
    testWidgets('miasto ($name): przełącznik zmienia pole wpisywane z klawiatury',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_cityScreen());
      await tester.pumpAndSettle();

      // Domyślnie wpisujemy płytki: 2 płytki = 4 pkt.
      await tester.tap(find.widgetWithText(ElevatedButton, '2'));
      await tester.pump();
      expect(find.text('Wynik: 4 pkt'), findsOneWidget);

      // Po przełączeniu cyfry trafiają do sztandarów: +3 sztandary = +6 pkt.
      await tester.tap(_switchSegment('Sztandary'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '3'));
      await tester.pump();
      expect(find.text('Wynik: 10 pkt'), findsOneWidget);

      // I z powrotem: kolejna cyfra dopisuje się do płytek (2 -> 25).
      await tester.tap(_switchSegment('Płytki'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '5'));
      await tester.pump();
      expect(find.text('Wynik: 56 pkt'), findsOneWidget);
    });
  }

  for (final newLines in [false, true]) {
    for (final titles in [false, true]) {
      testWidgets(
        'wybór punktacji (nowe linie: $newLines, tytuły: $titles) bez błędów',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(400, 800);
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            _app(
              SelectPointsTypeScreen(
                player: _p('Ala'),
                types: ScoringType.selectableFor(Expansion.values.toSet()),
                showGroupTitles: titles,
                groupsOnNewLines: newLines,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
