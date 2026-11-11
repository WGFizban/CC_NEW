import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/l10n/app_localizations.dart';
import 'package:cc_new/models/expansion.dart';
import 'package:cc_new/models/game_state.dart';
import 'package:cc_new/models/player.dart';
import 'package:cc_new/models/scoring.dart';
import 'package:cc_new/models/standings.dart';
import 'package:cc_new/screens/end_game_screen.dart';
import 'package:cc_new/screens/add_points_screen.dart';
import 'package:cc_new/screens/select_points_type_screen.dart';
import 'package:cc_new/services/settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Player _p(String name) => Player(name: name, color: const Color(0xFF1D27EA));

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('pl'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

Widget _screen(
  ScoringType type, {
  bool endPhase = false,
  Set<Expansion> expansions = const {},
}) => _app(
  AddPointsScreen(
    player: _p('Ala'),
    players: [_p('Ala'), _p('Bob')],
    type: type,
    expansions: expansions,
    endPhase: endPhase,
  ),
);

void main() {
  group('etapy gry', () {
    test('punktować można w trakcie gry i w punktowaniu końcowym', () {
      expect(canScore(GameStage.playing), isTrue);
      expect(canScore(GameStage.endScoring), isTrue);
      expect(canScore(GameStage.setup), isFalse);
      expect(canScore(GameStage.finished), isFalse);
    });

    test('punktowanie końcowe jest osobnym etapem', () {
      expect(isEndScoring(GameStage.endScoring), isTrue);
      expect(isEndScoring(GameStage.playing), isFalse);
      expect(isSetup(GameStage.endScoring), isFalse);
    });

    test('etap punktowania końcowego przetrwa zapis i odczyt', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = SettingsStorage();
      final settings = await storage.load();
      settings.stage = GameStage.endScoring;
      await storage.save(settings);

      expect((await storage.load()).stage, GameStage.endScoring);
    });
  });

  group('typy punktacji w fazach gry', () {
    final all = Expansion.values.toSet();

    test('w trakcie gry nie ma klasztorów niemieckich i holenderskich', () {
      expect(
        ScoringType.selectableFor(all),
        isNot(contains(ScoringType.monastery)),
      );
    });

    test('pole w trakcie gry tylko ze stodołą (Opactwo i burmistrz)', () {
      expect(
        ScoringType.selectableFor({}),
        isNot(contains(ScoringType.meadow)),
      );
      expect(
        ScoringType.selectableFor({Expansion.abbeyMayor}),
        contains(ScoringType.meadow),
      );
    });

    test('w trakcie gry są owce, surowce, bazar, wieża, złoto i wróżka', () {
      final types = ScoringType.selectableFor(all);
      expect(
        types,
        containsAll([
          ScoringType.city,
          ScoringType.road,
          ScoringType.cloister,
          ScoringType.fairy,
          ScoringType.sheep,
          ScoringType.goods,
          ScoringType.bazaar,
          ScoringType.tower,
          ScoringType.gold,
          ScoringType.crown,
          ScoringType.circus,
          ScoringType.pyramid,
          ScoringType.germanCastle,
          ScoringType.archbishop,
        ]),
      );
    });

    test('po grze są pola, klasztory niemieckie i holenderskie oraz nieukończone budowle', () {
      final types = ScoringType.selectableFor({}, endPhase: true);
      expect(
        types,
        containsAll([
          ScoringType.city,
          ScoringType.road,
          ScoringType.cloister,
          ScoringType.meadow,
        ]),
      );
      expect(
        ScoringType.selectableFor(all, endPhase: true),
        containsAll([
          ScoringType.monastery,
          ScoringType.germanCastle,
          ScoringType.archbishop,
          ScoringType.abbey,
          ScoringType.circus,
          ScoringType.pyramid,
          ScoringType.ringmaster,
        ]),
      );
    });

    test('po grze nie ma owiec, surowców, bazaru, wieży, złota ani wróżki', () {
      final types = ScoringType.selectableFor(all, endPhase: true);
      for (final t in [
        ScoringType.sheep,
        ScoringType.goods,
        ScoringType.bazaar,
        ScoringType.tower,
        ScoringType.gold,
        ScoringType.fairy,
        ScoringType.crown,
        ScoringType.king,
        ScoringType.robber,
        ScoringType.magic,
      ]) {
        expect(types, isNot(contains(t)), reason: '$t');
      }
    });
  });

  group('ekran punktowania w trakcie gry', () {
    testWidgets('miasto i droga nie mają przełącznika „ukończone”', (
      tester,
    ) async {
      await tester.pumpWidget(_screen(ScoringType.city));
      await tester.pumpAndSettle();
      expect(find.text('Czy ukończone'), findsNothing);
      expect(find.text('Punktowanie końcowe'), findsNothing);

      await tester.pumpWidget(_screen(ScoringType.road));
      await tester.pumpAndSettle();
      expect(find.text('Czy ukończona'), findsNothing);
    });

    testWidgets('klasztor zachowuje przełącznik (opat zdjęty wcześniej)', (
      tester,
    ) async {
      await tester.pumpWidget(_screen(ScoringType.cloister));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsOneWidget);
    });
  });

  group('ekran punktowania końcowego', () {
    testWidgets('miasto ma plakietkę i przełącznik, domyślnie nieukończone', (
      tester,
    ) async {
      await tester.pumpWidget(_screen(ScoringType.city, endPhase: true));
      await tester.pumpAndSettle();

      expect(find.text('Punktowanie końcowe'), findsOneWidget);
      final toggle = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Czy ukończone'),
      );
      expect(toggle.value, isFalse);
    });

    testWidgets('klasztor po grze jest domyślnie nieukończony', (tester) async {
      await tester.pumpWidget(_screen(ScoringType.cloister, endPhase: true));
      await tester.pumpAndSettle();

      final toggle = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(toggle.value, isFalse);
    });

    testWidgets('przełącznik „ukończone” jest ostatni na ekranie', (
      tester,
    ) async {
      await tester.pumpWidget(
        _screen(
          ScoringType.road,
          endPhase: true,
          expansions: {Expansion.innsCathedrals},
        ),
      );
      await tester.pumpAndSettle();

      // Karczma (z podpowiedzią) i „Czy ukończona” to dwa checkboxy; ten
      // drugi musi leżeć niżej.
      final boxes = find.byType(CheckboxListTile);
      expect(boxes, findsNWidgets(2));
      final last = tester.widget<CheckboxListTile>(boxes.last);
      expect((last.title! as Text).data, 'Czy ukończona');
      expect(
        tester.getTopLeft(boxes.last).dy,
        greaterThan(tester.getTopLeft(boxes.first).dy),
      );
    });

    testWidgets('ukończona struktura po grze wymaga potwierdzenia', (
      tester,
    ) async {
      await tester.pumpWidget(_screen(ScoringType.cloister, endPhase: true));
      await tester.pumpAndSettle();

      // Zaznaczamy „ukończony”: klasztor daje wtedy 9 pkt.
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('Ukończona struktura po grze'), findsOneWidget);
      expect(find.text('Dodaj mimo to'), findsOneWidget);

      await tester.tap(find.text('Wróć'));
      await tester.pumpAndSettle();
      expect(find.text('Ukończona struktura po grze'), findsNothing);
    });
  });

  group('katedra niemiecka po grze', () {
    testWidgets('drogi są domyślnie nieukończone i pokazują to w podtytule', (
      tester,
    ) async {
      await tester.pumpWidget(
        _screen(
          ScoringType.archbishop,
          endPhase: true,
          expansions: {Expansion.germanCathedrals},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('nieukończona'), findsWidgets);
      expect(find.text('ukończona'), findsNothing);
    });

    testWidgets('zamek z Mostów, zamków i bazarów punktuje też katedrę', (
      tester,
    ) async {
      final exp = {
        Expansion.germanCathedrals,
        Expansion.bridgesCastlesBazaars,
      };
      await tester.pumpWidget(_screen(ScoringType.archbishop, expansions: exp));
      await tester.pumpAndSettle();
      expect(ScoringType.archbishop.supportsCastle, isTrue);
      expect(ScoringType.germanCastle.supportsCastle, isTrue);
      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('w trakcie gry sekcje dróg nie mówią o ukończeniu', (
      tester,
    ) async {
      await tester.pumpWidget(
        _screen(
          ScoringType.archbishop,
          expansions: {Expansion.germanCathedrals},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('nieukończona'), findsNothing);
      expect(find.text('ukończona'), findsNothing);
    });
  });

  group('ekran wyboru typu', () {
    testWidgets('po grze pokazuje plakietkę fazy', (tester) async {
      await tester.pumpWidget(
        _app(
          SelectPointsTypeScreen(
            player: _p('Ala'),
            types: ScoringType.selectableFor({}, endPhase: true),
            endPhase: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Punktowanie końcowe'), findsOneWidget);
    });
  });

  group('miejsca w podsumowaniu', () {
    test('remis dzieli miejsce, a następne to kolejny numer', () {
      final a = _p('A')..points = 30;
      final b = _p('B')..points = 20;
      final c = _p('C')..points = 20;
      final d = _p('D')..points = 5;

      final r = rankings([d, b, a, c]);

      expect([for (final e in r) e.place], [1, 2, 2, 3]);
      expect(r.first.player, a);
      expect(r.first.score, 30);
    });

    testWidgets('pod zwycięzcą są kolejne miejsca z punktami', (tester) async {
      final players = [
        _p('Ala')..points = 30,
        _p('Bob')..points = 20,
        _p('Cezary')..points = 20,
      ];
      await tester.pumpWidget(
        _app(
          EndGameScreen(
            players: players,
            log: const [],
            expansions: const {},
            elapsed: Duration.zero,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Zwycięzca'), findsOneWidget);
      expect(find.text('2.'), findsNWidgets(2));
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Cezary'), findsOneWidget);
      expect(find.text('20 pkt'), findsNWidgets(2));
    });
  });
}
