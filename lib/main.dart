import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:convert';

void main() {
  runApp(const CarcassonneCounterApp());
}

class CarcassonneCounterApp extends StatelessWidget {
  const CarcassonneCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarcassonneCounter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Color.fromARGB(100, 189, 171, 251),
        useMaterial3: true,
      ),
      home: const PlayersScreen(),
    );
  }
}

class Player {
  String name;
  Color color;
  int points;

  Player({required this.name, required this.color, this.points = 0});

  Map<String, dynamic> toJson() => {
    'name': name,
    'color': color.value,
    'points': points,
  };

  static Player fromJson(Map<String, dynamic> json) => Player(
    name: json['name'],
    color: Color(json['color']),
    points: json['points'],
  );
}

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  List<Player> players = [];
  final List<Color> baseColors = [
    Color.fromARGB(255, 29, 39, 234),
    Color.fromARGB(255, 7, 142, 4),
    Color.fromARGB(255, 204, 27, 27),
    Color.fromARGB(255, 7, 7, 7),
    Color.fromARGB(255, 255, 255, 255),
    Color.fromARGB(255, 240, 248, 17),
    Color.fromARGB(255, 250, 134, 18),
    Color.fromARGB(255, 140, 26, 255),
    Color.fromARGB(255, 255, 66, 255),
    Color.fromARGB(255, 126, 119, 119),
  ];

  List<Color> availableColors = [];

  Timer? _gameTimer;
  Duration _elapsed = Duration.zero;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    availableColors = List.from(baseColors);
    loadPlayers();
  }

  Future<void> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('players');
    if (jsonString != null) {
      final decoded = json.decode(jsonString) as List;
      setState(() {
        players = decoded.map((e) => Player.fromJson(e)).toList();
        for (var p in players) {
          availableColors.remove(p.color);
        }
      });
    }
  }

  Future<void> savePlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(players.map((e) => e.toJson()).toList());
    await prefs.setString('players', encoded);
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _isTimerRunning = true;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _gameTimer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  void _resetTimer() {
    _gameTimer?.cancel();
    setState(() {
      _elapsed = Duration.zero;
      _isTimerRunning = false;
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return "$h:$m:$s";
  }

  void addPlayer(Player p) {
    setState(() {
      players.add(p);
      players.sort((a, b) => b.points.compareTo(a.points));
      if (baseColors.contains(p.color)) availableColors.remove(p.color);
    });
    savePlayers();
  }

  void removePlayer(Player p) {
    setState(() {
      players.remove(p);
      if (baseColors.contains(p.color)) {
        availableColors.add(p.color);
      }
    });
    savePlayers();
  }

  void editPlayer(Player oldPlayer, Player newPlayer) {
    setState(() {
      final index = players.indexOf(oldPlayer);
      if (index != -1) {
        players[index] = newPlayer;
      }
      players.sort((a, b) => b.points.compareTo(a.points));
      if (baseColors.contains(oldPlayer.color)) {
        availableColors.add(oldPlayer.color);
      }
      if (baseColors.contains(newPlayer.color)) {
        availableColors.remove(newPlayer.color);
      }
    });
    savePlayers();
  }

  void resetScores() {
    setState(() {
      for (var p in players) {
        p.points = 0;
      }
    });
    savePlayers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CarcassonneCounter"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') resetScores();
              if (value == 'start_timer') _startTimer();
              if (value == 'stop_timer') _stopTimer();
              if (value == 'reset_timer') _resetTimer();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Text('Resetuj punkty'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'start_timer',
                enabled: !_isTimerRunning,
                child: const Text('Start licznika'),
              ),
              PopupMenuItem(
                value: 'stop_timer',
                enabled: _isTimerRunning,
                child: const Text('Stop licznika'),
              ),
              PopupMenuItem(
                value: 'reset_timer',
                enabled: _elapsed != Duration.zero && _isTimerRunning == false,
                child: Text('Reset licznika'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlayerDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_elapsed > Duration.zero || _isTimerRunning)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                "Czas gry: ${_formatDuration(_elapsed)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          Expanded(
            child: players.isEmpty
                ? const Center(
                    child: Text(
                      "Brak graczy — dodaj nowego!",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final p = players[index];
                      return GestureDetector(
                        onTap: () => _openScoringSelection(p),
                        onLongPress: () => _showEditPlayerDialog(context, p),
                        child: Card(
                          color: Color.fromARGB(180, 189, 171, 251),
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          child: ListTile(
                            leading: MeepleIcon(color: p.color, size: 50),
                            title: Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            trailing: Text(
                              "${p.points}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPlayerDialog(BuildContext context) async {
    String name = "";
    Color selectedColor = availableColors.isNotEmpty
        ? availableColors.first
        : Colors.grey;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Dodaj gracza"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: "Imię"),
                    onChanged: (v) => name = v,
                  ),
                  const SizedBox(height: 10),
                  const Text("Wybierz kolor:"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var c in availableColors)
                        GestureDetector(
                          onTap: () => setState(() => selectedColor = c),
                          child: Container(
                            width: 30,
                            height: 30,
                            margin: EdgeInsets.all(2),
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: c,
                              border: Border.all(
                                color: selectedColor == c
                                    ? Colors.black
                                    : Colors.grey,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () async {
                          Color tempColor = selectedColor;
                          await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Wybierz kolor z palety"),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: tempColor,
                                  onColorChanged: (c) => tempColor = c,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Anuluj"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => selectedColor = tempColor);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: EdgeInsets.all(2),
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: selectedColor,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.palette, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    color: Color.fromARGB(255, 189, 171, 251),
                    child: MeepleIcon(color: selectedColor, size: 60),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Anuluj"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (name.isNotEmpty) {
                      addPlayer(Player(name: name, color: selectedColor));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Dodaj"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditPlayerDialog(
    BuildContext context,
    Player player,
  ) async {
    String name = player.name;
    Color selectedColor = player.color;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edytuj gracza"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: TextEditingController(text: name),
                    decoration: const InputDecoration(labelText: "Imię"),
                    onChanged: (v) => name = v,
                  ),
                  const SizedBox(height: 10),
                  const Text("Zmień kolor:"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var c in baseColors)
                        if (c == player.color || availableColors.contains(c))
                          GestureDetector(
                            onTap: () => setState(() => selectedColor = c),
                            child: Container(
                              margin: EdgeInsets.all(2),
                              padding: EdgeInsets.all(2),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: c,
                                border: Border.all(
                                  color: selectedColor == c
                                      ? Colors.black
                                      : Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    color: Color.fromARGB(255, 189, 171, 251),
                    child: MeepleIcon(color: selectedColor, size: 60),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    removePlayer(player);
                    Navigator.pop(context);
                  },
                  child: const Text("Usuń gracza"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newPlayer = Player(
                      name: name,
                      color: selectedColor,
                      points: player.points,
                    );
                    editPlayer(player, newPlayer);
                    Navigator.pop(context);
                  },
                  child: const Text("Zapisz"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openScoringSelection(Player p) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectPointsTypeScreen(
          player: p,
          onSelect: (type) async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPointsScreen(
                  player: p,
                  type: type,
                  onConfirm: (points) {
                    setState(() {
                      p.points += points;
                      players.sort((a, b) => b.points.compareTo(a.points));
                    });
                    savePlayers();
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

class MeepleIcon extends StatelessWidget {
  final Color color;
  final double size;

  const MeepleIcon({super.key, required this.color, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/meeple.svg',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ],
    );
  }
}

class SelectPointsTypeScreen extends StatelessWidget {
  final Player player;
  final Function(ScoringType type) onSelect;

  const SelectPointsTypeScreen({
    super.key,
    required this.player,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final color = player.color;
    final scoringTypes = ScoringType.all;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dodaj punkty: ${player.name}",
          style: TextStyle(
            color: player.color == Color.fromARGB(255, 255, 255, 255)
                ? Colors.black
                : Colors.white,
          ),
        ),
        backgroundColor: player.color,
      ),
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: color, width: 4)),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              "Wybierz rodzaj punktacji:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: scoringTypes.map((type) {
                  return _buildTypeButton(
                    context,
                    type.displayName,
                    type.iconPath,
                    type,
                  );
                }).toList(),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Anuluj"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context,
    String label,
    String iconPath,
    ScoringType type,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onSelect(type);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black26, width: 2),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(iconPath, fit: BoxFit.cover),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoringType {
  final String id;
  final String displayName;
  final String iconPath;
  final Color accentColor;
  final bool hasFairyOption; // Czy można dodać +3 za wróżkę
  final bool useTwoInputs;

  const ScoringType({
    required this.id,
    required this.displayName,
    required this.iconPath,
    required this.accentColor,
    this.hasFairyOption = false,
    this.useTwoInputs = false,
  });

  static const List<ScoringType> all = [
    ScoringType(
      id: 'city',
      displayName: 'Miasto',
      iconPath: 'assets/images/city.jpg',
      accentColor: Colors.orange,
      hasFairyOption: true,
      useTwoInputs: true,
    ),
    ScoringType(
      id: 'road',
      displayName: 'Droga',
      iconPath: 'assets/images/road.jpg',
      accentColor: Colors.brown,
      hasFairyOption: true,
    ),
    ScoringType(
      id: 'cloister',
      displayName: 'Klasztor',
      iconPath: 'assets/images/cloister.jpg',
      accentColor: Colors.green,
      hasFairyOption: true,
    ),
    ScoringType(
      id: 'meadow',
      displayName: 'Pola',
      iconPath: 'assets/images/meadow.jpg',
      accentColor: Colors.teal,
      hasFairyOption: false,
    ),
    ScoringType(
      id: 'fairy',
      displayName: 'Wróżka',
      iconPath: 'assets/images/fairy.png',
      accentColor: Colors.purple,
      hasFairyOption: false,
    ),
    ScoringType(
      id: 'sheeps',
      displayName: "Owce",
      iconPath: 'assets/images/sheeps.jpg',
      accentColor: Colors.blue,
      hasFairyOption: true,
    ),
  ];

  static ScoringType byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}

class AddPointsScreen extends StatefulWidget {
  final Player player;
  final ScoringType type;
  final Function(int points) onConfirm;

  const AddPointsScreen({
    super.key,
    required this.player,
    required this.type,
    required this.onConfirm,
  });

  @override
  State<AddPointsScreen> createState() => _AddPointsScreenState();
}

class _AddPointsScreenState extends State<AddPointsScreen> {
  int tiles = 0;
  int banners = 0;
  bool isFinalCloister = false;
  String activeField = "tiles";

  bool hasCathedral = false; // Miasto
  bool hasInn = false; // Droga
  bool hasPig = false; // Pole
  bool hasWine = false; // Kupcy
  bool hasCloth = false; // Kupcy
  bool hasGrain = false; // Kupcy

  int get calculatedPoints {
    switch (widget.type.id) {
      case 'city':
        if (hasCathedral && tiles + banners < 1) return 0;
        int base = (tiles + banners) * (hasCathedral ? 3 : 2);
        return base;

      case 'road':
        if (hasInn && tiles < 1) return 0;
        return hasInn ? tiles * 2 : tiles;

      case 'meadow':
        return hasPig ? (tiles * 4) : (tiles * 3);

      case 'cloister':
        return isFinalCloister ? tiles : 9;

      default:
        return tiles;
    }
  }

  void _onKeyTap(dynamic key) {
    setState(() {
      if (key == "C") {
        if (activeField == "tiles") tiles = 0;
        if (activeField == "banners") banners = 0;
      } else if (key == "<") {
        if (activeField == "tiles") tiles = tiles ~/ 10;
        if (activeField == "banners") banners = banners ~/ 10;
      } else if (key is int) {
        if (activeField == "tiles") {
          tiles = (tiles * 10 + key).clamp(0, 999);
        } else {
          banners = (banners * 10 + key).clamp(0, 999);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.player.color;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.player.name} — ${widget.type.displayName}"),
        backgroundColor: color.withOpacity(0.2),
      ),
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: color, width: 4)),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              switch (widget.type.id) {
                'city' => _buildCityInputs(),
                'road' => _buildRoadInput(),
                'cloister' => _buildCloisterInput(),
                'meadow' => _buildMeadowInput(),
                _ => _buildInputs(widget.type),
              },
              const SizedBox(height: 20),
              Text(
                "Wynik: $calculatedPoints pkt",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildKeyboard(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onConfirm(calculatedPoints);
                  Navigator.pop(context);
                },
                child: const Text("Zatwierdź"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputs(ScoringType type) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: widget.player.color, width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              type.useTwoInputs
                  ? Row(
                      children: [
                        _buildValueBox("Płytki", tiles, "tiles"),
                        _buildValueBox("Sztandary", banners, "banners"),
                      ],
                    )
                  : _buildValueBox("Płytki", tiles, "tiles"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCityInputs() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: widget.player.color, width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildValueBox("Płytki", tiles, "tiles"),
              _buildValueBox("Sztandary", banners, "banners"),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: hasCathedral,
              onChanged: (v) => setState(() => hasCathedral = v ?? false),
            ),
            const Text("Katedra"),
          ],
        ),
      ],
    );
  }

  Widget _buildRoadInput() {
    return Column(
      children: [
        _buildValueBox("Płytki", tiles, "tiles"),
        CheckboxListTile(
          title: const Text("Karczma"),
          value: hasInn,
          onChanged: (v) => setState(() => hasInn = v ?? false),
        ),
      ],
    );
  }

  Widget _buildCloisterInput() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text("Punkty na koniec gry (niedokończony)"),
          value: isFinalCloister,
          onChanged: (v) => setState(() => isFinalCloister = v ?? false),
        ),
        if (isFinalCloister)
          _buildValueBox("Płytki", tiles, "tiles")
        else
          const Text(
            "Ukończony klasztor = 9 pkt",
            style: TextStyle(fontSize: 20),
          ),
      ],
    );
  }

  Widget _buildMeadowInput() {
    return Column(
      children: [
        _buildValueBox("Płytki", tiles, "tiles"),
        CheckboxListTile(
          title: const Text("Świnka"),
          value: hasPig,
          onChanged: (v) => setState(() => hasPig = v ?? false),
        ),
      ],
    );
  }

  Widget _buildValueBox(String label, int value, String fieldKey) {
    final isActive = activeField == fieldKey;
    return GestureDetector(
      onTap: () => setState(() => activeField = fieldKey),
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 8),
          Container(
            width: 100,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive ? Colors.blueAccent : Colors.grey,
                width: isActive ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text("$value", style: const TextStyle(fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    const keys = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
      ["C", 0, "<"],
    ];

    return Column(
      children: keys
          .map(
            (row) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: ElevatedButton(
                    onPressed: () => _onKeyTap(key),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: Text("$key"),
                  ),
                );
              }).toList(),
            ),
          )
          .toList(),
    );
  }
}
