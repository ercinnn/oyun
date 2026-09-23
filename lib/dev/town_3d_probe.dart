// Geliştirme girişi: giriş (Google) kapısını atlayıp doğrudan 3D kasabayı açar.
//   flutter run -d chrome -t lib/dev/town_3d_probe.dart
//
// Karakteri denemek için URL'ye `?look=` eklenir (ör. `?look=fancy`); sonuncusu
// mağazadaki tüm parçaları giyer. `?go=room|market|wardrobe|arcade` doğrudan o
// ekranı açar (oda/mobilya denemesi için kasabada yürümek gerekmesin);
// `&furnished=1` odaya her mobilyadan bir örnek yerleştirir.
// Uygulamanın parçası değildir.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/town_controller.dart';
import '../games/town_game.dart';
import '../models/town/avatar_spec.dart';
import '../models/town/shop_catalog.dart';
import '../models/town/town_phase.dart';
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

const _phases = <String, TownPhase>{
  'room': TownPhase.home,
  'market': TownPhase.market,
  'wardrobe': TownPhase.wardrobe,
  'arcade': TownPhase.arcade,
};

void main() {
  final look = _looks[Uri.base.queryParameters['look']];
  final go = _phases[Uri.base.queryParameters['go']];
  final furnished = Uri.base.queryParameters['furnished'] != null;
  runApp(
    MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) {
          final controller = TownController(sounds: createTownSounds())
            ..enterTown();
          if (look != null) controller.profile.avatar = look;
          if (furnished) _furnish(controller);
          if (go != null) controller.debugJumpToPhase(go);
          return controller;
        },
        child: const TownRoot(),
      ),
    ),
  );
}

/// Her mobilyadan bir örnek alıp odaya serper (yalnızca geliştirme: 3B odayı
/// tek bakışta denemek için). Konumlar sabittir; çakışırsa `placeItem` zaten
/// yerleştirmeyi reddeder.
void _furnish(TownController controller) {
  controller.profile.coins = 9999;
  const spots = <String, (int, int, int)>{
    'furn_rug': (2, 3, 0),
    'furn_bed': (0, 0, 0),
    'furn_sofa': (5, 6, 0),
    'furn_table': (2, 6, 0),
    'furn_books': (0, 4, 0),
    'furn_tv': (4, 0, 0),
    'furn_lamp': (3, 0, 0),
    'furn_plant': (7, 0, 0),
    'furn_aquarium': (7, 5, 0),
  };
  spots.forEach((id, at) {
    final item = shopItemById(id);
    if (item == null) return;
    if (controller.profile.availableCount(id) <= 0) {
      controller.buyFurniture(item);
    }
    controller.placeItem(item, at.$1, at.$2, rotation: at.$3);
  });
}
