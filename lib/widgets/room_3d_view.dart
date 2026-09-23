import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../models/town/room_layout.dart';
import '../models/town/shop_catalog.dart';
import 'furniture_model.dart';
import 'scene_zoom_button.dart';
import 'three_pick.dart';

/// Odanın gerçek 3D görünümü (three_js). `IsoRoomView` ile **aynı sözleşmeyi**
/// taşır (`layout` / `onTapTile` / `selectedIndex`), böylece oda ekranı ikisi
/// arasında geçiş yapabilir; testler ve WebGL'siz platformlar 2B görünümde kalır.
///
/// Kare `(x, y)` 3B'de `(x, 0, y)`dir; kamera kasabayla **aynı yönden** bakar
/// (`+x, +z` tarafından), bu yüzden duvarlar `x = 0` ve `z = 0` kenarlarında
/// arkada kalır — izometrik görünümdeki düzenin aynısı.
///
/// **Kamera yönü sabittir, yalnızca yakınlaştırma var**: oda kapalı bir hacim
/// olduğu için döndürmek kamerayı duvarların arkasına atardı (kasabada böyle
/// bir sorun yok, orada döndürme serbest).
class Room3DView extends StatefulWidget {
  const Room3DView({
    super.key,
    required this.layout,
    required this.onTapTile,
    this.selectedIndex = -1,
  });

  final RoomLayout layout;
  final void Function(int x, int y) onTapTile;

  /// Seçili yerleştirilmiş eşyanın indeksi (-1: yok).
  final int selectedIndex;

  @override
  State<Room3DView> createState() => _Room3DViewState();
}

class _Room3DViewState extends State<Room3DView> {
  /// three_js doku boyutunu kurulduğu anki boyuttan okur; Android'de ilk karede
  /// bu 0 olabilir ve native doku reddedilir (bkz. `Town3DView`).
  three.ThreeJS? _threeOrNull;
  three.ThreeJS get _three => _threeOrNull!;

  static const _fovDeg = 40.0;
  static const _camBack = 7.6;
  static const _camHeight = 9.6;
  static const _zoomMin = 0.5;
  static const _zoomMax = 2.4;
  static const _wallHeight = 2.3;

  /// Varsayılan uzaklık: oda kadraja tam otursun. Dikey (telefon) ekranda yatay
  /// görüş dar olduğu için daha uzaktan başlar (kasabadaki `_defaultZoom` ile
  /// aynı mantık).
  static double _defaultZoom(double aspect) {
    if (aspect >= 1.4) return 0.92;
    if (aspect <= 0.6) return 1.5;
    return 1.5 - (aspect - 0.6) / 0.8 * 0.58;
  }

  double _zoom = 0.92;
  double _zoomTarget = 0.92;

  /// Odanın merkezi (kameranın baktığı nokta).
  final three.Vector3 _look = three.Vector3(roomSize / 2, 0.7, roomSize / 2);

  /// Mobilya ve vurgu düğümlerini taşıyan grup; düzen değişince içi yenilenir.
  three.Object3D? _roomGroup;
  bool _needsRebuild = false;

  /// **Kalıcı** GPU kaynakları: geometri ve malzemeler bir kez kurulup her
  /// yeniden kurulumda paylaşılır. Yeniden kurulumda yalnızca `Mesh` sarmalları
  /// atılır — GLB kopyaları geometriyi/malzemeyi şablonla paylaştığı için
  /// `dispose()` etmek sonraki kopyaları bozar, bu yüzden hiç dispose edilmez.
  final Map<String, three.BoxGeometry> _boxes = {};
  final Map<String, three.MeshStandardMaterial> _materials = {};

  three.BoxGeometry _box(double w, double h, double d) => _boxes.putIfAbsent(
    '$w/$h/$d',
    () => three.BoxGeometry(w, h, d),
  );

  three.MeshStandardMaterial _material(
    int color, {
    double roughness = 0.9,
    double emissive = 0,
  }) => _materials.putIfAbsent('$color/$roughness/$emissive', () {
    final map = <String, dynamic>{'color': color, 'roughness': roughness};
    if (emissive > 0) {
      map['emissive'] = color;
      map['emissiveIntensity'] = emissive;
    }
    return three.MeshStandardMaterial.fromMap(map);
  });

  void _createThree() {
    _threeOrNull = three.ThreeJS(
      onSetupComplete: () => setState(() {}),
      setup: _setup,
    );
  }

  @override
  void dispose() {
    _threeOrNull?.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(Room3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `RoomLayout`/`PlacedItem` `==` tanımlamaz; `copyWith` her değişimde yeni
    // örnek üretir, yani kimlik değişimi "bir şey değişti" demektir.
    if (oldWidget.layout != widget.layout ||
        oldWidget.selectedIndex != widget.selectedIndex) {
      _needsRebuild = true;
    }
  }

  Future<void> _setup() async {
    final scene = three.Scene();
    scene.background = three.Color.fromHex32(0xECEFF1);
    _three.scene = scene;

    final camera = three.PerspectiveCamera(
      _fovDeg,
      _three.width / _three.height,
      kIsWeb ? 0.5 : 1.5,
      kIsWeb ? 120 : 70,
    );
    _three.camera = camera;
    _placeCamera(camera, snap: true);

    // Aydınlatma gözle dengelendi: **gölgeler bu kurulumda hiç işlenmiyor**
    // (kasabada da öyle — `castShadow` ayarlı ve `Settings.enableShadowMap`
    // varsayılan olarak açık olduğu hâlde web'de gölge çıkmıyor), o yüzden
    // hacim hissi tamamen yüz normallerine bağlı: ortam ışığı yüzeyleri
    // eşitlediği için güneşten çok baskın olmamalı.
    scene.add(three.AmbientLight(0xffffff, 0.58));
    final sun = three.DirectionalLight(0xfff4e0, 0.95);
    sun.castShadow = true;
    sun.shadow?.mapSize.width = 1024;
    sun.shadow?.mapSize.height = 1024;
    // Gölge bozulması (shadow acne) önlemi, kasabadaki ayarların aynısı.
    sun.shadow?.bias = -0.0006;
    sun.shadow?.normalBias = 0.03;
    final shadowCam = sun.shadow?.camera;
    if (shadowCam != null) {
      shadowCam.left = -9;
      shadowCam.right = 9;
      shadowCam.top = 9;
      shadowCam.bottom = -9;
      shadowCam.near = 1;
      shadowCam.far = 40;
    }
    sun.position.setValues(roomSize * 0.9, 10, roomSize * 1.0);
    sun.target?.position.setValues(roomSize / 2, 0, roomSize / 2);
    scene.add(sun);
    scene.add(sun.target);
    // Arka duvarlar karanlık kalmasın diye karşıdan zayıf bir dolgu ışığı.
    final fill = three.DirectionalLight(0xffffff, 0.28);
    fill.position.setValues(-4, 6, -4);
    scene.add(fill);

    final group = three.Object3D();
    scene.add(group);
    _roomGroup = group;

    await FurnitureModel.preload();
    _rebuild();

    _three.addAnimationEvent(_onFrame);
  }

  void _placeCamera(three.PerspectiveCamera camera, {bool snap = false, double dt = 0}) {
    final desired = three.Vector3(
      roomSize / 2 + _camBack * _zoom,
      _camHeight * _zoom,
      roomSize / 2 + _camBack * _zoom,
    );
    if (snap) {
      camera.position.setFrom(desired);
    } else {
      final k = min(1.0, dt * 8);
      camera.position.x += (desired.x - camera.position.x) * k;
      camera.position.y += (desired.y - camera.position.y) * k;
      camera.position.z += (desired.z - camera.position.z) * k;
    }
    camera.lookAt(_look);
  }

  void _onFrame(double dt) {
    dt = min(0.1, dt);
    if (_needsRebuild) {
      _needsRebuild = false;
      _rebuild();
    }
    if ((_zoomTarget - _zoom).abs() > 1e-4) {
      _zoom += (_zoomTarget - _zoom) * min(1.0, dt * 9);
    }
    _placeCamera(_three.camera as three.PerspectiveCamera, dt: dt);
  }

  void _setZoom(double value) {
    _zoomTarget = value.clamp(_zoomMin, _zoomMax).toDouble();
  }

  // ─────────────────────────── Sahne kurulumu ───────────────────────────

  three.Mesh _mesh(
    three.BufferGeometry geometry,
    three.Material material,
    double x,
    double y,
    double z,
  ) => three.Mesh(geometry, material)
    ..position.setValues(x, y, z)
    ..castShadow = true
    ..receiveShadow = true;

  /// Zemin, duvarlar, mobilyalar ve seçim vurgusu. Düzen her değiştiğinde
  /// baştan kurulur (kullanıcı hareketiyle olur, karede bir değil).
  void _rebuild() {
    final group = _roomGroup;
    if (group == null) return;
    for (final child in group.children.toList()) {
      group.remove(child);
    }

    final floor = roomFloorColors[widget.layout.floorColor % roomFloorColors.length];
    final wall = roomWallColors[widget.layout.wallColor % roomWallColors.length];

    // Zemin: her kare bir ince kutu; satranç deseni gibi hafif iki ton
    // (izometrik görünümdeki aynı etki).
    final tile = _box(1, 0.2, 1);
    final light = _material(floor, roughness: 0.95);
    final dark = _material(_shade(floor, 0.06), roughness: 0.95);
    for (var y = 0; y < roomSize; y++) {
      for (var x = 0; x < roomSize; x++) {
        group.add(
          _mesh(tile, (x + y).isEven ? light : dark, x + 0.5, -0.1, y + 0.5),
        );
      }
    }

    // Duvarlar: z = 0 ve x = 0 kenarlarında (kameradan uzak taraf).
    const t = 0.12;
    const span = roomSize + t;
    // Duvarlar neredeyse tonlanmadan kullanılır; koyultunca krem renk
    // ekranda grimsi kahveye dönüyordu (ışık zaten iki yüzü ayırıyor).
    final wallBack = _material(_shade(wall, 0.02), roughness: 0.95);
    final wallSide = _material(wall, roughness: 0.95);
    group.add(
      _mesh(
        _box(span, _wallHeight, t),
        wallBack,
        roomSize / 2 - t / 2,
        _wallHeight / 2,
        -t / 2,
      ),
    );
    group.add(
      _mesh(
        _box(t, _wallHeight, span),
        wallSide,
        -t / 2,
        _wallHeight / 2,
        roomSize / 2 - t / 2,
      ),
    );
    // Süpürgelik.
    final skirting = _material(_shade(wall, 0.35), roughness: 0.8);
    group.add(
      _mesh(_box(span, 0.14, t * 1.4), skirting, roomSize / 2 - t / 2, 0.07, 0),
    );
    group.add(
      _mesh(_box(t * 1.4, 0.14, span), skirting, 0, 0.07, roomSize / 2 - t / 2),
    );

    for (var i = 0; i < widget.layout.items.length; i++) {
      final node = _furnitureNode(widget.layout.items[i]);
      if (node != null) group.add(node);
    }
    _addSelectionFrame(group);

    if (!kIsWeb) isolateMaterialPrograms(group);
  }

  /// Rengi [amount] kadar koyulaştırır (zemin/duvar tonlamaları için).
  static int _shade(int color, double amount) {
    int ch(int shift) {
      final v = (color >> shift) & 255;
      return (v * (1 - amount)).round().clamp(0, 255);
    }

    return (ch(16) << 16) | (ch(8) << 8) | ch(0);
  }

  /// Yerleştirilmiş eşyanın düğümü: modelin kendi yerel kutusu ayak izinin
  /// merkezine oturtulur, dönüş bu merkez etrafında yapılır — böylece
  /// `RoomLayout.footprint`'in genişlik/derinlik takası ile birebir uyuşur.
  three.Object3D? _furnitureNode(PlacedItem placed) {
    final item = shopItemById(placed.itemId);
    if (item == null) return null;
    final model = FurnitureModel.tryBuild(item) ?? _fallbackBox(item);
    final (w, d) = RoomLayout.footprint(item, placed.rotation);
    // `rotation.y = -90°` yerel +x'i +z'ye çevirir: kare uzayında saat yönü.
    final pivot = three.Object3D()
      ..position.setValues(placed.x + w / 2, 0, placed.y + d / 2);
    pivot.rotation.y = -placed.rotation * pi / 2;
    model.position.setValues(-item.width / 2, 0, -item.depth / 2);
    pivot.add(model);
    return pivot;
  }

  /// Model yoksa: katalog rengiyle düz bir kutu (izometrik görünümdeki gibi).
  three.Object3D _fallbackBox(ShopItem item) {
    final h = max(item.height, 0.03);
    final mesh = _mesh(
      _box(item.width - 0.06, h, item.depth - 0.06),
      _material(item.colorValue & 0xFFFFFF, roughness: 0.85),
      item.width / 2,
      h / 2,
      item.depth / 2,
    );
    return three.Object3D()..add(mesh);
  }

  /// Seçili eşyanın vurgusu: ayak izini çerçeveleyen dört ince çubuk **ve**
  /// eşyanın üstünde yüzen aşağı bakan bir koni.
  ///
  /// Yerdeki çerçeve tek başına yetmiyor: kitaplık/lamba gibi yüksek eşyalarda
  /// çerçeve tamamen gövdenin altında kalıp görünmüyor (tarayıcıda görüldü).
  /// Koni her açıdan görünür ve halı gibi düz eşyalarda da zarar vermez.
  /// Saydamlık kullanılmaz — three_js'te saydam yüzeylerin sıralaması sorun
  /// çıkarıyor.
  void _addSelectionFrame(three.Object3D group) {
    final index = widget.selectedIndex;
    if (index < 0 || index >= widget.layout.items.length) return;
    final placed = widget.layout.items[index];
    final item = shopItemById(placed.itemId);
    if (item == null) return;
    final (w, d) = RoomLayout.footprint(item, placed.rotation);
    final mat = _material(0xFFC107, roughness: 0.5, emissive: 0.6);
    const bar = 0.09;
    final x0 = placed.x.toDouble();
    final y0 = placed.y.toDouble();
    final wide = _box(w.toDouble(), 0.05, bar);
    final tall = _box(bar, 0.05, d.toDouble());
    group.add(_mesh(wide, mat, x0 + w / 2, 0.03, y0 + bar / 2));
    group.add(_mesh(wide, mat, x0 + w / 2, 0.03, y0 + d - bar / 2));
    group.add(_mesh(tall, mat, x0 + bar / 2, 0.03, y0 + d / 2));
    group.add(_mesh(tall, mat, x0 + w - bar / 2, 0.03, y0 + d / 2));

    final marker = three.Mesh(_cone, mat)
      ..position.setValues(
        x0 + w / 2,
        max(item.height, 0.05) + 0.34,
        y0 + d / 2,
      )
      ..rotation.x = pi; // ucu aşağı baksın
    group.add(marker);
  }

  /// Seçim işaretinin konisi (bir kez kurulur, bkz. `_boxes`/`_materials`).
  three.ConeGeometry? _coneOrNull;
  three.ConeGeometry get _cone =>
      _coneOrNull ??= three.ConeGeometry(0.15, 0.26, 4);

  // ─────────────────────────── Dokunma ───────────────────────────

  /// Dokunulan karo: önce yüksek eşyaların kutusu (gövdesine dokunmak onu
  /// seçsin, ışın arkadaki zemine gitmesin), yoksa zemin düzlemi. Halı gibi
  /// zemin eşyaları kutu denemesine girmez — üstüne dokunmak karoyu verir ve
  /// `RoomLayout.itemIndexAt` gerisini çözer.
  (int, int)? _tapTile(Offset local, Size size) {
    if (_threeOrNull == null || size.isEmpty) return null;
    final basis = ThreeSceneBasis.of(_three.camera, _look, fovDeg: _fovDeg);
    if (basis == null) return null;
    final dir = basis.rayThrough(local, size);

    double? bestT;
    (int, int)? hit;
    for (final placed in widget.layout.items) {
      final item = shopItemById(placed.itemId);
      if (item == null || RoomLayout.isFlat(item)) continue;
      final (w, d) = RoomLayout.footprint(item, placed.rotation);
      final t = basis.intersectBox(
        dir,
        [placed.x.toDouble(), 0, placed.y.toDouble()],
        [
          (placed.x + w).toDouble(),
          item.height + 0.08,
          (placed.y + d).toDouble(),
        ],
      );
      if (t != null && (bestT == null || t < bestT)) {
        bestT = t;
        hit = (placed.x, placed.y);
      }
    }
    if (hit != null) return hit;

    final ground = basis.hitPlane(dir);
    if (ground == null) return null;
    final x = ground.$1.floor();
    final y = ground.$2.floor();
    if (x < 0 || y < 0 || x >= roomSize || y >= roomSize) return null;
    return (x, y);
  }

  final Map<int, Offset> _pointers = {};
  double _pinchStartDistance = 0;
  double _pinchStartZoom = 1;
  bool _gestureIsPinch = false;
  Offset? _downAt;

  @override
  Widget build(BuildContext context) {
    if (_threeOrNull == null) {
      final size = MediaQuery.sizeOf(context);
      if (size.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      _zoom = _zoomTarget = _defaultZoom(size.width / size.height);
      _createThree();
    }
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              // Ham işaretçi olayları: three_js widget'ı kendi jestlerini
              // kaydeder ve jest yarışını kazanır; `Listener` yarışa girmez.
              return Listener(
                key: const Key('roomTap3d'),
                behavior: HitTestBehavior.translucent,
                onPointerDown: (e) {
                  _pointers[e.pointer] = e.localPosition;
                  if (_pointers.length == 1) {
                    _downAt = e.localPosition;
                    _gestureIsPinch = false;
                  } else if (_pointers.length == 2) {
                    _downAt = null;
                    _gestureIsPinch = true;
                    final pts = _pointers.values.toList();
                    _pinchStartDistance = (pts[0] - pts[1]).distance;
                    _pinchStartZoom = _zoomTarget;
                  }
                },
                onPointerMove: (e) {
                  if (!_pointers.containsKey(e.pointer)) return;
                  _pointers[e.pointer] = e.localPosition;
                  if (_pointers.length == 2 && _pinchStartDistance > 1) {
                    final pts = _pointers.values.toList();
                    final distance = (pts[0] - pts[1]).distance;
                    if (distance > 1) {
                      _setZoom(
                        _pinchStartZoom * _pinchStartDistance / distance,
                      );
                    }
                  }
                },
                onPointerUp: (e) {
                  _pointers.remove(e.pointer);
                  final start = _downAt;
                  _downAt = null;
                  if (_gestureIsPinch) {
                    if (_pointers.isEmpty) _gestureIsPinch = false;
                    return;
                  }
                  if (start == null) return;
                  if ((e.localPosition - start).distance > 12) return;
                  final tile = _tapTile(e.localPosition, size);
                  if (tile != null) widget.onTapTile(tile.$1, tile.$2);
                },
                onPointerCancel: (e) {
                  _pointers.remove(e.pointer);
                  _downAt = null;
                  if (_pointers.isEmpty) _gestureIsPinch = false;
                },
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    _setZoom(_zoomTarget * exp(event.scrollDelta.dy * 0.0012));
                  }
                },
                child: _three.build(),
              );
            },
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Column(
            children: [
              SceneZoomButton(
                key: const Key('roomZoomIn'),
                icon: Icons.add,
                tooltip: 'Yakınlaştır',
                onPressed: () => _setZoom(_zoomTarget * 0.82),
              ),
              const SizedBox(height: 6),
              SceneZoomButton(
                key: const Key('roomZoomOut'),
                icon: Icons.remove,
                tooltip: 'Uzaklaştır',
                onPressed: () => _setZoom(_zoomTarget / 0.82),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
