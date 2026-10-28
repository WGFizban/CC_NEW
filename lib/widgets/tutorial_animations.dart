import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import '../models/expansion.dart';
import '../models/scoring.dart';
import '../theme/app_theme.dart';
import 'game_icon.dart';
import 'meeple_icon.dart';

/// Gracze z przykładów: Ala (zielony, wybrany w animacji dodawania gracza)
/// i Bob (czerwony).
const Color _kAla = Color(0xFF078E04);
const Color _kBob = Color(0xFFEA1D27);

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
      ),
      // Ramka jest rysowana NA treści (a nie wokół niej), więc zawartość ma
      // pełny rozmiar makiety, a jej rogi nie wchodzą na zaokrąglenie ramki.
      foregroundDecoration: BoxDecoration(
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
    _kAla,
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
          color: _kAla,
          name: 'Ala',
        ),
        _playerRow(
          context,
          top: 88,
          color: _kBob,
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

// ---------------------------------------------------------------------------
// Wspólne elementy kolejnych scen.

double _bump(double p) => p < 0.5 ? p * 2 : (1 - p) * 2;

Widget _titleBar(BuildContext context, {Widget? trailing, String? title}) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    color: scheme.surfaceContainerHighest,
    child: Row(
      children: [
        Text(
          title ?? 'Carcassonne Counter',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    ),
  );
}

/// Zasłona w kolorze tła do płynnego startu i końca pętli: w pełni kryje
/// scenę na początku ([fadeIn] 0→1 ją odsłania) i na końcu ([fadeOut]).
Widget _veil(BuildContext context, double t, {double fadeOutFrom = 0.94}) {
  final cover = (1 - _seg(t, 0, 0.03)) > _seg(t, fadeOutFrom, 0.99)
      ? 1 - _seg(t, 0, 0.03)
      : _seg(t, fadeOutFrom, 0.99);
  if (cover <= 0) return const SizedBox.shrink();
  return Positioned.fill(
    child: IgnorePointer(
      child: Opacity(
        opacity: cover,
        child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
      ),
    ),
  );
}

Widget _pill(
  BuildContext context,
  String text, {
  required Color color,
  Color textColor = Colors.white,
  double? width,
  double height = 32,
  IconData? icon,
}) {
  return Container(
    width: width,
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(height / 2),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ),
      ],
    ),
  );
}

Widget _dialogCard(BuildContext context, Rect rect, double appear, Widget child) {
  final scheme = Theme.of(context).colorScheme;
  return Positioned.fromRect(
    rect: rect,
    child: Opacity(
      opacity: appear.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.85 + 0.15 * appear.clamp(0.0, 1.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black38)],
          ),
          child: child,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------

/// Animacja „Dodawaj punkty”: dotknięcie wiersza gracza, wybór „Droga”,
/// wpisanie płytek i „Zatwierdź”; wynik pojawia się na liście.
class ScoreAnimation extends _LoopingScene {
  const ScoreAnimation({super.key});

  @override
  State<ScoreAnimation> createState() => _ScoreAnimationState();
}

class _ScoreAnimationState extends _LoopingSceneState<ScoreAnimation> {
  static const _w = 280.0;
  static const _h = 230.0;

  static const _alaRow = Offset(140, 63);
  static const _roadTile = Offset(140, 102);
  static const _confirm = Offset(207, 196);

  @override
  Duration get duration => const Duration(seconds: 10);

  @override
  Widget buildScene(BuildContext context, double t) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    final rowPress = _seg(t, 0.12, 0.16);
    final ab = _seg(t, 0.16, 0.20);
    final roadPress = _seg(t, 0.32, 0.36);
    final bc = _seg(t, 0.36, 0.40);
    final typing = _seg(t, 0.42, 0.46, Curves.linear);
    final confirmPress = _seg(t, 0.62, 0.66);
    final ca = _seg(t, 0.66, 0.72);
    final fingerOut = _seg(t, 0.72, 0.78);

    // Ekran 1 leży na dole, a pozostałe wsuwają się na niego nieprzezroczyste
    // (tylko z płynnym pojawianiem się), więc treść spod spodu nie
    // prześwituje. Wyjście z ekranu 3 odsłania ekran 1.
    const aOp = 1.0;
    final bOp = ca > 0 ? 0.0 : ab;
    final cOp = bc * (1 - ca);

    final restFinger = Offset(_w * 0.7, _h * 0.7);
    final finger = t < 0.15
        ? Offset.lerp(restFinger, _alaRow, _seg(t, 0.03, 0.12))!
        : t < 0.40
        ? Offset.lerp(_alaRow, _roadTile, _seg(t, 0.22, 0.32))!
        : Offset.lerp(_roadTile, _confirm, _seg(t, 0.50, 0.62))!;
    final pressing = t < 0.2
        ? _bump(rowPress)
        : t < 0.45
        ? _bump(roadPress)
        : _bump(confirmPress);
    final fingerOpacity = _seg(t, 0.02, 0.05) * (1 - fingerOut);

    final digit = typing >= 0.5 ? '4' : '';
    final points = digit.isEmpty ? 0 : 4;
    final alaScore = t > 0.69 ? '4' : '0';

    // Nagłówek przypięty do góry ekranu ([mepel] tekst [mepel]); musi być
    // Positioned, inaczej rozciąga się na całą makietę i nachodzi na treść.
    Widget header(Widget center) => Positioned(
      left: 10,
      right: 10,
      top: 8,
      height: 40,
      child: Row(
        children: [
          MeepleIcon(color: _kAla, size: 32),
          Expanded(child: Center(child: center)),
          MeepleIcon(color: _kAla, size: 32),
        ],
      ),
    );

    Widget tile(ScoringType type, String label, double left) => Positioned(
      left: left,
      top: 62,
      child: Container(
        width: 78,
        height: 80,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GameIcon(type.iconAsset, size: 44),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );

    return _PhoneFrame(
      width: _w,
      height: _h,
      children: [
        // Ekran 1: lista graczy.
        Positioned.fill(
          child: Opacity(
            opacity: aOp,
            child: Stack(
              children: [
                _titleBar(context),
                _playerRow(context, top: 44, color: _kAla, name: 'Ala', score: alaScore),
                _playerRow(context, top: 88, color: _kBob, name: 'Bob'),
              ],
            ),
          ),
        ),
        // Ekran 2: wybór rodzaju punktacji.
        if (bOp > 0)
          Positioned.fill(
            child: Opacity(
              opacity: bOp,
              child: Container(
                color: bg,
                child: Stack(
                  children: [
                    header(
                      Text(
                        l.addPointsTitle('Ala'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: scheme.onSurface),
                      ),
                    ),
                    tile(ScoringType.city, l.scCity, 10),
                    tile(ScoringType.road, l.scRoad, 101),
                    tile(ScoringType.cloister, ScoringType.cloister.title(l), 192),
                    Positioned(
                      left: 14,
                      right: 14,
                      top: _h - 50,
                      child: _pill(
                        context,
                        l.cancel,
                        color: const Color(0xFFC62828),
                        height: 34,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Ekran 3: wynik i płytki.
        if (cOp > 0)
          Positioned.fill(
            child: Opacity(
              opacity: cOp,
              child: Container(
                color: bg,
                child: Stack(
                  children: [
                    header(
                      Text(
                        l.scoreLabel(points),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 62,
                      child: Column(
                        children: [
                          Text(
                            l.tiles,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 56,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: scheme.primary, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              digit.isEmpty ? '0' : digit,
                              style: TextStyle(
                                fontSize: 18,
                                color: digit.isEmpty
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: _h - 52,
                      child: Row(
                        children: [
                          Expanded(
                            child: _pill(
                              context,
                              l.cancel,
                              color: const Color(0xFFC62828),
                              height: 36,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _pill(
                              context,
                              l.confirm,
                              color: const Color(0xFF2E9E44),
                              height: 36,
                              icon: Icons.check,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        _tap(context, _alaRow, rowPress),
        _tap(context, _roadTile, roadPress),
        _tap(context, _confirm, confirmPress),
        _veil(context, t),
        _finger(context, finger, opacity: fingerOpacity, pressed: pressing),
      ],
    );
  }
}

/// Animacja „Pomyłka?”: menu (⋮), „Cofnij ostatnie punkty”, wynik wraca.
class UndoAnimation extends _LoopingScene {
  const UndoAnimation({super.key});

  @override
  State<UndoAnimation> createState() => _UndoAnimationState();
}

class _UndoAnimationState extends _LoopingSceneState<UndoAnimation> {
  static const _w = 280.0;
  static const _h = 230.0;

  static const _menuButton = Offset(_w - 24, 17);
  static const _menu = Rect.fromLTWH(_w - 178, 32, 166, 140);
  static const _undoItem = Offset(_w - 178 + 83, 32 + 14 + 14);

  @override
  Duration get duration => const Duration(seconds: 8);

  @override
  Widget buildScene(BuildContext context, double t) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final menuPress = _seg(t, 0.16, 0.20);
    final menuIn = _seg(t, 0.20, 0.26, Curves.easeOut);
    final itemPress = _seg(t, 0.46, 0.50);
    final menuOut = _seg(t, 0.50, 0.56);
    final fingerOut = _seg(t, 0.56, 0.62);

    final restFinger = Offset(_w * 0.5, _h * 0.7);
    final finger = t < 0.3
        ? Offset.lerp(restFinger, _menuButton, _seg(t, 0.04, 0.16))!
        : Offset.lerp(_menuButton, _undoItem, _seg(t, 0.34, 0.46))!;
    final pressing = t < 0.3 ? _bump(menuPress) : _bump(itemPress);
    final fingerOpacity = _seg(t, 0.02, 0.05) * (1 - fingerOut);
    final menuOpacity = menuIn * (1 - menuOut);
    final reverted = t > 0.54;

    Widget item(
      String text,
      int i, {
      bool highlight = false,
      bool emphasized = false,
    }) => Positioned(
      left: _menu.left,
      top: _menu.top + 14 + i * 28.0,
      width: _menu.width,
      height: 28,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: highlight
            ? scheme.primary.withValues(alpha: 0.18)
            : Colors.transparent,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: emphasized ? FontWeight.bold : FontWeight.normal,
            color: emphasized ? scheme.primary : scheme.onSurface,
          ),
        ),
      ),
    );

    return _PhoneFrame(
      width: _w,
      height: _h,
      children: [
        _titleBar(
          context,
          trailing: Icon(Icons.more_vert, size: 20, color: scheme.onSurface),
        ),
        _playerRow(
          context,
          top: 44,
          color: _kAla,
          name: 'Ala',
          score: reverted ? '0' : '4',
        ),
        _playerRow(context, top: 88, color: _kBob, name: 'Bob'),
        if (menuOpacity > 0)
          Positioned.fromRect(
            rect: _menu,
            child: Opacity(
              opacity: menuOpacity,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(blurRadius: 10, color: Colors.black38),
                  ],
                ),
              ),
            ),
          ),
        if (menuOpacity > 0)
          Opacity(
            opacity: menuOpacity,
            child: Stack(
              children: [
                item(l.menuUndoNone, 0, highlight: itemPress > 0),
                item(l.newGame, 1),
                // Skrót zasad jest wspomniany w tekście kroku, więc go
                // wyróżniamy.
                item(l.rulesTitle, 2, emphasized: true),
                item(l.menuTutorial, 3),
              ],
            ),
          ),
        _tap(context, _menuButton, menuPress),
        _tap(context, _undoItem, itemPress),
        _veil(context, t),
        _finger(context, finger, opacity: fingerOpacity, pressed: pressing),
      ],
    );
  }
}

/// Animacja „Koniec gry”: flaga, potwierdzenie i ekran zwycięzcy.
class EndGameAnimation extends _LoopingScene {
  const EndGameAnimation({super.key});

  @override
  State<EndGameAnimation> createState() => _EndGameAnimationState();
}

class _EndGameAnimationState extends _LoopingSceneState<EndGameAnimation> {
  static const _w = 280.0;
  static const _h = 230.0;

  static const _flag = Offset(_w - 38, _h - 38);
  static const _dialog = Rect.fromLTWH(34, 56, _w - 68, 112);
  static const _yes = Offset(_w - 34 - 12 - 18, 56 + 112 - 12 - 13);

  @override
  Duration get duration => const Duration(seconds: 9);

  @override
  Widget buildScene(BuildContext context, double t) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    final flagPress = _seg(t, 0.16, 0.20);
    final dialogIn = _seg(t, 0.20, 0.26, Curves.easeOut);
    final yesPress = _seg(t, 0.46, 0.50);
    final dialogOut = _seg(t, 0.50, 0.55);
    final swap = _seg(t, 0.54, 0.62);
    final fingerOut = _seg(t, 0.50, 0.56);

    final restFinger = Offset(_w * 0.55, _h * 0.55);
    final finger = t < 0.3
        ? Offset.lerp(restFinger, _flag, _seg(t, 0.04, 0.16))!
        : Offset.lerp(_flag, _yes, _seg(t, 0.34, 0.46))!;
    final pressing = t < 0.3 ? _bump(flagPress) : _bump(yesPress);
    final fingerOpacity = _seg(t, 0.02, 0.05) * (1 - fingerOut);
    final dialogOpacity = dialogIn * (1 - dialogOut);

    return _PhoneFrame(
      width: _w,
      height: _h,
      children: [
        // Ekran z listą graczy.
        Positioned.fill(
          child: Opacity(
            opacity: 1 - swap,
            child: Stack(
              children: [
                _titleBar(context),
                _playerRow(context, top: 44, color: _kAla, name: 'Ala', score: '12'),
                _playerRow(context, top: 88, color: _kBob, name: 'Bob', score: '7'),
                Positioned(
                  left: _flag.dx - 22,
                  top: _flag.dy - 22,
                  child: Transform.scale(
                    scale: 1 - 0.12 * (t < 0.3 ? pressing : 0),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.flag, color: scheme.onPrimaryContainer),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (dialogOpacity > 0)
          _dialogCard(
            context,
            _dialog,
            dialogOpacity,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.endGameQuestion,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.no,
                        style: TextStyle(fontSize: 12, color: scheme.primary),
                      ),
                      const SizedBox(width: 12),
                      _pill(
                        context,
                        l.yes,
                        color: scheme.primary,
                        textColor: scheme.onPrimary,
                        height: 26,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Ekran końca gry.
        if (swap > 0)
          Positioned.fill(
            child: Opacity(
              opacity: swap,
              child: Container(
                color: bg,
                child: Stack(
                  children: [
                    _titleBar(context, title: l.gameOver),
                    Positioned(
                      left: 14,
                      right: 14,
                      top: 46,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              size: 34,
                              color: Color(0xFFD4A017),
                            ),
                            Text(
                              l.winner,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MeepleIcon(color: _kAla, size: 24),
                                const SizedBox(width: 4),
                                Text(
                                  'Ala',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              l.pointsValue(12),
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      top: 156,
                      child: _pill(
                        context,
                        l.summaryTitle,
                        color: scheme.surfaceContainerHighest,
                        textColor: scheme.onSurface,
                        icon: Icons.table_chart_outlined,
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      top: 192,
                      child: _pill(
                        context,
                        l.newGame,
                        color: scheme.primary,
                        textColor: scheme.onPrimary,
                        icon: Icons.refresh,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        _tap(context, _flag, flagPress),
        _tap(context, _yes, yesPress),
        _veil(context, t),
        _finger(context, finger, opacity: fingerOpacity, pressed: pressing),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

/// Przełącznik makiety: [on] 0 → wyłączony, 1 → włączony (płynnie).
Widget _miniSwitch(BuildContext context, double on) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    width: 38,
    height: 22,
    decoration: BoxDecoration(
      color: Color.lerp(scheme.surfaceContainerHighest, scheme.primary, on),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(
        color: Color.lerp(scheme.outline, scheme.primary, on)!,
        width: 2,
      ),
    ),
    child: Align(
      alignment: Alignment(-1 + 2 * on, 0),
      child: Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(scheme.outline, scheme.onPrimary, on),
        ),
      ),
    ),
  );
}

/// Animacja „Wybierz dodatki”: menu (⋮) → „Dodatki” → włączenie kilku
/// dodatków przełącznikami.
class ExpansionsAnimation extends _LoopingScene {
  const ExpansionsAnimation({super.key});

  @override
  State<ExpansionsAnimation> createState() => _ExpansionsAnimationState();
}

class _ExpansionsAnimationState
    extends _LoopingSceneState<ExpansionsAnimation> {
  static const _w = 280.0;
  static const _h = 230.0;

  static const _menuButton = Offset(_w - 24, 17);
  static const _menu = Rect.fromLTWH(_w - 178, 32, 166, 140);
  static const _expansionsItem = Offset(_w - 178 + 83, 32 + 14 + 2 * 28 + 14);

  static const _rowsTop = 40.0;
  static const _rowH = 34.0;
  static const _switchX = _w - 14 - 19;
  // Wiersze: 0 „Wszystkie dodatki”, 1.. poszczególne dodatki.
  static const _expansions = [
    Expansion.innsCathedrals,
    Expansion.tradersBuilders,
    Expansion.princessDragon,
    Expansion.tower,
  ];
  static const _firstTap = 2; // „Kupcy i budowniczowie”
  static const _secondTap = 4; // „Wieża”

  static Offset _switchCenter(int row) =>
      Offset(_switchX, _rowsTop + row * _rowH + _rowH / 2);

  @override
  Duration get duration => const Duration(seconds: 11);

  @override
  Widget buildScene(BuildContext context, double t) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    final menuPress = _seg(t, 0.14, 0.18);
    final menuIn = _seg(t, 0.18, 0.24, Curves.easeOut);
    final itemPress = _seg(t, 0.40, 0.44);
    final menuOut = _seg(t, 0.44, 0.48);
    final screenIn = _seg(t, 0.46, 0.52);
    final firstPress = _seg(t, 0.66, 0.70);
    final firstOn = _seg(t, 0.68, 0.72);
    final secondPress = _seg(t, 0.86, 0.90);
    final secondOn = _seg(t, 0.88, 0.92);
    final fingerOut = _seg(t, 0.92, 0.96);

    final restFinger = Offset(_w * 0.5, _h * 0.75);
    final finger = t < 0.3
        ? Offset.lerp(restFinger, _menuButton, _seg(t, 0.04, 0.14))!
        : t < 0.5
        ? Offset.lerp(_menuButton, _expansionsItem, _seg(t, 0.30, 0.40))!
        : t < 0.75
        ? Offset.lerp(
            _expansionsItem,
            _switchCenter(_firstTap),
            _seg(t, 0.56, 0.66),
          )!
        : Offset.lerp(
            _switchCenter(_firstTap),
            _switchCenter(_secondTap),
            _seg(t, 0.76, 0.86),
          )!;
    final pressing = t < 0.3
        ? _bump(menuPress)
        : t < 0.5
        ? _bump(itemPress)
        : t < 0.75
        ? _bump(firstPress)
        : _bump(secondPress);
    final fingerOpacity = _seg(t, 0.02, 0.05) * (1 - fingerOut);
    final menuOpacity = menuIn * (1 - menuOut);

    Widget menuItem(String text, int i, {bool emphasized = false}) =>
        Positioned(
          left: _menu.left,
          top: _menu.top + 14 + i * 28.0,
          width: _menu.width,
          height: 28,
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: emphasized && itemPress > 0
                ? scheme.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: emphasized ? FontWeight.bold : FontWeight.normal,
                color: emphasized ? scheme.primary : scheme.onSurface,
              ),
            ),
          ),
        );

    Widget switchRow(int row, String text, double on, {bool bold = false}) =>
        Positioned(
          left: 14,
          right: 14,
          top: _rowsTop + row * _rowH,
          height: _rowH,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              _miniSwitch(context, on),
            ],
          ),
        );

    final onValues = [
      0.0, // Karczmy i katedry
      firstOn, // Kupcy i budowniczowie
      0.0, // Księżniczka i smok
      secondOn, // Wieża
    ];
    final allOn = 0.0;

    return _PhoneFrame(
      width: _w,
      height: _h,
      children: [
        // Ekran 1: lista graczy i menu.
        Positioned.fill(
          child: Stack(
            children: [
              _titleBar(
                context,
                trailing: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: scheme.onSurface,
                ),
              ),
              _playerRow(context, top: 44, color: _kAla, name: 'Ala'),
              _playerRow(context, top: 88, color: _kBob, name: 'Bob'),
            ],
          ),
        ),
        if (menuOpacity > 0)
          Positioned.fromRect(
            rect: _menu,
            child: Opacity(
              opacity: menuOpacity,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(blurRadius: 10, color: Colors.black38),
                  ],
                ),
              ),
            ),
          ),
        if (menuOpacity > 0)
          Opacity(
            opacity: menuOpacity,
            child: Stack(
              children: [
                menuItem(l.menuUndoNone, 0),
                menuItem(l.newGame, 1),
                menuItem(l.expansionsSection, 2, emphasized: true),
                menuItem(l.rulesTitle, 3),
              ],
            ),
          ),
        // Ekran 2: lista dodatków.
        if (screenIn > 0)
          Positioned.fill(
            child: Opacity(
              opacity: screenIn,
              child: Container(
                color: bg,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        color: scheme.surfaceContainerHighest,
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_back,
                              size: 18,
                              color: scheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l.expansionsSection,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    switchRow(0, l.allExpansions, allOn, bold: true),
                    for (var i = 0; i < _expansions.length; i++)
                      switchRow(i + 1, _expansions[i].label(l), onValues[i]),
                  ],
                ),
              ),
            ),
          ),
        _tap(context, _menuButton, menuPress),
        _tap(context, _expansionsItem, itemPress),
        _tap(context, _switchCenter(_firstTap), firstPress),
        _tap(context, _switchCenter(_secondTap), secondPress),
        _veil(context, t, fadeOutFrom: 0.96),
        _finger(context, finger, opacity: fingerOpacity, pressed: pressing),
      ],
    );
  }
}
