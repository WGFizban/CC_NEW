import 'dart:async';

import 'package:flutter/material.dart';

import 'players_screen.dart';

/// Kolor tła ekranu startowego (taki sam jak natywny splash, więc przejście
/// jest płynne).
const Color kSplashColor = Color(0xFF000080);

/// Ekran powitalny aplikacji: logo wjeżdża z lekkim powiększeniem, zostaje na
/// ekranie około dwóch sekund i płynnie przechodzi do głównego ekranu.
/// Stuknięcie pomija czekanie.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 2400);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  Timer? _timer;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_total, _leave);
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const PlayersScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    final width = MediaQuery.sizeOf(context).shortestSide * 0.78;

    return Scaffold(
      backgroundColor: kSplashColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _leave,
        child: Center(
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1).animate(curved),
              child: Image.asset(
                'assets/icons/splash_logo.png',
                width: width.clamp(200, 460),
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
