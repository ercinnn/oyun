import 'package:three_js/three_js.dart' as three;

import '../models/town/shop_catalog.dart';
import 'glb_model_library.dart';

/// Blender'da modellenmiş oda mobilyası (`assets/models/furniture.glb`,
/// üretici: `tool/blender/build_furniture.py`). Karakterdeki (`AvatarModel`)
/// desenin aynısı: **tek dosya bir kez yüklenir**, her parça mağaza kimliğiyle
/// adlandırılmış bir grup olarak içinde durur ve [tryBuild] yalnızca istenen
/// grubu kopyalar (ortak yükleyici: [GlbModelLibrary]).
///
/// Model yoksa/bozuksa null döner; çağıran kod (`Room3DView`) eşyanın
/// katalogdaki rengiyle düz bir kutuya düşer — oda çalışmaya devam eder.
///
/// Parçanın yerel koordinatları: ayak izi x∈[0,width], z∈[0,depth], y yukarı ve
/// 0'dan başlar; **ön yüz +z'ye bakar** (binalarla aynı sözleşme).
class FurnitureModel {
  FurnitureModel._();

  static final _library = GlbModelLibrary('furniture.glb');

  static bool get loaded => _library.loaded;

  static Future<void> preload() => _library.preload();

  /// [item] için model kopyası; model yüklenmediyse ya da bu parça dosyada
  /// yoksa null.
  static three.Object3D? tryBuild(ShopItem item) => _library.tryBuild(item.id);
}
