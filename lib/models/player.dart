import 'dart:ui';

class Player {
  String name;
  Color color;
  int points;

  Player({required this.name, required this.color, this.points = 0});

  Map<String, dynamic> toJson() => {
    'name': name,
    'color': color.toARGB32(),
    'points': points,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    name: json['name'] as String,
    color: Color(json['color'] as int),
    points: (json['points'] as int?) ?? 0,
  );
}
