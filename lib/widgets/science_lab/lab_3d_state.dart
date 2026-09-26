import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../glb_model_library.dart';
import '../scene_zoom_button.dart';
import '../three_pick.dart';

/// Kameranın bakacağı nokta ve oradan uzaklığı (yakınlaştırma 1'de).
typedef LabCameraShot = ({three.Vector3 look, three.Vector3 offset});

/// Bilim İnsanları 3B görünümlerinin ortak iskeleti (Arşimet, Newton…):
/// ThreeJS'in gecikmeli kurulumu, ışıklar, istasyonlar arası kayan kamera,
/// yakınlaştırma (tekerlek / iki parmak / düğmeler) ve Android renk sızması
/// düzeltmesi. Kamera yönü sabittir, döndürme yok (Oda görünümüyle aynı
/// gerekçe: deney düzeneği hep önden okunmalı).
///
/// Alt sınıf yalnızca dünyasını kurar ([buildWorld]), sahne verisindeki
/// yapısal değişimleri uygular ([syncWorld], [markDirty] sonrası bir kez) ve
/// her karede verisine doğru yumuşakça ilerler ([animateWorld]).
abstract class Lab3DState<W extends StatefulWidget> extends State<W> {
  three.ThreeJS? _threeOrNull;
  three.ThreeJS get threeJs => _threeOrNull!;

  double get fovDeg => 42;
  int get background => 0xBFE3F5;
  static const _zoomMin = 0.45;
  static const _zoomMax = 2.2;

  double _zoom = 1;
  double _zoomTarget = 1;
  final three.Vector3 _look = three.Vector3(0, 1, 0);
  bool _snapCamera = true;
  bool _dirty = true;
  bool _ready = false;

  /// Açılıştan beri geçen süre (salınım gibi sürekli hareketler için).
  double clock = 0;

  Future<void> buildWorld(three.Scene scene);
  void syncWorld();
  void animateWorld(double dt);
  LabCameraShot get cameraShot;

  /// Sahne verisi değişti: bir sonraki karede [syncWorld] çağrılır.
  void markDirty() => _dirty = true;

  // ─────────────────────────── Yardımcılar ───────────────────────────

  final Map<String, three.Material> _materials = {};
  late final three.BoxGeometry unitBox = three.BoxGeometry(1, 1, 1);

  /// Önbellekli malzeme. [opacity] < 1 saydamdır ve derinlik yazmaz (su,
  /// cam): içindeki cisimler sıralamadan bağımsız görünür. [glow] ışıktan
  /// etkilenmeyen parlak renk (ışık huzmesi, ekrandaki renk bandı). Web
  /// dışında her yeni malzeme oluşturulduğu anda yalıtılır.
  three.Material material(
    int color, {
    double roughness = 0.85,
    double opacity = 1,
    bool glow = false,
  }) => _materials.putIfAbsent('$color/$roughness/$opacity/$glow', () {
    final map = <String, dynamic>{'color': color};
    if (opacity < 1) {
      map['transparent'] = true;
      map['opacity'] = opacity;
      map['depthWrite'] = false;
    }
    map['roughness'] = roughness;
    final three.Material m = glow
        ? three.MeshBasicMaterial.fromMap(map..remove('roughness'))
        : three.MeshStandardMaterial.fromMap(map);
    // Sonradan (ör. her karede pencere yanınca) ilk kez kullanılan
    // malzemeler de Android renk sızmasından korunsun; sahne yalıtımı
    // yalnızca o an sahnede olanları kapsar.
    if (!kIsWeb) isolateMaterialProgram(m);
    return m;
  });

  three.Mesh box(int color, double w, double h, double d, {double opacity = 1}) =>
      three.Mesh(unitBox, material(color, opacity: opacity))
        ..scale.setValues(w, h, d);

  /// [library]'deki [id] grubunun kopyası; yoksa [fallbackColor] renkli,
  /// [size] boyunda bir kutu (oyun modelsiz de çalışsın).
  three.Object3D model(
    GlbModelLibrary library,
    String id, {
    int fallbackColor = 0x9E9E9E,
    double size = 0.4,
  }) {
    final node = library.tryBuild(id);
    if (node != null) return node;
    final mesh = three.Mesh(unitBox, material(fallbackColor))
      ..scale.setValues(size, size, size)
      ..position.setValues(0, size / 2, 0);
    return three.Object3D()..add(mesh);
  }

  /// Sahneye sonradan eklenen düğümler için (Android renk sızması, bkz.
  /// `three_pick.dart`).
  void isolate(three.Object3D root) {
    if (!kIsWeb) isolateMaterialPrograms(root);
  }

  // ─────────────────────────── Yaşam döngüsü ───────────────────────────

  @override
  void dispose() {
    _threeOrNull?.dispose();
    three.loading.clear();
    super.dispose();
  }

  Future<void> _setup() async {
    final scene = three.Scene();
    scene.background = three.Color.fromHex32(background);
    threeJs.scene = scene;
    threeJs.camera = three.PerspectiveCamera(
      fovDeg,
      threeJs.width / threeJs.height,
      kIsWeb ? 0.3 : 1.0,
      kIsWeb ? 140 : 90,
    );
    scene.add(three.AmbientLight(0xffffff, 0.6));
    final sun = three.DirectionalLight(0xfff4e0, 0.95);
    sun.position.setValues(6, 12, 9);
    scene.add(sun);
    final fill = three.DirectionalLight(0xffffff, 0.3);
    fill.position.setValues(-6, 5, -4);
    scene.add(fill);

    await buildWorld(scene);
    _ready = true;
    _dirty = false;
    syncWorld();
    isolate(scene);
    threeJs.addAnimationEvent(_onFrame);
  }

  void _onFrame(double dt) {
    dt = min(0.1, dt);
    clock += dt;
    if (_dirty && _ready) {
      _dirty = false;
      syncWorld();
    }
    animateWorld(dt);
    if ((_zoomTarget - _zoom).abs() > 1e-4) {
      _zoom += (_zoomTarget - _zoom) * min(1.0, dt * 9);
    }
    _placeCamera(dt);
  }

  /// Sahne kutusunun gerçek en/boy oranı.
  ///
  /// three_js çizim yüzeyini **pencere** boyutunda kurar ve widget'ı kutuya
  /// gerdirir (web'de `HtmlElementView`, Android'de `Texture` sıkı kısıtla
  /// kutuyu doldurur). Kamera pencere oranıyla çizerse kutu pencereden dar
  /// olduğunda görüntü yatayda sıkışır: küreler yumurta olur (Galileo'da
  /// Jüpiter'de görüldü). Kamerayı kutunun oranıyla çizdirmek, gerdirmeyi
  /// tam telafi eder. three_js pencere değişince oranı geri yazdığı için her
  /// karede denetlenir.
  double _boxAspect = 0;

  void _placeCamera(double dt) {
    final camera = threeJs.camera as three.PerspectiveCamera;
    if (_boxAspect > 0 && (camera.aspect - _boxAspect).abs() > 1e-3) {
      camera.aspect = _boxAspect;
      camera.updateProjectionMatrix();
    }
    final shot = cameraShot;
    final k = _snapCamera ? 1.0 : min(1.0, dt * 3);
    _snapCamera = false;
    _look.x += (shot.look.x - _look.x) * k;
    _look.y += (shot.look.y - _look.y) * k;
    _look.z += (shot.look.z - _look.z) * k;
    // Dikey (telefon) ekranda yatay görüş dar: uzaktan başla.
    final aspect = _boxAspect > 0 ? _boxAspect : threeJs.width / max(1, threeJs.height);
    final z = _zoom * (aspect < 1 ? max(1.0, 0.8 / aspect) : 1.0);
    camera.position.x += (_look.x + shot.offset.x * z - camera.position.x) * k;
    camera.position.y += (_look.y + shot.offset.y * z - camera.position.y) * k;
    camera.position.z += (_look.z + shot.offset.z * z - camera.position.z) * k;
    camera.lookAt(_look);
  }

  void _setZoom(double value) {
    _zoomTarget = value.clamp(_zoomMin, _zoomMax).toDouble();
  }

  // ─────────────────────────── Widget ───────────────────────────

  final Map<int, Offset> _pointers = {};
  double _pinchStartDistance = 0;
  double _pinchStartZoom = 1;

  @override
  Widget build(BuildContext context) {
    if (_threeOrNull == null) {
      // three_js doku boyutunu kurulduğu anki boyuttan okur; Android'de ilk
      // karede 0 olabilir (bkz. `Room3DView`).
      if (MediaQuery.sizeOf(context).isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      _threeOrNull = three.ThreeJS(
        onSetupComplete: () => setState(() {}),
        setup: _setup,
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxHeight > 0 && constraints.maxWidth.isFinite) {
                _boxAspect = constraints.maxWidth / constraints.maxHeight;
              }
              return _listener();
            },
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Column(
            children: [
              SceneZoomButton(
                key: const Key('labZoomIn'),
                icon: Icons.add,
                tooltip: 'Yakınlaştır',
                onPressed: () => _setZoom(_zoomTarget * 0.82),
              ),
              const SizedBox(height: 6),
              SceneZoomButton(
                key: const Key('labZoomOut'),
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

  /// Yakınlaştırma jestleri (tekerlek, iki parmak). Ham `Listener`: three_js
  /// widget'ı kendi jestlerini kaydeder ve jest yarışını kazanırdı.
  Widget _listener() => Listener(
    key: const Key('lab3d'),
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      _pointers[e.pointer] = e.localPosition;
      if (_pointers.length == 2) {
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
          _setZoom(_pinchStartZoom * _pinchStartDistance / distance);
        }
      }
    },
    onPointerUp: (e) => _pointers.remove(e.pointer),
    onPointerCancel: (e) => _pointers.remove(e.pointer),
    onPointerSignal: (event) {
      if (event is PointerScrollEvent) {
        _setZoom(_zoomTarget * exp(event.scrollDelta.dy * 0.0012));
      }
    },
    child: threeJs.build(),
  );
}
