import 'package:flutter/material.dart';

import 'number_keypad.dart';

/// Maksymalna szerokość treści. Na tabletach i w poziomie reszta ekranu
/// zostaje pusta po bokach, dzięki czemu wiersze i formularze nie rozciągają się
/// na cały ekran i pozostają czytelne.
const double kMaxContentWidth = 640;

/// Szerokość panelu z klawiaturą numeryczną, gdy stoi obok formularza
/// (na bardzo szerokich ekranach panel jest odpowiednio szerszy).
const double kSideKeypadWidth = 340;

/// Czy ekran jest na tyle szeroki i niski (telefon lub tablet w poziomie),
/// że klawiatura numeryczna powinna stać obok formularza, a nie pod nim.
bool useSideKeypad(BoxConstraints c) =>
    c.maxWidth >= 560 && c.maxWidth > c.maxHeight;

/// Ogranicza szerokość [child] do [kMaxContentWidth] i wyśrodkowuje go.
///
/// Na wąskim ekranie (telefon w pionie) nic nie zmienia: dziecko dostaje całą
/// szerokość jak dotąd.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = kMaxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Układ ekranu z klawiaturą numeryczną.
///
/// W pionie: [form] zajmuje całą dostępną wysokość, a [keypad] leży pod nim
/// (jak dotąd). W poziomie na szerokim ekranie: [form] po lewej, a [keypad]
/// w osobnym panelu po prawej, na całą wysokość, żeby klawisze nie zasłaniały
/// formularza i nie powodowały przepełnienia.
///
/// [keypad] jest budowany z informacją, czy stoi z boku (`sideBySide`).
class KeypadLayout extends StatelessWidget {
  final Widget form;
  final Widget Function(bool sideBySide) keypad;

  const KeypadLayout({super.key, required this.form, required this.keypad});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (useSideKeypad(constraints)) {
          return Row(
            children: [
              Expanded(child: ContentWidth(child: form)),
              SideKeypadPanel(child: keypad(true)),
            ],
          );
        }
        return Column(
          children: [
            Expanded(child: ContentWidth(child: form)),
            keypad(false),
          ],
        );
      },
    );
  }
}

/// Panel po prawej stronie ekranu, w którym stoi klawiatura numeryczna.
class SideKeypadPanel extends StatelessWidget {
  final Widget child;

  const SideKeypadPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
      child: SizedBox(
        width: (MediaQuery.sizeOf(context).width * 0.3).clamp(
          kSideKeypadWidth,
          kSideKeypadWidth + 100,
        ),
        height: double.infinity,
        child: SafeArea(left: false, top: false, bottom: false, child: child),
      ),
    );
  }
}

/// Klawiatura numeryczna do [KeypadLayout]: w panelu z boku wyśrodkowana
/// i dopasowana do wysokości, pod formularzem z niewielkim odstępem od dołu.
Widget keypadBlock({
  required bool side,
  required ValueChanged<String> onKey,
}) {
  if (side) return Center(child: NumberKeypad(onKey: onKey));
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [NumberKeypad(onKey: onKey), const SizedBox(height: 8)],
  );
}
