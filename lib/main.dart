import 'package:flutter/material.dart';

import 'screens/players_screen.dart';
import 'theme/app_colors.dart';

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
      theme: ThemeData(colorSchemeSeed: kBrandColor, useMaterial3: true),
      home: const PlayersScreen(),
    );
  }
}
