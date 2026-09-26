import 'dart:math';

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../../models/newton/cart.dart';
import '../../models/newton/falling.dart';
import '../../models/newton/newton_scene.dart';
import '../../models/newton/prism.dart';
import '../glb_model_library.dart';
import '../science_lab/lab_3d_state.dart';

/// Newton'un laboratuvarının 3B görünümü. Modeller Blender'da üretilmiştir
/// (`assets/models/newton.glb`, üretici `tool/blender/build_newton.py`).
///
/// Deneyler zamana bağlıdır: [NewtonScene.run] değişince görünüm saatini
/// sıfırlar ve konumları **modelden** okur (`fallDistance`,
/// `cartPositionAt`), böylece ekranda görülen ile açıklamadaki süreler
/// birebir tutar. 2B yedeği `NewtonLab2DView` aynı veriyi çizer.
class NewtonLab3DView extends StatefulWidget {
  const NewtonLab3DView({super.key, required this.scene});

  final NewtonScene scene;

  static final models = GlbModelLibrary('newton.glb');

  @override
  State<NewtonLab3DView> createState() => _NewtonLab3DViewState();
}

// Dünya yerleşimi (1 birim = 1 m); üç istasyon x ekseninde yan yana.
const double _fallX = 0;
const double _prismX = 22;
const double _cartX = 44;
const double _tableTop = 0.9;

/// Cisimlerin asılı durduğu kanca yüksekliği ve kulenin iki kolu.
const double _hookY = towerHeightM - 0.14;
const double _armX = 0.95;

/// Işık yelpazesinin açısal genişliği ekranda görülsün diye bu kadar
/// büyütülür (gerçek fark yalnızca ~5°).
const double _spreadGain = 2.5;
const double _screenDistance = 1.6;

/// Işık yüksekliği (fenerin yarığı, masadan 0,25 m) ve prizmanın merkezi.
const double _beamY = _tableTop + 0.25;
const double _entryX = _prismX - 0.4;

/// Renklerin ortalama sapması (derece). Fener bu açı kadar çapraz konur ki
/// yelpazenin ortası masanın boyunca (+x) gitsin ve perde masaya otursun.
final double _meanDeviation =
    spectrumColors.map(deviationDeg).reduce((a, b) => a + b) /
    spectrumColors.length;

/// Yön: açı φ için (cos φ, 0, −sin φ) — `rotation.y = φ` yerel +x'i buraya çevirir.
three.Vector3 _dir(double phi) => three.Vector3(cos(phi), 0, -sin(phi));

/// İki pistin z konumu: A arkada, B önde (kameraya yakın).
const double _laneAZ = -0.55;
const double _laneBZ = 0.55;
const double _trackStart = _cartX - trackLengthM / 2;

class _NewtonLab3DViewState extends Lab3DState<NewtonLab3DView> {
  GlbModelLibrary get _lib => NewtonLab3DView.models;

  // Düşme istasyonu.
  three.Mesh? _ground;
  three.Object3D? _tree;
  three.Mesh? _tube;
  final List<_Faller> _fallers = [];
  String _fallSignature = '';

  // Prizma istasyonu.
  three.Object3D? _secondPrism;
  final List<three.Mesh> _beams = [];
  final List<three.Mesh> _spots = [];
  three.Mesh? _inBeam;
  String _prismSignature = '';

  // Araba istasyonu.
  final List<_CartNodes> _carts = [];
  final List<three.Mesh> _laneSurfaces = [];
  three.Object3D? _plungerA;
  three.Object3D? _plungerB;
  String _cartSignature = '';

  // Deney saati: her yeni `run`'da sıfırlanır.
  int _lastRun = -1;
  NewtonStation? _lastStation;
  double _t = 0;

  NewtonScene get _s => widget.scene;

  @override
  void didUpdateWidget(NewtonLab3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) markDirty();
  }

  @override
  Future<void> buildWorld(three.Scene scene) async {
    await _lib.preload();
    _buildFallStation(scene);
    _buildPrismStation(scene);
    _buildCartStation(scene);
  }

  three.Object3D _model(String id, {int color = 0x9E9E9E, double size = 0.3}) =>
      model(_lib, id, fallbackColor: color, size: size);

  // ─────────────────────────── Kurulum ───────────────────────────

  void _buildFallStation(three.Scene scene) {
    _ground = box(0x7CB342, 18, 0.2, 12)..position.setValues(_fallX, -0.1, 0);
    scene.add(_ground!);
    scene.add(_model('newton_tower', color: 0xA9713F, size: 1)
      ..position.setValues(_fallX, 0, 0));
    _tree = _model('newton_tree', color: 0x4CAF50, size: 1)
      ..position.setValues(_fallX - 4, 0, -2);
    scene.add(_tree!);
    scene.add(_model('newton_figure', color: 0x3E2723, size: 0.5)
      ..position.setValues(_fallX + 2.6, 0, 1.4)
      ..rotation.y = -0.4);
    // Havası boşaltılmış tüp (yalnızca vakum deneyinde görünür).
    _tube = three.Mesh(
      three.CylinderGeometry(1.7, 1.7, towerHeightM + 0.6, 28, 1, true),
      material(0xB3E5FC, opacity: 0.18),
    )..position.setValues(_fallX, (towerHeightM + 0.6) / 2, 0);
    scene.add(_tube!);
  }

  void _buildPrismStation(three.Scene scene) {
    scene.add(_model('newton_room', color: 0xEFE6D6, size: 0.1)
      ..position.setValues(_prismX, 0, 0));
    // Masa derinleştirildi (fener çapraz duruyor).
    scene.add(_model('newton_table', color: 0xA9713F, size: 0.9)
      ..position.setValues(_prismX, 0, 0)
      ..scale.setValues(1, 1, 1.6));
    final phiIn = -_meanDeviation * pi / 180;
    final slit = _entry.clone()..sub(_dir(phiIn)..scale(0.9));
    final lampBase = slit.clone()..sub(_dir(phiIn)..scale(0.2));
    scene.add(_model('newton_lamp', color: 0x37474F, size: 0.4)
      ..position.setValues(lampBase.x, _tableTop, lampBase.z)
      ..rotation.y = phiIn);
    _slit = slit;
    scene.add(_prism()..position.setValues(_entry.x, _tableTop, _entry.z));
    _secondPrism = _prism()
      ..position.setValues(_q.x, _tableTop, _q.z)
      ..rotation.y = pi;
    scene.add(_secondPrism!);
    // Perde masanın ucunda, yüzü prizmaya dönük (-x).
    scene.add(_model('newton_screen', color: 0xFFFFFF, size: 0.8)
      ..position.setValues(_entry.x + _screenDistance, _tableTop, 0));
    scene.add(_model('newton_figure', color: 0x3E2723, size: 0.5)
      ..position.setValues(_prismX - 2.8, 0, 1.2)
      ..rotation.y = 0.5);
    _inBeam = three.Mesh(unitBox, material(0xFFFFFF, glow: true));
    scene.add(_inBeam!);
  }

  final three.Vector3 _entry = three.Vector3(_entryX, _beamY, 0);

  /// Ters prizmanın yeri (renklerin yeniden buluştuğu nokta).
  final three.Vector3 _q = three.Vector3(_entryX + 0.55, _beamY, 0);
  three.Vector3 _slit = three.Vector3(_entryX - 0.9, _beamY, 0);

  /// Prizma; camı saydam boyanır (Blender'da `prism_glass*`).
  three.Object3D _prism() {
    final node = _model('newton_prism', color: 0xB3E5FC, size: 0.3);
    node.traverse((o) {
      if (o is three.Mesh && o.name.startsWith('prism_glass')) {
        o.material = material(0xB3E5FC, roughness: 0.1, opacity: 0.45);
      }
    });
    return node;
  }

  void _buildCartStation(three.Scene scene) {
    scene.add(box(0xD7CCC8, 16, 0.2, 5)..position.setValues(_cartX, -0.1, 0));
    for (final z in [_laneAZ, _laneBZ]) {
      final surface = box(0xC19A6B, trackLengthM, 0.03, 0.8)
        ..position.setValues(_cartX, 0.015, z);
      scene.add(surface);
      _laneSurfaces.add(surface);
    }
    // Metre çizgileri ve sondaki tampon.
    for (var m = 0; m <= trackLengthM; m++) {
      scene.add(box(m % 5 == 0 ? 0x263238 : 0x546E7A, 0.03, 0.035, 2.0)
        ..position.setValues(_trackStart + m, 0.02, 0));
    }
    scene.add(box(0x455A64, 0.15, 0.35, 2.2)
      ..position.setValues(_trackStart + trackLengthM + 0.08, 0.17, 0));
    for (final z in [_laneAZ, _laneBZ]) {
      final launcher = _model('newton_launcher', color: 0x455A64, size: 0.3)
        ..position.setValues(_trackStart, 0.03, z);
      scene.add(launcher);
      final plunger = GlbModelLibrary.find(launcher, 'Plunger');
      if (z == _laneAZ) {
        _plungerA = plunger;
      } else {
        _plungerB = plunger;
      }
    }
    for (final z in [_laneAZ, _laneBZ]) {
      final root = _model('newton_cart', color: 0x1E88E5, size: 0.3);
      final holder = three.Object3D()..add(root);
      holder.position.setValues(_trackStart + 0.36, 0.03, z);
      scene.add(holder);
      _carts.add(
        _CartNodes(holder, [
          for (var i = 0; i < 4; i++)
            ?GlbModelLibrary.find(root, 'Wheel$i'),
        ]),
      );
    }
    scene.add(_model('newton_figure', color: 0x3E2723, size: 0.5)
      ..position.setValues(_trackStart - 1.2, 0, 1.6)
      ..rotation.y = 0.3);
  }

  // ─────────────────────────── Eşleme ───────────────────────────

  @override
  void syncWorld() {
    final s = _s;
    if (s.run != _lastRun || s.station != _lastStation) {
      _lastRun = s.run;
      _lastStation = s.station;
      _t = 0;
    }
    _syncFall(s);
    _syncPrism(s);
    _syncCarts(s);
  }

  void _syncFall(NewtonScene s) {
    final moon = s.environment == FallEnvironment.moon;
    threeJs.scene.background = three.Color.fromHex32(moon ? 0x0B1020 : 0xBFE3F5);
    _ground?.material = material(moon ? 0x9E9E9E : 0x7CB342);
    _tree?.visible = !moon;
    _tube?.visible = s.environment == FallEnvironment.vacuum;

    final objects = [s.fallA, s.fallB];
    final signature = objects.map((o) => o?.id).join(',');
    if (signature == _fallSignature) return;
    _fallSignature = signature;
    for (final f in _fallers) {
      f.node.parent?.remove(f.node);
    }
    _fallers.clear();
    for (var i = 0; i < objects.length; i++) {
      final o = objects[i];
      if (o == null) continue;
      final m = _model(o.modelId, color: 0xFF7043, size: 0.25);
      final holder = three.Object3D()..add(m);
      final box = three.BoundingBox().setFromObject(m);
      final height = max(0.02, box.max.y - box.min.y);
      m.position.y = -box.min.y; // taban y = 0
      threeJs.scene.add(holder);
      _fallers.add(_Faller(holder, o, height, i == 0 ? -_armX : _armX));
    }
    isolate(threeJs.scene);
  }

  void _syncPrism(NewtonScene s) {
    _secondPrism!.visible = s.secondPrism;
    final signature = '${s.light.name}/${s.secondPrism}';
    if (signature == _prismSignature) return;
    _prismSignature = signature;
    for (final m in [..._beams, ..._spots]) {
      m.parent?.remove(m);
    }
    _beams.clear();
    _spots.clear();
    final colors = s.light.colors;
    _inBeam!.material = material(
      s.light.onlyColorId == null ? 0xFFFFFF : colors.single.hex,
      glow: true,
    );
    // Her renk için bir huzme + perdede bir leke; ters prizma varsa en sonda
    // birleşmiş huzme + leke (tüm renkler varsa beyaz, yoksa o renk).
    for (final hex in [
      for (final c in colors) c.hex,
      if (s.secondPrism) s.prism.recombinedHex,
    ]) {
      final beam = three.Mesh(unitBox, material(hex, glow: true));
      final spot = three.Mesh(unitBox, material(hex, glow: true));
      threeJs.scene.add(beam);
      threeJs.scene.add(spot);
      _beams.add(beam);
      _spots.add(spot);
    }
  }

  void _syncCarts(NewtonScene s) {
    final lanes = [s.laneA, s.laneB];
    final signature = lanes.map((l) => l == null ? '-' : '${l.boxes}/${l.surface.name}').join(',');
    if (signature == _cartSignature) return;
    _cartSignature = signature;
    for (var i = 0; i < _carts.length; i++) {
      final lane = lanes[i];
      final cart = _carts[i];
      cart.holder.visible = lane != null;
      _laneSurfaces[i].visible = lane != null;
      if (lane == null) continue;
      _laneSurfaces[i].material = material(
        switch (lane.surface) {
          CartSurface.ice => 0xE1F5FE,
          CartSurface.wood => 0xC19A6B,
          CartSurface.carpet => 0xB23A48,
        },
        roughness: lane.surface == CartSurface.ice ? 0.1 : 0.9,
      );
      for (final b in cart.boxes) {
        cart.holder.remove(b);
      }
      cart.boxes.clear();
      const spots = [(-0.14, 0.24), (0.14, 0.24), (0.0, 0.48)];
      for (var k = 0; k < lane.boxes && k < spots.length; k++) {
        final b = _model('newton_box', color: 0xC68A4E, size: 0.24)
          ..position.setValues(spots[k].$1, spots[k].$2, 0);
        cart.holder.add(b);
        cart.boxes.add(b);
      }
    }
    isolate(threeJs.scene);
  }

  // ─────────────────────────── Kare ───────────────────────────

  @override
  void animateWorld(double dt) {
    final s = _s;
    if (s.run > 0) _t += dt;
    _animateFall(s);
    _animatePrism(s);
    _animateCarts(s);
  }

  void _animateFall(NewtonScene s) {
    for (final f in _fallers) {
      final start = _hookY - f.height;
      final d = s.run > 0 ? fallDistance(f.object, _t, s.environment) : 0.0;
      final landed = d >= towerHeightM - 1e-6;
      final y = start - d / towerHeightM * (start - 0.04);
      // Havada süzülen hafif cisimler sallanır.
      final flutter = s.environment.hasAir && f.object.terminalSpeed < 3 && !landed
          ? sin(_t * 5 + f.x) * 0.35
          : 0.0;
      f.node.position.setValues(_fallX + f.x + flutter * 0.4, y, 0.2);
      f.node.rotation.z = flutter;
    }
  }

  void _animatePrism(NewtonScene s) {
    final on = s.run > 0;
    // Işık önce fenerden prizmaya uzanır, sonra yelpaze açılır.
    final grow = on ? min(1.0, _t / 0.6) : 0.0;
    _placeBeam(_inBeam!, _slit, _entry, grow, visible: on);

    final colors = s.light.colors;
    final fanGrow = on ? ((_t - 0.6) / 0.6).clamp(0.0, 1.0) : 0.0;
    final screenX = _entry.x + _screenDistance - 0.02;
    for (var i = 0; i < colors.length; i++) {
      // Yelpazenin ortası +x; her renk ortalamadan sapması kadar döner.
      final angle =
          (deviationDeg(colors[i]) - _meanDeviation) * _spreadGain * pi / 180;
      final end = s.secondPrism
          ? _q
          : (_entry.clone()..add(_dir(angle)..scale((screenX - _entry.x) / cos(angle))));
      _placeBeam(_beams[i], _entry, end, fanGrow, visible: on, thickness: 0.012);
      final spot = _spots[i];
      spot.visible = on && fanGrow >= 1 && !s.secondPrism;
      spot.position.setValues(screenX, end.y, end.z);
      spot.scale.setValues(0.01, 0.12, colors.length == 1 ? 0.12 : 0.075);
    }
    if (s.secondPrism) {
      // Görsel sadeleştirme: birleşen ışık doğrudan perdeye gider.
      final end = three.Vector3(screenX, _q.y, _q.z);
      final outGrow = on ? ((_t - 1.2) / 0.5).clamp(0.0, 1.0) : 0.0;
      _placeBeam(_beams.last, _q, end, outGrow, visible: on);
      _spots.last
        ..visible = on && outGrow >= 1
        ..position.setFrom(end)
        ..scale.setValues(0.01, 0.14, 0.14);
    }
  }

  /// [a]'dan [b]'ye uzanan ince huzme; [grow] 0-1 arası uzunluk oranı.
  void _placeBeam(
    three.Mesh beam,
    three.Vector3 a,
    three.Vector3 b,
    double grow, {
    required bool visible,
    double thickness = 0.02,
  }) {
    beam.visible = visible && grow > 0;
    if (!beam.visible) return;
    final dx = b.x - a.x, dz = b.z - a.z;
    final len = sqrt(dx * dx + dz * dz) * grow;
    final angle = atan2(-dz, dx);
    beam.scale.setValues(max(0.001, len), thickness, thickness);
    beam.rotation.y = angle;
    beam.position.setValues(
      a.x + cos(angle) * len / 2,
      a.y,
      a.z - sin(angle) * len / 2,
    );
  }

  void _animateCarts(NewtonScene s) {
    final lanes = [s.laneA, s.laneB];
    for (var i = 0; i < _carts.length; i++) {
      final lane = lanes[i];
      if (lane == null) continue;
      final x = s.run > 0 ? cartPositionAt(lane, s.push, _t) : 0.0;
      final cart = _carts[i];
      cart.holder.position.x = _trackStart + 0.36 + x;
      for (final w in cart.wheels) {
        w.rotation.z = -x / 0.08;
      }
    }
    // Tokmak ilk 0,15 saniyede ileri fırlar, sonra yavaşça geri çekilir.
    final kick = s.run > 0
        ? (_t < 0.15 ? _t / 0.15 : max(0.0, 1 - (_t - 0.15) / 0.8)) * 0.2
        : 0.0;
    _plungerA?.position.x = kick;
    _plungerB?.position.x = kick;
  }

  // ─────────────────────────── Kamera ───────────────────────────

  @override
  LabCameraShot get cameraShot => switch (_s.station) {
    NewtonStation.fall => (
      look: three.Vector3(_fallX, 2.9, 0),
      offset: three.Vector3(0, 1.2, 10.5),
    ),
    NewtonStation.prism => (
      look: three.Vector3(_prismX + 0.2, 1.15, 0),
      offset: three.Vector3(0, 1.7, 3.6),
    ),
    NewtonStation.cart => (
      look: three.Vector3(_cartX, 0.2, 0),
      offset: three.Vector3(0, 5.2, 8.6),
    ),
  };
}

class _Faller {
  _Faller(this.node, this.object, this.height, this.x);

  final three.Object3D node;
  final FallingObject object;
  final double height;
  final double x;
}

class _CartNodes {
  _CartNodes(this.holder, this.wheels);

  final three.Object3D holder;
  final List<three.Object3D> wheels;
  final List<three.Object3D> boxes = [];
}
