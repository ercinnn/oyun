import 'package:three_js/three_js.dart' as three;

import '../models/town/shop_catalog.dart';

/// Blender'da modellenmiş oda mobilyası (`assets/models/furniture.glb`,
/// üretici: `tool/blender/build_furniture.py`). Karakterdeki (`AvatarModel`)
/// desenin aynısı: **tek dosya bir kez yüklenir**, her parça mağaza kimliğiyle
/// adlandırılmış bir grup olarak içinde durur ve [tryBuild] yalnızca istenen
/// grubu kopyalar.
///
/// Model yoksa/bozuksa null döner; çağıran kod (`Room3DView`) eşyanın
/// katalogdaki rengiyle düz bir kutuya düşer — oda çalışmaya devam eder.
///
/// Parçanın yerel koordinatları: ayak izi x∈[0,width], z∈[0,depth], y yukarı ve
/// 0'dan başlar; **ön yüz +z'ye bakar** (binalarla aynı sözleşme).
class FurnitureModel {
  FurnitureModel._();

  static three.Object3D? _template;
  static bool _loading = false;

  /// Yüklenmeyi denedik mi (tekrar tekrar denememek için).
  static bool get loaded => _template != null;

  /// Modeli bir kez yükler (başarısızsa sessizce vazgeçer; oyun bozulmaz).
  static Future<void> preload() async {
    if (_template != null || _loading) return;
    _loading = true;
    try {
      final gltf = await three.GLTFLoader()
          .setPath('assets/models/')
          .fromAsset('furniture.glb');
      _template = gltf?.scene;
    } catch (_) {
      _template = null;
    } finally {
      _loading = false;
    }
  }

  /// [item] için model kopyası; model yüklenmediyse ya da bu parça dosyada
  /// yoksa null.
  static three.Object3D? tryBuild(ShopItem item) {
    // Blender aynı adlı nesneleri `.001` diye numaralar; grubu adın `.`'tan
    // önceki kısmıyla ara (bkz. `AvatarModel._findBase`).
    three.Object3D? group;
    _template?.traverse((o) {
      if (group == null && o.name.split('.').first == item.id) group = o;
    });
    final node = group?.clone(true);
    if (node == null) return null;
    node.traverse((o) {
      o.castShadow = true;
      o.receiveShadow = true;
    });
    // Grup sahnede kendi konumunu taşıyabilir; yerleştirmeyi çağıran yapar.
    node.position.setValues(0, 0, 0);
    node.rotation.set(0, 0, 0);
    return node;
  }
}
