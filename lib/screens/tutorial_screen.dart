import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/scoring.dart';
import '../widgets/game_dialogs.dart';
import '../widgets/game_icon.dart';
import '../widgets/tutorial_animations.dart';

/// Krótki samouczek: przesuwane strony z opisem kolejnych kroków gry.
/// Pokazywany przy pierwszym uruchomieniu i na życzenie z menu.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _Step {
  final Widget icon;
  final String title;
  final String body;

  const _Step(this.icon, this.title, this.body);
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Step> _steps(BuildContext context) {
    final l = context.l10n;
    final color = Theme.of(context).colorScheme.primary;
    Widget material(IconData icon) => Icon(icon, size: 96, color: color);
    return [
      _Step(
        GameIcon(ScoringType.city.iconAsset, size: 110),
        l.tutorial1Title,
        l.tutorial1Body,
      ),
      _Step(const AddPlayerAnimation(), l.tutorial2Title, l.tutorial2Body),
      _Step(const StartGameAnimation(), l.tutorial3Title, l.tutorial3Body),
      _Step(material(Icons.touch_app), l.tutorial4Title, l.tutorial4Body),
      _Step(material(Icons.undo), l.tutorial5Title, l.tutorial5Body),
      _Step(material(kEndGameIcon), l.tutorial6Title, l.tutorial6Body),
    ];
  }

  void _next(int count) {
    if (_page >= count - 1) {
      Navigator.pop(context);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final steps = _steps(context);
    final last = _page == steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tutorialTitle),
        automaticallyImplyLeading: false,
        actions: [
          if (!last)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.tutorialSkip),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                for (final s in steps)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            s.icon,
                            const SizedBox(height: 24),
                            Text(
                              s.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              s.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 17, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < steps.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _next(steps.length),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                ),
                child: Text(last ? l.tutorialDone : l.tutorialNext),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
