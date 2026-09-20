// Geliştirme girişi: giriş (Google) kapısını atlayıp doğrudan 3D kasabayı açar.
//   flutter run -d chrome -t lib/dev/town_3d_probe.dart
// Uygulamanın parçası değildir.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/town_controller.dart';
import '../games/town_game.dart';

void main() {
  runApp(
    MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => TownController()..enterTown(),
        child: const TownRoot(),
      ),
    ),
  );
}
