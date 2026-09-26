import 'dart:math';
import 'dart:ui' show Offset, Size;

import 'package:three_js/three_js.dart' as three;

/// 3B sahnelerde dokunma/izdüşüm hesabı ve platform düzeltmeleri.
/// `Town3DView` (kasaba) ve `Room3DView` (oda) ortak kullanır — bu math iki
/// yerde kopyalanmamalı.

/// Kamera tabanı: konum + ileri/sağ/yukarı birim vektörleri. Sahne kamerasının
/// `lookAt` hedefiyle kurulur, böylece izdüşüm sahnenin gördüğüyle aynıdır.
class ThreeSceneBasis {
  const ThreeSceneBasis({
    required this.pos,
    required this.fwd,
    required this.right,
    required this.up,
    required this.fovDeg,
  });

  final List<double> pos;
  final List<double> fwd;
  final List<double> right;
  final List<double> up;
  final double fovDeg;

  /// Kameranın konumundan [look] noktasına bakan taban; kamera hedefin
  /// üstündeyse (ileri vektörü sıfır) null.
  static ThreeSceneBasis? of(
    three.Camera camera,
    three.Vector3 look, {
    required double fovDeg,
  }) {
    final px = camera.position.x, py = camera.position.y, pz = camera.position.z;
    var fx = look.x - px, fy = look.y - py, fz = look.z - pz;
    final fl = sqrt(fx * fx + fy * fy + fz * fz);
    if (fl == 0) return null;
    fx /= fl;
    fy /= fl;
    fz /= fl;
    // sağ = ileri × (0,1,0)
    var rx = -fz;
    var rz = fx;
    final rl = sqrt(rx * rx + rz * rz);
    if (rl == 0) return null;
    rx /= rl;
    rz /= rl;
    // yukarı = sağ × ileri (ry = 0)
    final ux = -rz * fy;
    final uy = rz * fx - rx * fz;
    final uz = rx * fy;
    return ThreeSceneBasis(
      pos: [px, py, pz],
      fwd: [fx, fy, fz],
      right: [rx, 0, rz],
      up: [ux, uy, uz],
      fovDeg: fovDeg,
    );
  }

  double dot(List<double> a, List<double> b) =>
      a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

  /// Dünya noktasının ekran konumu (piksel); kameranın arkasındaysa null.
  Offset? project(double x, double y, double z, Size size) {
    final v = [x - pos[0], y - pos[1], z - pos[2]];
    final depth = dot(v, fwd);
    if (depth <= 0) return null;
    final tanH = tan(fovDeg * pi / 360);
    final aspect = size.width / size.height;
    final nx = dot(v, right) / (depth * tanH * aspect);
    final ny = dot(v, up) / (depth * tanH);
    return Offset((nx + 1) / 2 * size.width, (1 - ny) / 2 * size.height);
  }

  /// Ekrandaki [local] noktasından geçen ışının yönü (normalize edilmemiş).
  List<double> rayThrough(Offset local, Size size) {
    final tanH = tan(fovDeg * pi / 360);
    final k = (local.dx / size.width * 2 - 1) * tanH * (size.width / size.height);
    final m = (1 - local.dy / size.height * 2) * tanH;
    return [for (var i = 0; i < 3; i++) fwd[i] + right[i] * k + up[i] * m];
  }

  /// Işının y = [planeY] düzlemine isabet ettiği nokta (x, z); ışın düzleme
  /// paralel ya da arkada kalıyorsa null.
  (double, double)? hitPlane(List<double> dir, {double planeY = 0}) {
    if (dir[1].abs() < 1e-9) return null;
    final t = (planeY - pos[1]) / dir[1];
    if (t <= 0) return null;
    return (pos[0] + dir[0] * t, pos[2] + dir[2] * t);
  }

  /// Eksen hizalı kutuyla kesişim (slab yöntemi): ışının kutuya girdiği `t`
  /// ya da kesişmiyorsa null. [lo]/[hi] kutunun köşeleri (x, y, z).
  double? intersectBox(List<double> dir, List<double> lo, List<double> hi) {
    var tMin = 0.0;
    var tMax = double.infinity;
    for (var a = 0; a < 3; a++) {
      final o = pos[a];
      if (dir[a].abs() < 1e-9) {
        if (o < lo[a] || o > hi[a]) return null;
        continue;
      }
      var t1 = (lo[a] - o) / dir[a];
      var t2 = (hi[a] - o) / dir[a];
      if (t1 > t2) {
        final tmp = t1;
        t1 = t2;
        t2 = tmp;
      }
      tMin = max(tMin, t1);
      tMax = min(tMax, t2);
    }
    return tMin <= tMax ? tMin : null;
  }
}

/// Android'de (flutter_angle) aynı GL programını paylaşan malzemeler arasında
/// renk sızıyor: bir parça, kendinden hemen önce çizilen parçanın rengini
/// alıyor (çatı meyvenin yeşiline, duvar başka binanın rengine dönüyor) ve
/// çizim sırası kamerayla değiştiği için renkler dönerken/yakınlaşırken
/// oynuyor. Web'de aynı renderer kodu sorunsuz. Bu yüzden her farklı görünüme
/// (renk + malzeme değerleri) kendi programını veriyoruz: GL uniform değerleri
/// program başına saklandığından bir program yalnızca tek bir rengi taşır ve
/// başka parçanın rengi ona geçemez. Aynı değerli malzemeler aynı programı
/// paylaşır; program sayısı farklı görünüm sayısı kadardır (~100).
///
/// **Kaldırma.** Sahneye sonradan malzeme eklersen (oda yeniden kurulurken
/// olduğu gibi) onu da bu fonksiyondan geçir.
void isolateMaterialPrograms(three.Object3D root) {
  root.traverse((o) {
    final m = o is three.Mesh ? o.material : null;
    if (m != null) isolateMaterialProgram(m);
  });
}

/// Tek bir malzemeye kendi programını verir (bkz. [isolateMaterialPrograms]).
/// Sahneye sonradan, ilk kez oluşturulan malzemeler için de çağrılmalıdır;
/// Bilim İnsanları görünümlerinin ortak `material()` yardımcısı bunu her yeni
/// malzemede kendisi yapar.
void isolateMaterialProgram(three.Material m) {
  final key = StringBuffer(m.runtimeType)
    ..write(m.color.getHex())
    ..write('/${m.opacity}/${m.transparent}');
  if (m is three.MeshStandardMaterial) {
    key.write('/${m.roughness}/${m.metalness}');
    key.write('/${m.emissive?.getHex()}/${m.emissiveIntensity}');
  }
  final k = key.toString();
  m.customProgramCacheKey = () => k;
}
