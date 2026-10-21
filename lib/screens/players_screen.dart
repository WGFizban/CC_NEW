import 'dart:async';

import 'package:flutter/material.dart';

import '../models/circus.dart';
import '../models/expansion.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../models/scoring.dart';
import '../models/standings.dart';
import '../services/players_storage.dart';
import '../services/settings_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/goods_widgets.dart';
import '../widgets/meeple_icon.dart';
import '../widgets/player_dialog.dart';
import 'add_points_screen.dart';
import 'bazaar_screen.dart';
import 'circus_screen.dart';
import 'expansions_screen.dart';
import 'flock_screen.dart';
import 'pyramid_screen.dart';
import 'select_points_type_screen.dart';

enum _MenuAction {
  undo,
  reset,
  expansions,
  startTimer,
  stopTimer,
  resetTimer,
}

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _storage = PlayersStorage();
  final _settingsStorage = SettingsStorage();
  final List<Player> _players = [];
  GameSettings _settings = GameSettings();

  /// Historia zatwierdzonych punktów w tej sesji (do cofania).
  final List<ScoreEvent> _history = [];

  // Stoper liczy czas z [Stopwatch], więc nie gubi sekund, gdy aplikacja
  // jest w tle; [Timer] służy tylko do odświeżania widoku.
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  /// Kolory podstawowe, które nie są jeszcze zajęte przez żadnego gracza.
  List<Color> get _availableColors => [
    for (final c in kPlayerColors)
      if (!_players.any((p) => p.color == c)) c,
  ];

  bool _has(Expansion e) => _settings.expansions.contains(e);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- dane

  Future<void> _load() async {
    final loaded = await _storage.load();
    final settings = await _settingsStorage.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _players
        ..clear()
        ..addAll(loaded);
      _sortPlayers();
    });
  }

  void _save() => unawaited(_storage.save(_players));

  void _saveSettings() => unawaited(_settingsStorage.save(_settings));

  /// Sortuje po wyniku na bieżąco, czyli z premią za surowce.
  void _sortPlayers() {
    final scores = {for (final p in _players) p: totalScore(p, _players)};
    _players.sort((a, b) => scores[b]!.compareTo(scores[a]!));
  }

  // --------------------------------------------------------------- stoper

  void _startTimer() {
    _ticker?.cancel();
    _stopwatch.start();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
    setState(() {});
  }

  void _stopTimer() {
    _ticker?.cancel();
    _stopwatch.stop();
    setState(() {});
  }

  void _resetTimer() {
    _ticker?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {});
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  // -------------------------------------------------------------- akcje

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onAddPlayer() async {
    final result = await showPlayerDialog(
      context,
      availableColors: _availableColors,
    );
    if (result == null || result.delete || !mounted) return;
    setState(() {
      _players.add(Player(name: result.name, color: result.color));
      _sortPlayers();
    });
    _save();
  }

  Future<void> _onEditPlayer(Player player) async {
    final result = await showPlayerDialog(
      context,
      availableColors: _availableColors,
      player: player,
    );
    if (result == null || !mounted) return;

    if (result.delete) {
      final confirmed = await _confirm(
        title: 'Usunąć gracza?',
        message: '${player.name} zostanie usunięty razem z punktami.',
        confirmLabel: 'Usuń',
      );
      if (!confirmed) return;
      setState(() {
        _players.remove(player);
        _history.removeWhere(
          (e) => e.changes.any((c) => c.player == player),
        );
        _sortPlayers();
      });
    } else {
      setState(() {
        player
          ..name = result.name
          ..color = result.color;
      });
    }
    _save();
  }

  Future<void> _onScorePlayer(Player player) async {
    final type = await Navigator.push<ScoringType>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectPointsTypeScreen(
          player: player,
          types: ScoringType.availableFor(_settings.expansions),
        ),
      ),
    );
    if (type == null || !mounted) return;

    final event = await Navigator.push<ScoreEvent>(
      context,
      MaterialPageRoute(builder: (_) => _scoringScreen(player, type)),
    );
    if (event == null || !mounted) return;

    _applyEvent(event);
  }

  Widget _scoringScreen(Player player, ScoringType type) {
    final players = List<Player>.of(_players);
    return switch (type) {
      ScoringType.sheep => FlockScreen(player: player, players: players),
      ScoringType.bazaar => BazaarScreen(player: player, players: players),
      ScoringType.pyramid => PyramidScreen(players: players),
      ScoringType.circus => CircusScreen(
        player: player,
        players: players,
        used: Map<CircusAnimal, int>.of(_settings.usedAnimals),
      ),
      _ => AddPointsScreen(
        player: player,
        players: players,
        type: type,
        expansions: _settings.expansions,
      ),
    };
  }

  void _applyEvent(ScoreEvent event) {
    setState(() {
      event.apply();
      _history.add(event);
      final animal = event.animal;
      if (animal != null) {
        _settings.usedAnimals[animal] =
            (_settings.usedAnimals[animal] ?? 0) + 1;
      }
      _sortPlayers();
    });
    _save();
    _saveSettings();
  }

  void _undo() {
    if (_history.isEmpty) return;
    final event = _history.removeLast();
    setState(() {
      event.revert();
      final animal = event.animal;
      if (animal != null) {
        final left = (_settings.usedAnimals[animal] ?? 0) - 1;
        if (left > 0) {
          _settings.usedAnimals[animal] = left;
        } else {
          _settings.usedAnimals.remove(animal);
        }
      }
      _sortPlayers();
    });
    _save();
    _saveSettings();
  }

  Future<void> _onReset() async {
    final confirmed = await _confirm(
      title: 'Nowa gra?',
      message:
          'Punkty, surowce i zużyte żetony cyrku zostaną wyzerowane, '
          'a stoper zatrzymany.',
      confirmLabel: 'Resetuj',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      for (final p in _players) {
        p.points = 0;
        p.goods.updateAll((goods, count) => 0);
      }
      _history.clear();
      _settings.usedAnimals.clear();
    });
    _resetTimer();
    _save();
    _saveSettings();
  }

  Future<void> _openExpansions() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpansionsScreen(
          initial: _settings.expansions,
          onChanged: (enabled) {
            setState(() {
              _settings.expansions
                ..clear()
                ..addAll(enabled);
            });
            _saveSettings();
          },
        ),
      ),
    );
  }

  void _onMenuSelected(_MenuAction action) {
    switch (action) {
      case _MenuAction.undo:
        _undo();
      case _MenuAction.reset:
        _onReset();
      case _MenuAction.expansions:
        _openExpansions();
      case _MenuAction.startTimer:
        _startTimer();
      case _MenuAction.stopTimer:
        _stopTimer();
      case _MenuAction.resetTimer:
        _resetTimer();
    }
  }

  // ------------------------------------------------------------- widoki

  List<PopupMenuEntry<_MenuAction>> _buildMenuItems() {
    final last = _history.isEmpty ? null : _history.last;
    return [
      PopupMenuItem(
        value: _MenuAction.undo,
        enabled: last != null,
        child: Text(
          last == null ? 'Cofnij ostatnie punkty' : 'Cofnij: ${last.label}',
        ),
      ),
      const PopupMenuItem(
        value: _MenuAction.reset,
        child: Text('Resetuj punkty'),
      ),
      const PopupMenuItem(
        value: _MenuAction.expansions,
        child: Text('Dodatki…'),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: _MenuAction.startTimer,
        enabled: !_stopwatch.isRunning,
        child: const Text('Start licznika'),
      ),
      PopupMenuItem(
        value: _MenuAction.stopTimer,
        enabled: _stopwatch.isRunning,
        child: const Text('Stop licznika'),
      ),
      PopupMenuItem(
        value: _MenuAction.resetTimer,
        enabled: !_stopwatch.isRunning && _stopwatch.elapsed > Duration.zero,
        child: const Text('Reset licznika'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final showTimer =
        _stopwatch.isRunning || _stopwatch.elapsed > Duration.zero;
    final showGoods =
        _has(Expansion.tradersBuilders) && _players.any((p) => p.goodsTotal > 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CarcassonneCounter'),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: _onMenuSelected,
            itemBuilder: (_) => _buildMenuItems(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPlayer,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (showTimer)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                'Czas gry: ${_formatDuration(_stopwatch.elapsed)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          if (showGoods) GoodsLeaderboard(players: _players),
          Expanded(
            child: _players.isEmpty
                ? const Center(
                    child: Text(
                      'Brak graczy — dodaj nowego!',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: _players.length,
                    itemBuilder: (context, index) =>
                        _buildPlayerCard(_players[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Player p) {
    final bonus = goodsBonus(p, _players);
    final hasGoods = _has(Expansion.tradersBuilders) && p.goodsTotal > 0;

    return Card(
      color: kBrandColor.withValues(alpha: 180 / 255),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        onTap: () => _onScorePlayer(p),
        onLongPress: () => _onEditPlayer(p),
        leading: MeepleIcon(color: p.color, size: 50),
        title: Text(
          p.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: hasGoods
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: GoodsBadges(player: p, players: _players),
              )
            : null,
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${p.points + bonus}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (bonus > 0)
              Text(
                '${p.points} + $bonus',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
