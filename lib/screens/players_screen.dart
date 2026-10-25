import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/app_language.dart';
import '../l10n/l10n.dart';
import '../models/circus.dart';
import '../models/expansion.dart';
import '../models/fairy.dart';
import '../models/game_state.dart';
import '../models/history_entry.dart';
import '../models/player.dart';
import '../models/score_event.dart';
import '../models/scoring.dart';
import '../services/history_storage.dart';
import '../services/players_storage.dart';
import '../services/settings_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/game_dialogs.dart';
import '../widgets/goods_widgets.dart';
import '../widgets/meeple_icon.dart';
import '../widgets/player_dialog.dart';
import 'add_points_screen.dart';
import 'bazaar_screen.dart';
import 'circus_screen.dart';
import 'end_game_screen.dart';
import 'flock_screen.dart';
import 'history_screen.dart';
import 'pyramid_screen.dart';
import 'select_points_type_screen.dart';
import 'tower_screen.dart';
import 'settings_screen.dart';

enum _MenuAction { undo, history, reset, settings }

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _storage = PlayersStorage();
  final _settingsStorage = SettingsStorage();
  final _historyStorage = HistoryStorage();
  final List<Player> _players = [];
  GameSettings _settings = GameSettings();

  /// Historia zatwierdzonych punktów w tej sesji (do cofania).
  final List<ScoreEvent> _history = [];

  /// Trwała historia punktów (do przeglądania w ustawieniach). Cofnięcie
  /// zdarzenia usuwa też jego wpis.
  final List<HistoryEntry> _log = [];
  final Map<ScoreEvent, int> _logIds = {};

  /// Kolory podstawowe, które nie są jeszcze zajęte przez żadnego gracza.
  List<Color> get _availableColors => [
    for (final c in kPlayerColors)
      if (!_players.any((p) => p.color == c)) c,
  ];

  bool _has(Expansion e) => _settings.expansions.contains(e);

  GameStage _stage = GameStage.setup;

  bool get _inSetup => _stage == GameStage.setup;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    unawaited(WakelockPlus.disable().catchError((Object _) {}));
    super.dispose();
  }

  // ---------------------------------------------------------------- dane

  Future<void> _load() async {
    final loaded = await _storage.load();
    final settings = await _settingsStorage.load();
    final log = await _historyStorage.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      appThemeMode.value = settings.themeMode;
      appLanguage.value = settings.language;
      _log
        ..clear()
        ..addAll(log);
      _players
        ..clear()
        ..addAll(loaded);
      _stage = settings.stage ?? inferLegacyStage(loaded);
      _sortPlayers();
    });
    _applyWakelock();
    if (_stage == GameStage.finished) _showEndScreen();
  }

  /// Włącza lub wyłącza blokadę wygaszania ekranu zgodnie z ustawieniem.
  void _applyWakelock() {
    unawaited(
      WakelockPlus.toggle(
        enable: _settings.keepScreenOn,
      ).catchError((Object _) {}),
    );
  }

  void _save() => unawaited(_storage.save(_players));

  void _saveSettings() => unawaited(_settingsStorage.save(_settings));

  void _saveLog() => unawaited(_historyStorage.save(_log));

  /// Sortuje po punktach z planszy (premia za surowce dopiero na koniec).
  void _sortPlayers() {
    _players.sort((a, b) => b.points.compareTo(a.points));
  }

  void _setStage(GameStage stage) {
    _stage = stage;
    _settings.stage = stage;
    _saveSettings();
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
            child: Text(context.l10n.cancel),
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
    if (!_inSetup) return;
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
    if (!_inSetup) return;
    final result = await showPlayerDialog(
      context,
      availableColors: _availableColors,
      player: player,
    );
    if (result == null || !mounted) return;

    if (result.delete) {
      final confirmed = await _confirm(
        title: context.l10n.deletePlayerTitle,
        message: context.l10n.deletePlayerMessage(player.name),
        confirmLabel: context.l10n.delete,
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
    if (_stage != GameStage.playing) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.startFirst)));
      return;
    }
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

    if (type == ScoringType.fairy) {
      _scoreFairy(player);
      return;
    }

    final event = await Navigator.push<ScoreEvent>(
      context,
      MaterialPageRoute(builder: (_) => _scoringScreen(player, type)),
    );
    if (event == null || !mounted) return;

    _applyEvent(event);
  }

  /// Wróżka przy meplu gracza daje 1 pkt na początku jego tury, więc
  /// dopisujemy go od razu, bez osobnego ekranu. Można go cofnąć z paska.
  void _scoreFairy(Player player) {
    final l = context.l10n;
    final event = ScoreEvent(
      l.fairyEventLabel(player.name, kFairyTurnPoints),
      [ScoreChange(player, kFairyTurnPoints)],
      category: l.scFairy,
      type: ScoringType.fairy,
    );
    _applyEvent(event);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.fairySnack(player.name, kFairyTurnPoints)),
          action: SnackBarAction(
            label: l.undo,
            onPressed: () {
              // Cofamy tylko, jeśli to nadal ostatnie zdarzenie.
              if (_history.isNotEmpty && identical(_history.last, event)) {
                _undo();
              }
            },
          ),
        ),
      );
  }

  Widget _scoringScreen(Player player, ScoringType type) {
    final players = List<Player>.of(_players);
    return switch (type) {
      ScoringType.sheep => FlockScreen(player: player, players: players),
      ScoringType.bazaar => BazaarScreen(player: player, players: players),
      ScoringType.tower => TowerScreen(player: player, players: players),
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      event.apply();
      _history.add(event);
      final entry = HistoryEntry.fromEvent(
        event,
        totals: {for (final p in _players) p: p.points},
      );
      _log.add(entry);
      _logIds[event] = entry.id;
      final animal = event.animal;
      if (animal != null) {
        _settings.usedAnimals[animal] =
            (_settings.usedAnimals[animal] ?? 0) + 1;
      }
      _sortPlayers();
    });
    _save();
    _saveSettings();
    _saveLog();
  }

  void _undo() {
    if (_history.isEmpty) return;
    final event = _history.removeLast();
    setState(() {
      event.revert();
      final logId = _logIds.remove(event);
      if (logId != null) _log.removeWhere((e) => e.id == logId);
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
    _saveLog();
  }

  Future<void> _onReset() async {
    final confirmed = await _confirm(
      title: context.l10n.newGameTitle,
      message: context.l10n.newGameMessage,
      confirmLabel: context.l10n.reset,
    );
    if (!confirmed || !mounted) return;
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      for (final p in _players) {
        p.points = 0;
        p.gold = 0;
        p.goods.updateAll((goods, count) => 0);
      }
      _history.clear();
      _logIds.clear();
      _log.clear();
      _settings.usedAnimals.clear();
      _settings.startedAt = null;
      _settings.endedAt = null;
      _stage = GameStage.setup;
      _settings.stage = GameStage.setup;
    });
    _save();
    _saveSettings();
    _saveLog();
  }

  Future<void> _openHistory() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          entries: List<HistoryEntry>.of(_log),
          onClear: () {
            setState(() => _log.clear());
            _saveLog();
          },
        ),
      ),
    );
  }

  Future<void> _onStartGame() async {
    final l = context.l10n;
    final names = [
      for (final e in Expansion.values)
        if (_has(e)) e.label(l),
    ];
    final ok = await askYesNo(
      context,
      title: l.startGameQuestion,
      message: l.startGameBody(names.isEmpty ? l.noneCap : names.join(', ')),
    );
    if (!ok || !mounted) return;
    setState(() {
      _settings.startedAt = DateTime.now();
      _settings.endedAt = null;
      _setStage(GameStage.playing);
    });
    await showGameStartedNote(context);
  }

  Future<void> _onEndGame() async {
    final ok = await askYesNo(context, title: context.l10n.endGameQuestion);
    if (!ok || !mounted) return;
    setState(() {
      _settings.endedAt = DateTime.now();
      _setStage(GameStage.finished);
    });
    await _showEndScreen();
  }

  /// Podsumowanie gry; jedyne wyjście to „Nowa gra".
  Future<void> _showEndScreen() async {
    final newGame = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EndGameScreen(
          players: List<Player>.of(_players),
          log: List<HistoryEntry>.of(_log),
          showGoods: _has(Expansion.tradersBuilders),
          showGold: _has(Expansion.goldMines),
          elapsed: gameElapsed(
            startedAt: _settings.startedAt,
            endedAt: _settings.endedAt,
          ),
        ),
      ),
    );
    if (newGame == true && mounted) _resetGame();
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          expansions: _settings.expansions,
          keepScreenOn: _settings.keepScreenOn,
          themeMode: _settings.themeMode,
          language: _settings.language,
          expansionsLocked: !_inSetup,
          onChanged: (values) {
            setState(() {
              _settings.expansions
                ..clear()
                ..addAll(values.expansions);
              _settings.keepScreenOn = values.keepScreenOn;
              _settings.themeMode = values.themeMode;
              _settings.language = values.language;
            });
            appThemeMode.value = values.themeMode;
            appLanguage.value = values.language;
            _applyWakelock();
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
      case _MenuAction.history:
        _openHistory();
      case _MenuAction.reset:
        _onReset();
      case _MenuAction.settings:
        _openSettings();
    }
  }

  // ------------------------------------------------------------- widoki

  List<PopupMenuEntry<_MenuAction>> _buildMenuItems() {
    final l = context.l10n;
    final last = _history.isEmpty ? null : _history.last;
    return [
      PopupMenuItem(
        value: _MenuAction.undo,
        enabled: last != null,
        child: Text(
          last == null ? l.menuUndoNone : l.menuUndo(last.label),
        ),
      ),
      PopupMenuItem(
        value: _MenuAction.history,
        child: Text(l.menuHistory),
      ),
      PopupMenuItem(
        value: _MenuAction.reset,
        child: Text(l.menuReset),
      ),
      PopupMenuItem(
        value: _MenuAction.settings,
        child: Text(l.menuSettings),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final showStart = _inSetup && _players.isNotEmpty;

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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showStart)
                FloatingActionButton.extended(
                  heroTag: 'start',
                  onPressed: _onStartGame,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l.startGame),
                )
              else
                const SizedBox.shrink(),
              if (_inSetup)
                FloatingActionButton(
                  heroTag: 'add',
                  onPressed: _onAddPlayer,
                  child: const Icon(Icons.add),
                )
              else if (_stage == GameStage.playing)
                FloatingActionButton(
                  heroTag: 'end',
                  tooltip: l.endGameTooltip,
                  onPressed: _onEndGame,
                  child: const Icon(kEndGameIcon),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
      body: _players.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.noPlayersHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: _players.length,
              itemBuilder: (context, index) =>
                  _buildPlayerCard(_players[index]),
            ),
    );
  }

  Widget _buildPlayerCard(Player p) {
    final total = p.points;
    final hasGoods = _has(Expansion.tradersBuilders) && p.goodsTotal > 0;
    final hasGold = _has(Expansion.goldMines) && p.gold > 0;

    return Card(
      color: playerCardColor(context),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        onTap: () => _onScorePlayer(p),
        onLongPress: () => _onEditPlayer(p),
        leading: MeepleIcon(color: p.color, size: 50),
        title: Text(
          p.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: hasGoods || hasGold
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (hasGoods) GoodsBadges(player: p, players: _players),
                    if (hasGold) GoldBadge(count: p.gold),
                  ],
                ),
              )
            : null,
        trailing: Text(
          '$total',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
