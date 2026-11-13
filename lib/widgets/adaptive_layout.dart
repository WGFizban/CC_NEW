import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
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

/// Układ ekranu z klawiaturą numeryczną, taki sam jak na ekranie punktowania.
///
/// W pionie: [form] zajmuje całą dostępną wysokość, a klawiatura leży pod nim
/// w panelu, który zwija się przyciskiem w prawym górnym rogu albo stuknięciem
/// w puste miejsce formularza. Wysuwa się ponownie, gdy ekran ustawi [open] na
/// `true` (np. po stuknięciu w pole, które klawiatura wypełnia). W poziomie na
/// szerokim ekranie: [form] po lewej, a klawiatura w osobnym panelu po prawej,
/// na całą wysokość, zawsze widoczna (bez zwijania).
class CollapsibleKeypadLayout extends StatelessWidget {
  final Widget form;
  final ValueChanged<String> onKey;

  /// Czy klawiatura jest wysunięta (tylko układ pionowy).
  final ValueNotifier<bool> open;

  /// Opcjonalny element nad klawiszami (np. przełącznik pola).
  final Widget? top;

  const CollapsibleKeypadLayout({
    super.key,
    required this.form,
    required this.onKey,
    required this.open,
    this.top,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keypad = NumberKeypad(onKey: onKey, top: top);
        if (useSideKeypad(constraints)) {
          return Row(
            children: [
              Expanded(child: ContentWidth(child: form)),
              SideKeypadPanel(
                child: Column(
                  children: [
                    Expanded(child: Center(child: keypad)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            Expanded(
              child: ContentWidth(
                // Stuknięcie w puste miejsce zwija klawiaturę; kontrolki
                // (pola, checkboxy) obsługują stuknięcie same i jej nie chowają.
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => open.value = false,
                  child: form,
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: open,
              builder: (context, isOpen, _) => AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.bottomCenter,
                child: isOpen
                    ? Material(
                        elevation: 8,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  tooltip: context.l10n.collapseKeypad,
                                  visualDensity: VisualDensity.compact,
                                  iconSize: 24,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  onPressed: () => open.value = false,
                                ),
                              ),
                              keypad,
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ),
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
