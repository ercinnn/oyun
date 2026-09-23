// Geliştirme girişi: giriş (Google) kapısını atlayıp doğrudan 3D kasabayı açar.
//   flutter run -d chrome -t lib/dev/town_3d_probe.dart
//
// Karakteri denemek için URL'ye `?look=` eklenir (ör. `?look=fancy`); sonuncusu
// mağazadaki tüm parçaları giyer. Uygulamanın parçası değildir.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/town_controller.dart';
import '../games/town_game.dart';
import '../models/town/avatar_spec.dart';
import '../services/town_sounds.dart';

const _looks = <String, AvatarSpec>{
  'fancy': AvatarSpec(
    skin: 3,
    hairStyle: 'hair_long',
    hairColor: 3,
    outfit: 'outfit_space',
    outfitColor: 2,
    hat: 'hat_crown',
    accessory: 'acc_wings',
  ),
  'dress': AvatarSpec(
    skin: 0,
    hairStyle: 'hair_bun',
    hairColor: 1,
    outfit: 'outfit_dress',
    outfitColor: 1,
    hat: 'hat_party',
    accessory: 'acc_necklace',
  ),
  'suit': AvatarSpec(
    skin: 4,
    hairStyle: 'hair_spiky',
    hairColor: 0,
    outfit: 'outfit_suit',
    outfitColor: 6,
    hat: 'hat_cowboy',
    accessory: 'acc_glasses',
  ),
  'hoodie': AvatarSpec(
    skin: 2,
    hairStyle: 'hair_curly',
    hairColor: 2,
    outfit: 'outfit_hoodie',
    outfitColor: 0,
    hat: 'hat_cap',
    accessory: 'acc_headphones',
  ),
};

void main() {
  final look = _looks[Uri.base.queryParameters['look']];
  runApp(
    MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) {
          final controller = TownController(sounds: createTownSounds())
            ..enterTown();
          if (look != null) controller.profile.avatar = look;
          return controller;
        },
        child: const TownRoot(),
      ),
    ),
  );
}
