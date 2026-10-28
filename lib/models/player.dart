import 'dart:ui';

import 'goods.dart';

class Player {
  static int _seq = 0;

  /// Nowy, niewidoczny dla użytkownika identyfikator gracza. Nie zależy od
  /// imienia ani koloru, więc te można zmieniać w trakcie gry, a dwóch
  /// graczy może mieć to samo imię.
  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_seq++}';

  /// Stały identyfikator gracza (do historii i podsumowań).
  final String id;

  String name;
  Color color;

  /// Punkty zdobyte na planszy (bez premii za surowce).
  int points;

  /// Zebrane surowce z dodatku „Kupcy i budowniczowie".
  final Map<Goods, int> goods;

  /// Sztabki złota z minidodatku „Kopalnie złota".
  int gold;

  Player({
    String? id,
    required this.name,
    required this.color,
    this.points = 0,
    Map<Goods, int>? goods,
    this.gold = 0,
  }) : id = id ?? newId(),
       goods = {for (final g in Goods.values) g: goods?[g] ?? 0};

  int goodsOf(Goods g) => goods[g] ?? 0;

  int get goodsTotal => goods.values.fold(0, (a, b) => a + b);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.toARGB32(),
    'points': points,
    'goods': {for (final e in goods.entries) e.key.name: e.value},
    'gold': gold,
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    final rawGoods = json['goods'];
    return Player(
      // Starsze zapisy nie mają id – dostają nowe przy wczytaniu.
      id: json['id'] as String?,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      points: (json['points'] as int?) ?? 0,
      gold: (json['gold'] as int?) ?? 0,
      goods: {
        if (rawGoods is Map)
          for (final g in Goods.values) g: (rawGoods[g.name] as int?) ?? 0,
      },
    );
  }
}
