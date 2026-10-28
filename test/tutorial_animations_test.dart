import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/l10n/app_localizations.dart';
import 'package:cc_new/widgets/tutorial_animations.dart';

Widget _app({bool reduceMotion = false}) => MaterialApp(
  locale: const Locale('pl'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: const Scaffold(body: Center(child: AddPlayerAnimation())),
);

void main() {
  testWidgets('animacja dodawania gracza przechodzi całą pętlę bez błędów', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    // Cała pętla trwa 8 s; sprawdzamy kilka charakterystycznych momentów.
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(tester.takeException(), isNull);
    expect(find.text('Carcassonne Counter'), findsOneWidget);
  });

  testWidgets('w trakcie wpisywania widać imię, a na końcu wiersz gracza', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    await tester.pump(const Duration(milliseconds: 4000)); // 50% pętli
    expect(find.text('Ala'), findsWidgets);

    // Koniec pętli: wiersz z imieniem i punktami.
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('przy ograniczonym ruchu pokazuje nieruchomą klatkę końcową', (
    tester,
  ) async {
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.pump();

    expect(find.text('Ala'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    // Brak aktywnych animacji, więc pumpAndSettle się kończy.
    await tester.pumpAndSettle();
  });

  testWidgets('dotknięcie wstrzymuje animację', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 1000));

    await tester.tap(find.byType(AddPlayerAnimation));
    await tester.pump();
    // Po wstrzymaniu nie ma już zaplanowanych klatek.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
