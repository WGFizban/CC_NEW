import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/widgets/number_keypad.dart';

Color? _bg(WidgetTester tester, String key) => tester
    .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, key))
    .style
    ?.backgroundColor
    ?.resolve({});

void main() {
  testWidgets('klawisze C i < mają własne kolory, cyfry domyślne', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: NumberKeypad(onKey: (_) {}))),
    );

    expect(_bg(tester, 'C'), NumberKeypad.clearColor);
    expect(_bg(tester, '<'), NumberKeypad.backspaceColor);
    expect(NumberKeypad.clearColor, isNot(NumberKeypad.backspaceColor));
    for (final key in ['0', '5', '9']) {
      expect(_bg(tester, key), isNull);
    }
  });

  testWidgets('klawisze nadal przekazują wciśnięty znak', (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: NumberKeypad(onKey: pressed.add))),
    );

    await tester.tap(find.text('C'));
    await tester.tap(find.text('<'));
    await tester.tap(find.text('7'));

    expect(pressed, ['C', '<', '7']);
  });
}
