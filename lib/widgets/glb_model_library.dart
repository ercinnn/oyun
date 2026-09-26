import 'package:three_js/three_js.dart' as three;

/// Blender'da üretilmiş, **birden çok parçayı isimli kök gruplar olarak**
/// taşıyan tek bir GLB dosyası (mobilya: `furniture.glb`, Arşimet:
/// `archimedes.glb`). Dosya bir kez yüklenir; [tryBuild] yalnızca istenen
/// grubu kopyalar.
///
/// Model yoksa/bozuksa [tryBuild] null döner ve çağıran kod ilkel bir şekle
/// düşer — oyun bozulmaz.
class GlbModelLibrary {
  GlbModelLibrary(this.fileName);

  /// `assets/models/` altındaki dosya adı.
  final String fileName;

  three.Object3D? _template;
  bool _loading = false;

  bool get loaded => _template != null;

  /// Dosyayı bir kez yükler; başarısızsa sessizce vazgeçer (bir sonraki
  /// çağrı yeniden dener).
  Future<void> preload() async {
    if (_template != null || _loading) return;
    _loading = true;
    try {
      final gltf = await three.GLTFLoader()
          .setPath('assets/models/')
          .fromAsset(fileName);
      _template = gltf?.scene;
    } catch (_) {
      _template = null;
    } finally {
      _loading = false;
    }
  }

  /// [id] adlı grubun kopyası (konumu/dönüşü sıfırlanmış, gölge açık); yoksa
  /// null. Blender aynı adlı nesneleri `.001` diye numaraladığı için ad,
  /// `.`'tan önceki kısmıyla eşlenir (bkz. `AvatarModel._findBase`).
  three.Object3D? tryBuild(String id) {
    final group = find(_template, id);
    final node = group?.clone(true);
    if (node == null) return null;
    node.traverse((o) {
      o.castShadow = true;
      o.receiveShadow = true;
    });
    node.position.setValues(0, 0, 0);
    node.rotation.set(0, 0, 0);
    return node;
  }

  /// [root] altında adı [name] olan ilk düğüm (`.001` sonekleri yok sayılır).
  static three.Object3D? find(three.Object3D? root, String name) {
    three.Object3D? found;
    root?.traverse((o) {
      if (found == null && o.name.split('.').first == name) found = o;
    });
    return found;
  }
}
