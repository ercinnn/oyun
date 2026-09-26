import 'dart:math';

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../../models/archimedes/archimedes_scene.dart';
import '../../models/archimedes/archimedes_screw.dart';
import '../../models/archimedes/boat.dart';
import '../../models/archimedes/buoyancy.dart';
import '../glb_model_library.dart';
import '../science_lab/lab_3d_state.dart';

/// Arşimet atölyesinin gerçek 3B görünümü (three_js). Modeller Blender'da
/// üretilmiştir (`assets/models/archimedes.glb`, üretici
/// `tool/blender/build_archimedes.py`); yüklenemezse ilkel şekillere düşülür.
///
/// Görünüm **durumsuzdur**: her karede [scene]'e doğru yumuşakça ilerler
/// (cisim düşer ve salınır, su yükselir, gemi gömülür, vida döner). Mantık
/// hiçbir animasyonu beklemez; 2B yedeği `ArchimedesLab2DView` aynı veriyi
/// çizer.
///
/// Üç istasyon dünyada yan yana durur; istasyon değişince kamera kayar.
/// Kamera yönü sabittir, yalnızca yakınlaştırma var (oda görünümü gibi).
class ArchimedesLab3DView extends StatefulWidget {
  const ArchimedesLab3DView({super.key, required this.scene});

  final ArchimedesScene scene;

  static final models = GlbModelLibrary('archimedes.glb');

  @override
  State<ArchimedesLab3DView> createState() => _ArchimedesLab3DViewState();
}

// Dünya yerleşimi. Su kabı istasyonunda 1 birim = 10 cm (kap 2 birim = 20 cm),
// sahnede masanın üstüne [_tankScale] ile küçültülerek konur.
const double _tankStationX = 0;
const double _boatStationX = 14;
const double _screwStationX = 28;
const double _tableTop = 0.9;
const double _tankScale = 0.55;
const double _tankInner = 1.6;
const double _tankHeightUnits = 2.0;

/// Blender'daki gövde yükseklikleri (`BOAT_HULL_HEIGHT`) ile aynı olmalı.
const Map<String, double> _boatHullHeight = {
  'rowboat': 0.35,
  'raft': 0.22,
  'sailboat': 0.45,
};

/// Vidanın alt ucu (nehrin içinde) ve tarlanın sol kenarına uzaklığı; 2B
/// görünümdeki yerleşimle aynı (`pivot + 2.95 m`).
const double _screwPivotX = _screwStationX - 2.2;
const double _screwPivotY = -0.3;
const double _fieldGap = 2.95;

class _ArchimedesLab3DViewState extends Lab3DState<ArchimedesLab3DView> {
  // Kalıcı düğümler.
  three.Object3D? _tankRoot;
  final List<_TankNodes> _tanks = [];
  final Map<String, _ObjectNode> _objects = {};
  String _tankSignature = '';

  three.Object3D? _boatPivot;
  three.Object3D? _boatModel;
  String? _boatId;
  final List<three.Object3D> _crates = [];
  double _boatY = 0;
  double _boatTilt = 0;

  three.Object3D? _screwPivot;
  three.Object3D? _screwRotor;
  three.Object3D? _sprouts;
  final List<three.Mesh> _drops = [];
  double _shownTurns = 0;
  double _shownLitres = 0;
  double _shownAngle = 30;

  @override
  void didUpdateWidget(ArchimedesLab3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) markDirty();
  }

  @override
  Future<void> buildWorld(three.Scene scene) async {
    await ArchimedesLab3DView.models.preload();
    _buildTankStation(scene);
    _buildBoatStation(scene);
    _buildScrewStation(scene);
  }

  three.Object3D _model(String id, {int fallbackColor = 0x9E9E9E, double size = 0.4}) =>
      model(ArchimedesLab3DView.models, id, fallbackColor: fallbackColor, size: size);

  three.Mesh _box(int color, double w, double h, double d, {double opacity = 1}) =>
      box(color, w, h, d, opacity: opacity);

  void _buildTankStation(three.Scene scene) {
    final lab = _model('arch_lab', fallbackColor: 0xE0DCD0, size: 0.01)
      ..position.setValues(_tankStationX, 0, 0);
    scene.add(lab);
    final archimedes = _model('arch_archimedes', fallbackColor: 0xF1ECE2)
      ..position.setValues(_tankStationX - 2.9, 0, 0.9);
    archimedes.rotation.y = 0.35;
    scene.add(archimedes);
    _tankRoot = three.Object3D()
      ..position.setValues(_tankStationX, _tableTop, 0.2)
      ..scale.setValues(_tankScale, _tankScale, _tankScale);
    scene.add(_tankRoot!);
  }

  void _buildBoatStation(three.Scene scene) {
    // Havuz: kum kenarlı, saydam su.
    scene.add(
      _box(0xE6CFA0, 9, 0.4, 7)..position.setValues(_boatStationX, -0.9, 0),
    );
    scene.add(
      _box(0x1E88E5, 8, 0.1, 6)..position.setValues(_boatStationX, -0.72, 0),
    );
    scene.add(
      _box(0x4FC3F7, 8, 0.7, 6, opacity: 0.6)
        ..position.setValues(_boatStationX, -0.35, 0),
    );
    _boatPivot = three.Object3D()..position.setValues(_boatStationX, 0, 0);
    scene.add(_boatPivot!);
  }

  void _buildScrewStation(three.Scene scene) {
    // Nehir (saydam) ve kıyı.
    scene.add(
      _box(0x8D6E63, 12, 0.3, 6)..position.setValues(_screwStationX, -0.85, 0),
    );
    scene.add(
      _box(0x4FC3F7, 8, 0.7, 5, opacity: 0.65)
        ..position.setValues(_screwStationX - 2, -0.35, 0),
    );
    final field = _model('arch_field', fallbackColor: 0x7CB342)
      ..position.setValues(_screwPivotX + _fieldGap + 1.2, 0, 0);
    scene.add(field);
    _sprouts = GlbModelLibrary.find(field, 'Sprouts');

    _screwPivot = three.Object3D()
      ..position.setValues(_screwPivotX, _screwPivotY, 0);
    scene.add(_screwPivot!);
    final screw = _model('arch_screw', fallbackColor: 0x7A4E2A);
    _screwPivot!.add(screw);
    _screwRotor = GlbModelLibrary.find(screw, 'ScrewRotor');
    final dropMat = material(0x0288D1, roughness: 0.3);
    final dropGeo = three.SphereGeometry(0.07, 8, 6);
    for (var i = 0; i < 12; i++) {
      final d = three.Mesh(dropGeo, dropMat);
      _screwPivot!.add(d);
      _drops.add(d);
    }
  }

  // ─────────────────────────── Sahneyle eşleme ───────────────────────────

  /// Sahne verisinin yapısal değişimlerini düğümlere uygular (kap sayısı,
  /// gemi türü, sandık sayısı). Konumlar [_onFrame]'de yumuşakça ilerler.
  @override
  void syncWorld() {
    final s = widget.scene;
    _syncTanks(s);
    _syncBoat(s);
  }

  void _syncTanks(ArchimedesScene s) {
    final root = _tankRoot;
    if (root == null) return;
    final signature = [
      for (final t in s.tanks) '${t.brimFull}',
    ].join(',');
    if (signature != _tankSignature) {
      _tankSignature = signature;
      for (final t in _tanks) {
        root.remove(t.root);
      }
      _tanks.clear();
      for (final node in _objects.values) {
        node.node.parent?.remove(node.node);
      }
      _objects.clear();
      final n = s.tanks.length;
      for (var i = 0; i < n; i++) {
        final x = n == 1 ? 0.0 : (i - (n - 1) / 2) * 2.6;
        _tanks.add(_makeTank(root, x, s.tanks[i].brimFull));
      }
    }

    // Cisim düğümleri: kimlikle eşlenir, böylece tutulan cisim bırakılınca
    // aynı düğüm aşağı düşer.
    final wanted = <String>{};
    for (var i = 0; i < s.tanks.length && i < _tanks.length; i++) {
      final tank = s.tanks[i];
      final all = [...tank.dropped, if (tank.held != null) tank.held!];
      for (final o in all) {
        final key = '$i/${o.id}';
        wanted.add(key);
        _objects.putIfAbsent(key, () {
          final model = _model(o.modelId, fallbackColor: 0xFF7043, size: 0.35);
          final holder = three.Object3D()..add(model);
          _tanks[i].root.add(holder);
          final box = three.BoundingBox().setFromObject(model);
          final height = max(0.05, box.max.y - box.min.y);
          holder.position.setValues(0, _tankHeightUnits + 0.5, 0);
          return _ObjectNode(holder, height, -box.min.y);
        });
      }
    }
    for (final key in _objects.keys.toList()) {
      if (!wanted.contains(key)) {
        final node = _objects.remove(key)!;
        node.node.parent?.remove(node.node);
      }
    }
    isolate(root);
  }

  _TankNodes _makeTank(three.Object3D root, double x, bool brimFull) {
    final group = three.Object3D()..position.setValues(x, 0, 0);
    root.add(group);
    group.add(_model('arch_tank', fallbackColor: 0x455A64, size: 0.1));
    final water = _box(0x4FC3F7, _tankInner, 1, _tankInner, opacity: 0.55);
    group.add(water);
    three.Mesh? beakerWater;
    if (brimFull) {
      // Ölçü kabı tankın önünde, oluğun altında (ön yüz = +z).
      const bx = 0.55, bz = _tankInner / 2 + 0.75;
      group.add(
        _model('arch_beaker', fallbackColor: 0xB3E5FC, size: 0.1)
          ..position.setValues(bx, 0, bz),
      );
      beakerWater = three.Mesh(
        three.CylinderGeometry(0.3, 0.3, 1, 18),
        material(0x29B6F6, roughness: 0.3),
      )..position.setValues(bx, 0, bz);
      group.add(beakerWater);
    }
    return _TankNodes(group, water, beakerWater);
  }

  void _syncBoat(ArchimedesScene s) {
    final pivot = _boatPivot;
    final boat = s.boat;
    if (pivot == null) return;
    if (boat?.id != _boatId) {
      if (_boatModel != null) pivot.remove(_boatModel!);
      for (final c in _crates) {
        pivot.remove(c);
      }
      _crates.clear();
      _boatId = boat?.id;
      _boatModel = boat == null
          ? null
          : _model('arch_boat_${boat.id}', fallbackColor: 0xB07A45, size: 1);
      if (_boatModel != null) pivot.add(_boatModel!);
      _boatTilt = 0;
      _boatY = boat == null ? 0 : -boat.draftRatio(0) * _hull(boat);
    }
    if (boat == null) return;
    while (_crates.length < s.crates) {
      final i = _crates.length;
      final crate = _model('arch_crate', fallbackColor: 0xC68A4E, size: 0.3);
      final col = i % 3;
      final row = (i ~/ 3) % 2;
      final layer = i ~/ 6;
      crate.position.setValues(
        -0.35 + 0.35 * col,
        0.07 + layer * 0.31 + 0.4, // biraz yukarıdan konur, [_onFrame] indirir
        row == 0 ? -0.17 : 0.17,
      );
      pivot.add(crate);
      _crates.add(crate);
    }
    while (_crates.length > s.crates) {
      pivot.remove(_crates.removeLast());
    }
    isolate(pivot);
  }

  double _hull(BoatSpec boat) => _boatHullHeight[boat.id] ?? 0.35;

  // ─────────────────────────── Kare ───────────────────────────

  @override
  void animateWorld(double dt) {
    final s = widget.scene;
    _animateTanks(s, dt);
    _animateBoat(s, dt);
    _animateScrew(s, dt);
  }

  void _animateTanks(ArchimedesScene s, double dt) {
    for (var i = 0; i < s.tanks.length && i < _tanks.length; i++) {
      final tank = s.tanks[i];
      final nodes = _tanks[i];
      // Su seviyesi (birim = 10 cm).
      final level = tank.waterLevelCm / 10;
      nodes.level += (level - nodes.level) * min(1.0, dt * 2.5);
      nodes.water.scale.y = max(0.001, nodes.level);
      nodes.water.position.y = nodes.level / 2;

      final beakerWater = nodes.beakerWater;
      if (beakerWater != null) {
        // 80 mL kabı doldurur (2B görünümle aynı ölçek).
        final target = (tank.overflowMl / 80).clamp(0.0, 1.0) * 0.85;
        nodes.overflow += (target - nodes.overflow) * min(1.0, dt * 1.5);
        beakerWater.scale.y = max(0.001, nodes.overflow);
        beakerWater.position.y = 0.04 + nodes.overflow / 2;
      }

      final slots = const [(-0.4, 0.35), (0.4, -0.35), (0.4, 0.35), (-0.4, -0.35)];
      for (var k = 0; k < tank.dropped.length; k++) {
        final o = tank.dropped[k];
        final node = _objects['$i/${o.id}'];
        if (node == null) continue;
        final (sx, sz) = tank.dropped.length == 1 ? (0.0, 0.0) : slots[k % 4];
        // Hedef: yüzen cisim batma oranı kadar suya gömülür, batan dibe iner.
        final targetBottom = o.floats
            ? nodes.level - node.height * o.submergedFraction
            : 0.0;
        final target = targetBottom + node.baseOffset;
        final p = node.node.position;
        p.x += (sx - p.x) * min(1.0, dt * 3);
        p.z += (sz - p.z) * min(1.0, dt * 3);
        // Yerçekimi benzeri düşüş, suya girince yavaşlar; yüzen cisim salınır.
        final inWater = p.y - node.baseOffset < nodes.level;
        node.velocity -= (inWater ? 4 : 18) * dt;
        if (inWater) {
          node.velocity += (target - p.y) * 12 * dt;
          node.velocity *= pow(0.12, dt).toDouble();
        }
        p.y += node.velocity * dt;
        if (p.y < target && !o.floats) {
          p.y = target;
          node.velocity = 0;
        }
        node.node.rotation.y += (0 - node.node.rotation.y) * min(1.0, dt * 2);
      }
      final held = tank.held;
      if (held != null) {
        final node = _objects['$i/${held.id}'];
        if (node != null) {
          node.velocity = 0;
          final p = node.node.position;
          final hover = _tankHeightUnits + 0.45 + node.baseOffset +
              sin(clock * 2.2) * 0.06;
          p.x += (0 - p.x) * min(1.0, dt * 4);
          p.z += (0 - p.z) * min(1.0, dt * 4);
          p.y += (hover - p.y) * min(1.0, dt * 4);
          node.node.rotation.y += dt * 0.8;
        }
      }
    }
  }

  void _animateBoat(ArchimedesScene s, double dt) {
    final boat = s.boat;
    final pivot = _boatPivot;
    if (boat == null || pivot == null || _boatModel == null) return;
    final hull = _hull(boat);
    final sinking = boat.sinks(s.crates);
    final target = sinking ? -(hull + 0.9) : -boat.draftRatio(s.crates) * hull;
    // Batarken yavaş, yük değişince hızlıca oturur.
    _boatY += (target - _boatY) * min(1.0, dt * (sinking ? 0.8 : 3));
    _boatTilt += ((sinking ? 0.28 : 0) - _boatTilt) * min(1.0, dt * 1.2);
    final bob = sinking ? 0.0 : sin(clock * 1.6) * 0.02;
    _boatModel!.position.y = _boatY + bob;
    _boatModel!.rotation.z = _boatTilt + sin(clock * 1.1) * 0.015;
    for (var i = 0; i < _crates.length; i++) {
      final c = _crates[i];
      final layer = i ~/ 6;
      final deck = _boatY + bob + 0.07 + layer * 0.31;
      c.position.y += (deck - c.position.y) * min(1.0, dt * 6);
      c.rotation.z = _boatModel!.rotation.z;
    }
  }

  void _animateScrew(ArchimedesScene s, double dt) {
    final pivot = _screwPivot;
    if (pivot == null) return;
    _shownAngle += (s.screwAngle - _shownAngle) * min(1.0, dt * 5);
    pivot.rotation.z = _shownAngle * pi / 180;
    // Tur: en çok 1,6 tur/sn — kol hızlı çevrilse de dönüş görülsün.
    final diff = s.screwTurns - _shownTurns;
    final step = 1.6 * dt;
    _shownTurns += diff.abs() <= step ? diff : step * diff.sign;
    _screwRotor?.rotation.x = -_shownTurns * 2 * pi;
    _shownLitres += (s.fieldLitres - _shownLitres) * min(1.0, dt * 1.2);
    final grow = 0.15 + 0.85 * (_shownLitres / fieldNeedLitres).clamp(0.0, 1.0);
    _sprouts?.scale.setValues(1, grow, 1);

    // Ceplerdeki su: vida döndükçe eksen boyunca yukarı kayar.
    final fill = screwPocketFill(s.screwAngle);
    for (var i = 0; i < _drops.length; i++) {
      final u = ((i + _shownTurns % 1) / _drops.length);
      final d = _drops[i];
      d.visible = fill > 0 && u < 0.98;
      d.position.setValues(0.1 + u * (screwLengthM - 0.2), -0.1, 0);
      final r = 0.6 + fill;
      d.scale.setValues(r, r, r);
    }
  }

  // ─────────────────────────── Kamera ───────────────────────────

  @override
  LabCameraShot get cameraShot {
    final (lx, ly, lz, ox, oy, oz) = switch (widget.scene.station) {
      ArchimedesStation.tank => (_tankStationX - 0.6, 1.5, 0.3, 0.6, 1.9, 5.2),
      ArchimedesStation.boat => (_boatStationX, 0.3, 0.0, 0.0, 3.6, 7.2),
      ArchimedesStation.screw => (_screwStationX + 0.2, 0.7, 0.0, 0.0, 2.4, 8.2),
    };
    return (look: three.Vector3(lx, ly, lz), offset: three.Vector3(ox, oy, oz));
  }
}

class _TankNodes {
  _TankNodes(this.root, this.water, this.beakerWater);

  final three.Object3D root;
  final three.Mesh water;
  final three.Mesh? beakerWater;
  double level = tankStartWaterCm / 10;
  double overflow = 0;
}

class _ObjectNode {
  _ObjectNode(this.node, this.height, this.baseOffset);

  final three.Object3D node;

  /// Modelin boyu (birim) ve tabanını y = 0'a getiren kaydırma.
  final double height;
  final double baseOffset;
  double velocity = 0;
}
