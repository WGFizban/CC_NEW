import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/l10n/app_localizations.dart';
import 'package:cc_new/screens/rules_screen.dart';

Widget _app() => MaterialApp(
  locale: const Locale('pl'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: const RulesScreen(),
);

void main() {
  testWidgets('skrót zasad pokazuje zawartość gry podstawowej i link do wiki', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 3000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Gra podstawowa jest rozwinięta od początku.
    expect(find.text('Zawartość i elementy'), findsOneWidget);
    expect(find.textContaining('72 płytki'), findsOneWidget);

    // Liczba płytek jest widoczna już w zwiniętym tytule dodatku.
    expect(find.textContaining('Karczmy i katedry (18 płytek)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Otwórz Wikicarpedię'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nie znalazłeś interesującej Cię zasady?'), findsOneWidget);
    expect(find.text('Otwórz Wikicarpedię'), findsOneWidget);
  });
}
