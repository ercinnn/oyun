import 'dart:math';

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../models/town/avatar_spec.dart';
import '../models/town/town_map.dart';
import '../models/town/town_world.dart';
import 'avatar_3d.dart';
import 'world_input_layer.dart';

/// Kasabanın gerçek 3D görünümü (three_js). `IsoWorldView` ile aynı sözleşmeyi
/// taşır: her karede [onTick] çağrılır, sonra dünya durumu (`TownWorld`) sahneye
/// yansıtılır. **Oyun mantığı 2B kare koordinatlarında kalır**; kare `(x, y)`
/// 3B'de `(x, 0, y)` olur (kare merkezi `+0,5`).
///
/// Kamera izometrik görünümle **aynı yönden** bakar (avatarın `+x,+y` tarafında,
/// `-x,-y`'ye doğru): ekranda "sağ" = `x - y`. Bu yüzden `TownWorld.step`'in
/// ekran-uzayı girdi dönüşümü değişmeden doğru çalışır.
///
/// **Yalnızca web'de doğrulandı**; `TownWorldScreen.use3d` diğer platformlarda
/// (ve testlerde: VM'de WebGL yok) 2B görünüme düşer.
class Town3DView extends StatefulWidget {
  const Town3DView({
    super.key,
    required this.world,
    required this.avatar,
    required this.onTick,
    required this.onInput,
    this.onTapTile,
    this.overlay = const [],
  });

  final TownWorld world;
  final AvatarSpec avatar;

  /// Her karede ilerleyen süre (saniye), 0,1 s ile sınırlı.
  final ValueChanged<double> onTick;
  final ValueChanged<WorldInput> onInput;

  /// Dokun-yürü: dokunulan altın/bina/zemin karesi (`IsoWorldView` ile aynı sözleşme).
  final void Function(int x, int y)? onTapTile;

  /// Dünyanın üstüne konan öğeler (HUD, düğmeler).
  final List<Widget> overlay;

  @override
  State<Town3DView> createState() => _Town3DViewState();
}

class _Town3DViewState extends State<Town3DView> {
  late final three.ThreeJS _three;

  /// Kamera avatardan bu kadar uzakta (kare uzayında +x,+y yönünde; yükseklik ayrı).
  static const _camBack = 5.5;
  static const _camHeight = 8.5;

  three.Group? _avatar;
  Avatar3D? _playerRig;
  final List<Avatar3D> _npcRigs = [];
  three.DirectionalLight? _sun;
  double _heading = 0;
  double _lastX = 0;
  double _lastY = 0;

  /// Kameranın baktığı nokta (dokunma ışını için).
  three.Vector3 _look = three.Vector3(0, 0, 0);
  static const _fovDeg = 40.0;

  /// `world.coins[i]` <-> `_coinNodes[i]` (aynı sıra); NPC'ler için de öyle.
  final List<three.Object3D> _coinNodes = [];
  final List<three.Group> _npcNodes = [];
  final List<double> _npcHeading = [];
  final List<Offset> _npcLast = [];

  Offset? _downAt;
  Duration _downTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _lastX = widget.world.x;
    _lastY = widget.world.y;
    _three = three.ThreeJS(
      onSetupComplete: () => setState(() {}),
      setup: _setup,
    );
  }

  @override
  void dispose() {
    _three.dispose();
    three.loading.clear();
    super.dispose();
  }

  static int _tileColor(TileKind kind) => switch (kind) {
    TileKind.road => 0xB0BEC5,
    TileKind.sand => 0xFFE082,
    TileKind.water => 0x4FC3F7,
    TileKind.mud => 0x8D6E63,
    TileKind.door => 0xFFB74D,
    TileKind.goal => 0xFAFAFA,
    TileKind.start => 0xA5D6A7,
    TileKind.building => 0x9FA8DA,
    _ => 0x81C784, // çim (ağaç/çeşme/lamba altı da çim)
  };

  Future<void> _setup() async {
    final world = widget.world;
    final scene = three.Scene();
    scene.background = three.Color.fromHex32(0x87CEEB);
    _three.scene = scene;

    final camera = three.PerspectiveCamera(
      40,
      _three.width / _three.height,
      0.1,
      200,
    );
    _three.camera = camera;
    _placeCamera(camera, snap: true);

    scene.add(three.AmbientLight(0xffffff, 0.38));
    final sun = three.DirectionalLight(0xfff4e0, 0.9);
    sun.castShadow = true;
    sun.shadow?.mapSize.width = 1024;
    sun.shadow?.mapSize.height = 1024;
    final shadowCam = sun.shadow?.camera;
    if (shadowCam != null) {
      shadowCam.left = -14;
      shadowCam.right = 14;
      shadowCam.top = 14;
      shadowCam.bottom = -14;
      shadowCam.near = 1;
      shadowCam.far = 60;
    }
    scene.add(sun);
    scene.add(sun.target);
    _sun = sun;

    // Zemin: her kare bir kutu; renk kare türünden. Aynı renk aynı malzemeyi paylaşır.
    final materials = <int, three.MeshStandardMaterial>{};
    three.MeshStandardMaterial material(int color) => materials.putIfAbsent(
      color,
      () => three.MeshStandardMaterial.fromMap({'color': color}),
    );
    final tileGeometry = three.BoxGeometry(1, 0.2, 1);
    final map = world.map;
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        final kind = map.kindAt(x, y);
        final tile = three.Mesh(tileGeometry, material(_tileColor(kind)));
        tile.position.setValues(
          x + 0.5,
          kind == TileKind.water ? -0.16 : -0.1,
          y + 0.5,
        );
        tile.receiveShadow = true;
        scene.add(tile);
      }
    }

    _buildScenery(scene);
    await _loadBuildings(scene);
    scene.add(_buildAvatar());
    _buildActors(scene);

    _three.addAnimationEvent(_onFrame);
  }

  /// Binalar: Blender'da modellenip GLB olarak `assets/models/`'e konan modeller
  /// (üretici: `tool/blender/build_town_building.py`). Model köşesi orijinde,
  /// ön yüzü (kapı) +z'ye (kare +y, güney) bakar; bu yüzden binanın sol-üst
  /// karesine (`TownBuilding.x/y`) olduğu gibi konur. Boyutlar haritayla aynı
  /// olmalıdır (giyim/market/ev 4×3, oyun salonu 3×3). Yüklenemezse (dosya
  /// yok/bozuk) bina düz kare olarak kalır; oyun bozulmaz.
  static const _buildingModels = {
    DoorKind.wardrobe: 'wardrobe_shop.glb',
    DoorKind.market: 'market_shop.glb',
    DoorKind.home: 'home_house.glb',
    DoorKind.arcade: 'arcade_hall.glb',
  };

  Future<void> _loadBuildings(three.Scene scene) async {
    final loader = three.GLTFLoader().setPath('assets/models/');
    for (final b in widget.world.map.buildings) {
      final file = _buildingModels[b.kind];
      if (file == null) continue;
      try {
        final gltf = await loader.fromAsset(file);
        final model = gltf?.scene;
        if (model == null) continue;
        model.traverse((o) {
          o.castShadow = true;
          o.receiveShadow = true;
        });
        model.position.setValues(b.x.toDouble(), 0, b.y.toDouble());
        scene.add(model);
      } catch (_) {
        // Model yüklenemedi: oyunu bozma.
      }
    }
  }

  /// Ağaç, çeşme ve lamba (ilkel şekillerden). Aynı kare her zaman aynı görünür:
  /// ağaç boyu/rengi kare koordinatından türetilir, rastgelelik yok.
  void _buildScenery(three.Scene scene) {
    final map = widget.world.map;
    final trunkMat = three.MeshStandardMaterial.fromMap({'color': 0x6D4C41});
    final leafMats = [
      three.MeshStandardMaterial.fromMap({'color': 0x2E7D32}),
      three.MeshStandardMaterial.fromMap({'color': 0x388E3C}),
      three.MeshStandardMaterial.fromMap({'color': 0x1B8A4B}),
    ];
    final stoneMat = three.MeshStandardMaterial.fromMap({'color': 0xB0BEC5});
    final waterMat = three.MeshStandardMaterial.fromMap({'color': 0x29B6F6});
    final poleMat = three.MeshStandardMaterial.fromMap({'color': 0x37474F});
    final bulbMat = three.MeshBasicMaterial.fromMap({'color': 0xFFEE58});

    three.Mesh add(
      three.BufferGeometry g,
      three.Material m,
      double x,
      double y,
      double z,
    ) {
      final mesh = three.Mesh(g, m)
        ..position.setValues(x, y, z)
        ..castShadow = true
        ..receiveShadow = true;
      scene.add(mesh);
      return mesh;
    }

    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        final cx = x + 0.5, cz = y + 0.5;
        switch (map.kindAt(x, y)) {
          case TileKind.tree:
            final h = (x * 7 + y * 13) % 3; // 0..2: boy/renk çeşitliliği
            final scale = 0.9 + h * 0.15;
            add(
              three.CylinderGeometry(0.1, 0.14, 0.7 * scale, 8),
              trunkMat,
              cx,
              0.35 * scale,
              cz,
            );
            add(
              three.ConeGeometry(0.55 * scale, 0.95 * scale, 10),
              leafMats[h],
              cx,
              1.05 * scale,
              cz,
            );
            add(
              three.ConeGeometry(0.42 * scale, 0.8 * scale, 10),
              leafMats[(h + 1) % 3],
              cx,
              1.55 * scale,
              cz,
            );
          case TileKind.fountain:
            add(
              three.CylinderGeometry(0.46, 0.5, 0.28, 20),
              stoneMat,
              cx,
              0.14,
              cz,
            );
            add(
              three.CylinderGeometry(0.38, 0.38, 0.05, 20),
              waterMat,
              cx,
              0.29,
              cz,
            );
            add(
              three.CylinderGeometry(0.07, 0.09, 0.6, 10),
              stoneMat,
              cx,
              0.55,
              cz,
            );
            add(three.SphereGeometry(0.13, 12, 8), waterMat, cx, 0.9, cz);
          case TileKind.lamp:
            add(
              three.CylinderGeometry(0.035, 0.05, 1.25, 8),
              poleMat,
              cx,
              0.62,
              cz,
            );
            add(three.SphereGeometry(0.13, 12, 8), bulbMat, cx, 1.32, cz);
          default:
            break;
        }
      }
    }
  }

  /// Altın/yıldızlar ve gezen NPC'ler. Dünya durumu (`TownWorld`) tek kaynaktır:
  /// her karede konum/görünürlük ondan okunur, burada mantık yoktur.
  void _buildActors(three.Scene scene) {
    final world = widget.world;
    final coinMat = three.MeshStandardMaterial.fromMap({
      'color': 0xFFC107,
      'metalness': 0.3,
      'roughness': 0.35,
    });
    final starMat = three.MeshStandardMaterial.fromMap({
      'color': 0xFFEB3B,
      'metalness': 0.2,
      'roughness': 0.4,
    });
    final coinGeometry = three.CylinderGeometry(0.17, 0.17, 0.05, 16);
    final starGeometry = three.CylinderGeometry(0.24, 0.24, 0.07, 5);
    for (final coin in world.coins) {
      final holder = three.Group(); // dış grup y ekseninde döner
      final disc = three.Mesh(
        coin.isStar ? starGeometry : coinGeometry,
        coin.isStar ? starMat : coinMat,
      );
      disc.rotation.x = pi / 2; // madeni para ayakta dursun
      disc.castShadow = true;
      holder.add(disc);
      holder.position.setValues(coin.x, 0.55, coin.y);
      scene.add(holder);
      _coinNodes.add(holder);
    }
    for (final npc in world.npcs) {
      final node = _buildAvatar(npc.avatar);
      node.position.setValues(npc.x, 0, npc.y);
      scene.add(node);
      _npcNodes.add(node);
      _npcHeading.add(0);
      _npcLast.add(Offset(npc.x, npc.y));
    }
  }

  static double _turn(double from, double to, double amount) {
    var diff = to - from;
    while (diff > pi) {
      diff -= 2 * pi;
    }
    while (diff < -pi) {
      diff += 2 * pi;
    }
    return from + diff * amount;
  }

  void _updateActors(double dt) {
    final world = widget.world;
    for (var i = 0; i < _coinNodes.length && i < world.coins.length; i++) {
      final coin = world.coins[i];
      final node = _coinNodes[i];
      node.visible = coin.active;
      if (!coin.active) continue;
      node.position.y = 0.55 + sin(world.time * 4 + coin.x * 2 + coin.y) * 0.07;
      node.rotation.y = world.time * 3;
    }
    for (var i = 0; i < _npcNodes.length && i < world.npcs.length; i++) {
      final npc = world.npcs[i];
      final node = _npcNodes[i];
      node.position.setValues(
        npc.x,
        npc.moving ? sin(world.time * 12 + i).abs() * 0.06 : 0,
        npc.y,
      );
      final last = _npcLast[i];
      final mx = npc.x - last.dx, my = npc.y - last.dy;
      if (mx * mx + my * my > 1e-8) {
        _npcHeading[i] = _turn(
          _npcHeading[i],
          atan2(mx, my),
          min(1.0, dt * 12),
        );
      }
      node.rotation.y = _npcHeading[i];
      if (i < _npcRigs.length) {
        _npcRigs[i].update(world.time, npc.moving, phase: i * 1.7);
      }
      _npcLast[i] = Offset(npc.x, npc.y);
    }
  }

  /// Karakteri kurar ([Avatar3D]: `AvatarSpec`'teki saç/kıyafet/şapka/aksesuar
  /// dahil) ve animasyon için kaydeder. [forSpec] null ise oyuncudur.
  three.Group _buildAvatar([AvatarSpec? forSpec]) {
    final rig = Avatar3D.build(forSpec ?? widget.avatar);
    if (forSpec == null) {
      _playerRig = rig;
      _avatar = rig.root;
    } else {
      _npcRigs.add(rig);
    }
    return rig.root;
  }

  void _placeCamera(
    three.PerspectiveCamera camera, {
    bool snap = false,
    double dt = 0,
  }) {
    final world = widget.world;
    final target = three.Vector3(world.x, 0.6, world.y);
    final desired = three.Vector3(
      world.x + _camBack,
      _camHeight,
      world.y + _camBack,
    );
    if (snap) {
      camera.position.setFrom(desired);
    } else {
      final k = min(1.0, dt * 6);
      camera.position.x += (desired.x - camera.position.x) * k;
      camera.position.y += (desired.y - camera.position.y) * k;
      camera.position.z += (desired.z - camera.position.z) * k;
    }
    _look = target;
    camera.lookAt(target);
  }

  void _onFrame(double dt) {
    dt = min(0.1, dt);
    if (dt <= 0) return;
    widget.onTick(dt);

    final world = widget.world;
    final avatar = _avatar;
    if (avatar != null) {
      avatar.position.setValues(world.x, 0, world.y);
      // Yön: son karedeki hareketten; dururken son yön korunur.
      final mx = world.x - _lastX;
      final my = world.y - _lastY;
      if (mx * mx + my * my > 1e-8) {
        _heading = _turn(_heading, atan2(mx, my), min(1.0, dt * 14));
      }
      avatar.rotation.y = _heading;
      _playerRig?.update(world.time, world.moving);
      // Yürürken hafif zıplama.
      avatar.position.y = world.moving
          ? (sin(world.time * 14).abs() * 0.07)
          : 0;
    }
    _lastX = world.x;
    _lastY = world.y;

    _updateActors(dt);

    final sun = _sun;
    if (sun != null) {
      sun.position.setValues(world.x + 6, 12, world.y + 4);
      sun.target?.position.setValues(world.x, 0, world.y);
    }
    _placeCamera(_three.camera as three.PerspectiveCamera, dt: dt);
  }

  // ─────────────────────────── Dokun-yürü ───────────────────────────

  /// Kamera tabanı: konum + ileri/sağ/yukarı birim vektörleri. Sahne
  /// kamerasıyla aynı `lookAt` hedefini kullanır.
  _CameraBasis? _basis() {
    final cam = _three.camera;
    final px = cam.position.x, py = cam.position.y, pz = cam.position.z;
    var fx = _look.x - px, fy = _look.y - py, fz = _look.z - pz;
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
    // yukarı = sağ × ileri  (ry = 0)
    final ux = -rz * fy;
    final uy = rz * fx - rx * fz;
    final uz = rx * fy;
    return _CameraBasis(
      pos: [px, py, pz],
      fwd: [fx, fy, fz],
      right: [rx, 0, rz],
      up: [ux, uy, uz],
    );
  }

  /// Dünya noktasının ekran konumu (piksel); kameranın arkasındaysa null.
  Offset? _project(double x, double y, double z, Size size) {
    final b = _basis();
    if (b == null) return null;
    final v = [x - b.pos[0], y - b.pos[1], z - b.pos[2]];
    final depth = b.dot(v, b.fwd);
    if (depth <= 0) return null;
    final tanH = tan(_fovDeg * pi / 360);
    final aspect = size.width / size.height;
    final nx = b.dot(v, b.right) / (depth * tanH * aspect);
    final ny = b.dot(v, b.up) / (depth * tanH);
    return Offset((nx + 1) / 2 * size.width, (1 - ny) / 2 * size.height);
  }

  /// Dokunulan noktanın **yürünecek karesi**. Sırayla: altın/yıldız (havada
  /// süzüldükleri için ekrandaki yerine bakılır), bina gövdesi/çatısı (kapısına
  /// yürütür), yoksa yere isabet eden kare. Hiçbiri yoksa null.
  (int, int)? _tapTarget(Offset local, Size size) {
    final b = _basis();
    if (b == null || size.isEmpty) return null;
    final world = widget.world;

    var best = 34.0;
    (int, int)? coinTile;
    for (final coin in world.coins) {
      if (!coin.active) continue;
      final at = _project(coin.x, 0.55, coin.y, size);
      if (at == null) continue;
      final d = (at - local).distance;
      if (d < best) {
        best = d;
        coinTile = (coin.x.floor(), coin.y.floor());
      }
    }
    if (coinTile != null) return coinTile;

    // Dokunma ışını.
    final tanH = tan(_fovDeg * pi / 360);
    final k =
        (local.dx / size.width * 2 - 1) * tanH * (size.width / size.height);
    final m = (1 - local.dy / size.height * 2) * tanH;
    final d = [
      for (var i = 0; i < 3; i++) b.fwd[i] + b.right[i] * k + b.up[i] * m,
    ];

    // Bina kutusuyla kesişim (slab yöntemi); en yakın isabet kazanır.
    double? bestT;
    TownBuilding? hit;
    for (final building in world.map.buildings) {
      const height = 3.0; // duvar 2,0 + çatı 0,95 (modeller)
      final lo = [building.x.toDouble(), 0.0, building.y.toDouble()];
      final hi = [
        (building.x + building.w).toDouble(),
        height,
        (building.y + building.h).toDouble(),
      ];
      var tMin = 0.0;
      var tMax = double.infinity;
      var ok = true;
      for (var a = 0; a < 3; a++) {
        final o = b.pos[a];
        if (d[a].abs() < 1e-9) {
          if (o < lo[a] || o > hi[a]) ok = false;
        } else {
          var t1 = (lo[a] - o) / d[a];
          var t2 = (hi[a] - o) / d[a];
          if (t1 > t2) {
            final tmp = t1;
            t1 = t2;
            t2 = tmp;
          }
          tMin = max(tMin, t1);
          tMax = min(tMax, t2);
        }
      }
      if (ok && tMin <= tMax && (bestT == null || tMin < bestT)) {
        bestT = tMin;
        hit = building;
      }
    }
    if (hit != null) return (hit.doorX, hit.doorY);

    if (d[1].abs() < 1e-9) return null;
    final t = -b.pos[1] / d[1];
    if (t <= 0) return null;
    final tx = (b.pos[0] + d[0] * t).floor();
    final ty = (b.pos[2] + d[2] * t).floor();
    final map = world.map;
    if (tx < 0 || ty < 0 || tx >= map.width || ty >= map.height) return null;
    return (tx, ty);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: WorldInputLayer(
            onInput: widget.onInput,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                // Ham işaretçi olayları: three_js widget'ı kendi jestlerini kaydeder
                // ve jest yarışında `GestureDetector`'ı geçer; `Listener` yarışa girmez.
                return Listener(
                  key: const Key('townWorldTap3d'),
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (e) {
                    _downAt = e.localPosition;
                    _downTime = e.timeStamp;
                  },
                  onPointerUp: (e) {
                    final start = _downAt;
                    _downAt = null;
                    if (start == null || widget.onTapTile == null) return;
                    final quick =
                        (e.timeStamp - _downTime).inMilliseconds < 500;
                    if (!quick || (e.localPosition - start).distance > 12) {
                      return;
                    }
                    final tile = _tapTarget(e.localPosition, size);
                    if (tile != null) widget.onTapTile!(tile.$1, tile.$2);
                  },
                  onPointerCancel: (_) => _downAt = null,
                  child: _three.build(),
                );
              },
            ),
          ),
        ),
        ...widget.overlay,
      ],
    );
  }
}

/// Kamera tabanı (dokunma ışını ve izdüşüm için).
class _CameraBasis {
  const _CameraBasis({
    required this.pos,
    required this.fwd,
    required this.right,
    required this.up,
  });

  final List<double> pos;
  final List<double> fwd;
  final List<double> right;
  final List<double> up;

  double dot(List<double> a, List<double> b) =>
      a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}
