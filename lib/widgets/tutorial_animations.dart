import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'meeple_icon.dart';

/// Postęp [t] w przedziale [a]–[b] jako liczba 0–1 (poza przedziałem
/// przycina do 0 lub 1), z krzywą [curve].
double _seg(double t, double a, double b, [Curve curve = Curves.easeInOut]) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return curve.transform((t - a) / (b - a));
}

/// Bazowa scena animacji samouczka: makieta ekranu aplikacji, na której
/// zapętlona animacja pokazuje jedną czynność. Dotknięcie wstrzymuje i
/// wznawia animację. Przy włączonym w systemie ograniczeniu ruchu pokazuje
/// jedną, nieruchomą klatkę końcową.
abstract class _LoopingScene extends StatefulWidget {
  const _LoopingScene({super.key});
}

abstract class _LoopingSceneState<T extends _LoopingScene> extends State<T>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: duration,
  );

  Duration get duration;

  /// Klatka pokazywana przy ograniczonym ruchu.
  double get restingFrame => 0.9;

  bool _paused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      controller
        ..stop()
        ..value = restingFrame;
    } else if (!controller.isAnimating && !_paused) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _togglePause() {
    if (MediaQuery.of(context).disableAnimations) return;
    setState(() {
      _paused = !_paused;
      if (_paused) {
        controller.stop();
      } else {
        controller.repeat();
      }
    });
  }

  Widget buildScene(BuildContext context, double t);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePause,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => buildScene(context, controller.value),
      ),
    );
  }
}

/// Wspólna makieta telefonu: pasek tytułu, miejsce na treść i przycisk „+”.
class _PhoneFrame extends StatelessWidget {
  final double width;
  final double height;
  final List<Widget> children;

  const _PhoneFrame({
    required this.width,
    required this.height,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline, width: 3),
      ),
      child: Stack(children: children),
    );
  }
}

/// Palec (kropka z ikoną dotyku), którego opuszek jest w punkcie [tip].
Widget _finger(
  BuildContext context,
  Offset tip, {
  double opacity = 1,
  double pressed = 0,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Positioned(
    left: tip.dx - 10,
    top: tip.dy - 4,
    child: Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: 1 - 0.15 * pressed,
        alignment: Alignment.topLeft,
        child: Icon(Icons.touch_app, size: 34, color: scheme.onSurface),
      ),
    ),
  );
}

/// Kółko „kliknięcia” rozchodzące się od punktu [center] (postęp [t] 0–1).
Widget _tap(BuildContext context, Offset center, double t) {
  if (t <= 0 || t >= 1) return const SizedBox.shrink();
  final size = 14 + 34 * t;
  return Positioned(
    left: center.dx - size / 2,
    top: center.dy - size / 2,
    child: Opacity(
      opacity: 1 - t,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
    ),
  );
}

/// Animacja „Dodaj gracza”: palec dotyka „+”, w oknie wpisuje się imię,
/// po „Dodaj” nowy gracz pojawia się na liście.
class AddPlayerAnimation extends _LoopingScene {
  const AddPlayerAnimation({super.key});

  @override
  State<AddPlayerAnimation> createState() => _AddPlayerAnimationState();
}

class _AddPlayerAnimationState extends _LoopingSceneState<AddPlayerAnimation> {
  static const _name = 'Ala';
  static const _w = 280.0;
  static const _h = 230.0;

  // Położenia elementów makiety.
  static const _fab = Offset(_w - 38, _h - 38);
  static const _dialog = Rect.fromLTWH(34, 46, _w - 68, 150);
  static const _addButton = Offset(_w - 34 - 12 - 28, 46 + 150 - 12 - 13);

  // Paleta kolorów mepla w oknie (pokazujemy tylko kilka z nich; własny
  // kolor wybiera się w aplikacji z pełnej palety, co opisuje tekst kroku).
  static const _palette = [
    Color(0xFF1D27EA),
    Color(0xFFEA1D27),
    Color(0xFF078E04),
    Color(0xFFEAD21D),
    Color(0xFF000000),
  ];
  static const _chosen = 2;
  static const _dot = 18.0;
  static const _dotGap = 8.0;
  static const _dotsLeft = 34 + 12.0;
  static const _dotsTop = 46 + 12 + 17 + 8 + 30 + 8.0;
  static const _chosenDot = Offset(
    _dotsLeft + _dot / 2 + _chosen * (_dot + _dotGap),
    _dotsTop + _dot / 2,
  );

  @override
  Duration get duration => const Duration(seconds: 8);

  @override
  Widget buildScene(BuildContext context, double t) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    // Oś czasu (ułamek całej pętli).
    final toFab = _seg(t, 0.04, 0.17);
    final fabPress = _seg(t, 0.17, 0.22);
    final dialogIn = _seg(t, 0.22, 0.28, Curves.easeOut);
    final typing = _seg(t, 0.30, 0.44, Curves.linear);
    final toColor = _seg(t, 0.46, 0.52);
    final colorPress = _seg(t, 0.52, 0.56);
    final toAdd = _seg(t, 0.58, 0.66);
    final addPress = _seg(t, 0.66, 0.70);
    final dialogOut = _seg(t, 0.70, 0.75);
    final rowIn = _seg(t, 0.73, 0.83, Curves.easeOutBack);
    final fingerOut = _seg(t, 0.75, 0.80);
    final fadeAll = _seg(t, 0.94, 0.99);

    final typed = _name.substring(0, (typing * _name.length).round());
    final restFinger = Offset(_w * 0.55, _h * 0.62);
    final finger = t < 0.45
        ? Offset.lerp(restFinger, _fab, toFab)!
        : t < 0.57
        ? Offset.lerp(_fab, _chosenDot, toColor)!
        : Offset.lerp(_chosenDot, _addButton, toAdd)!;
    final colorChosen = colorPress > 0.5;
    final playerColor = colorChosen ? _palette[_chosen] : _palette[0];
    final fingerOpacity = (t < 0.04 ? _seg(t, 0, 0.04) : 1.0) *
        (1 - fingerOut) *
        (1 - fadeAll);
    double bump(double p) => p < 0.5 ? p * 2 : (1 - p) * 2;
    final pressing = t < 0.45
        ? bump(fabPress)
        : t < 0.57
        ? bump(colorPress)
        : bump(addPress);

    final dialogOpacity = dialogIn * (1 - dialogOut);
    final rowOpacity = rowIn.clamp(0.0, 1.0) * (1 - fadeAll);
    final fabScale = 1 - 0.12 * (t < 0.45 ? pressing : 0);

    return _PhoneFrame(
      width: _w,
      height: _h,
      children: [
        // Pasek tytułu.
        Container(
          height: 34,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: scheme.surfaceContainerHighest,
          child: Text(
            'Carcassonne Counter',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
        ),
        // Nowy wiersz gracza.
        Positioned(
          left: 10,
          right: 10,
          top: 44 + 14 * (1 - rowIn),
          child: Opacity(
            opacity: rowOpacity,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: playerCardColor(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  MeepleIcon(color: playerColor, size: 26),
                  const SizedBox(width: 8),
                  const Text(
                    _name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '0',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Przycisk „+”.
        Positioned(
          left: _fab.dx - 22,
          top: _fab.dy - 22,
          child: Transform.scale(
            scale: fabScale,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.add, color: scheme.onPrimaryContainer),
            ),
          ),
        ),
        // Okno dodawania gracza.
        if (dialogOpacity > 0)
          Positioned.fromRect(
            rect: _dialog,
            child: Opacity(
              opacity: dialogOpacity,
              child: Transform.scale(
                scale: 0.85 + 0.15 * dialogIn,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(blurRadius: 12, color: Colors.black38),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.addPlayer,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 30,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.outline),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typed.isEmpty ? l.nameLabel : typed,
                          style: TextStyle(
                            fontSize: 13,
                            color: typed.isEmpty
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var i = 0; i < _palette.length; i++)
                            Container(
                              width: _dot,
                              height: _dot,
                              margin: const EdgeInsets.only(right: _dotGap),
                              decoration: BoxDecoration(
                                color: _palette[i],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (colorChosen && i == _chosen) ||
                                          (!colorChosen && i == 0)
                                      ? scheme.primary
                                      : scheme.outlineVariant,
                                  width: (colorChosen && i == _chosen) ||
                                          (!colorChosen && i == 0)
                                      ? 3
                                      : 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            l.add,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        _tap(context, _fab, fabPress),
        _tap(context, _chosenDot, colorPress),
        _tap(context, _addButton, addPress),
        _finger(
          context,
          finger,
          opacity: fingerOpacity,
          pressed: pressing,
        ),
      ],
    );
  }
}

/// Wiersz gracza na makiecie (mepel w kolorze, imię, wynik).
Widget _playerRow(
  BuildContext context, {
  required double top,
  required Color color,
  required String name,
  String score = '0',
}) {
  return Positioned(
    left: 10,
    right: 10,
    top: top,
    child: Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: playerCardColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          MeepleIcon(color: color, size: 26),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            score,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    ),
  );
}

/// Animacja „Rozpocznij grę”: palec dotyka „Rozpocznij grę”, w oknie
/// potwierdza, a przyciski dodawania graczy zastępuje flaga końca gry.
class StartGameAnimation extends _LoopingScene {
  const StartGameAnimation({super.key});

  @override
  State<StartGameAnimation> createState() => _StartGameAnimationState();
}

class _StartGameAnimationState extends _LoopingSceneState<StartGameAnimation> {
  static const _w = 280.0;
  static const _h = 230.0;

  static const _startButton = Offset(66, _h - 36);
  static const _fab = Offset(_w - 38, _h - 38);
  static const _dialog = Rect.fromLTWH(34, 56, _w - 68, 128);
  static const _confirmButton = Offset(_w - 34 - 12 - 48, 56 + 128 - 12 - 13);

  @override
  Duration get duration => const Duration(seconds: 8);

  @override
  Widget buildScene(BuildContext context, double t) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final toStart = _seg(t, 0.04, 0.18);
    final startPress = _seg(t, 0.18, 0.23);
    final dialogIn = _seg(t, 0.24, 0.30, Curves.easeOut);
    final toConfirm = _seg(t, 0.44, 0.56);
    final confirmPress = _seg(t, 0.56, 0.61);
    final dialogOut = _seg(t, 0.61, 0.66);
    final swap = _seg(t, 0.64, 0.74);
    final fingerOut = _seg(t, 0.66, 0.72);
    final fadeAll = _seg(t, 0.94, 0.99);

    double bump(double p) => p < 0.5 ? p * 2 : (1 - p) * 2;
    final restFinger = Offset(_w * 0.5, _h * 0.55);
    final finger = t < 0.4
        ? Offset.lerp(restFinger, _startButton, toStart)!
        : Offset.lerp(_startButton, _confirmButton, toConfirm)!;
    final fingerOpacity =
        (t < 0.04 ? _seg(t, 0, 0.04) : 1.0) * (1 - fingerOut) * (1 - fadeAll);
    final pressing = t < 0.4 ? bump(startPress) : bump(confirmPress);
    final dialogOpacity = dialogIn * (1 - dialogOut);

    return _PhoneFrame(
      width: _w,
      height: _h,
      children: [
        Container(
          height: 34,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: scheme.surfaceContainerHighest,
          child: Text(
            'Carcassonne Counter',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
        ),
        _playerRow(
          context,
          top: 44,
          color: const Color(0xFF1D27EA),
          name: 'Ala',
        ),
        _playerRow(
          context,
          top: 88,
          color: const Color(0xFFEA1D27),
          name: 'Bob',
        ),
        // Przed startem: „Rozpocznij grę” i „+”.
        Positioned(
          left: 12,
          top: _h - 56,
          child: Opacity(
            opacity: 1 - swap,
            child: Transform.scale(
              scale: 1 - 0.08 * (t < 0.4 ? pressing : 0),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      size: 18,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l.startGame,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: _fab.dx - 22,
          top: _fab.dy - 22,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 1 - swap,
                  child: Icon(Icons.add, color: scheme.onPrimaryContainer),
                ),
                Opacity(
                  opacity: swap,
                  child: Icon(Icons.flag, color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
        if (dialogOpacity > 0)
          Positioned.fromRect(
            rect: _dialog,
            child: Opacity(
              opacity: dialogOpacity,
              child: Transform.scale(
                scale: 0.85 + 0.15 * dialogIn,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(blurRadius: 12, color: Colors.black38),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.startGameQuestion,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            l.startGame,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        _tap(context, _startButton, startPress),
        _tap(context, _confirmButton, confirmPress),
        _finger(context, finger, opacity: fingerOpacity, pressed: pressing),
      ],
    );
  }
}
