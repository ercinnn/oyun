import 'dart:math';

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../../models/einstein/einstein_scene.dart';
import '../../models/einstein/mass_energy.dart';
import '../../models/einstein/spacetime.dart';
import '../../models/einstein/time_dilation.dart';
import '../glb_model_library.dart';
import '../science_lab/lab_3d_state.dart';

/// Einstein'ın laboratuvarının 3B görünümü. Modeller Blender'da üretilmiştir
/// (`assets/models/einstein.glb`, üretici `tool/blender/build_einstein.py`);
/// uzay-zaman örtüsü kodla, kütleye göre çöken bir çizgi ızgarasıdır.
///
/// Bilye, modelin hesapladığı yolu (`simulateMarble`) izler ve arkasında iz
/// bırakır. Işık saatinde foton Dünya'da 1 saniyede, gemide γ saniyede bir
/// tıklar. Şehirde, kütlenin enerjisi kadar ev sırayla yanar.
class EinsteinLab3DView extends StatefulWidget {
  const EinsteinLab3DView({super.key, required this.scene});

  final EinsteinScene scene;

  static final models = GlbModelLibrary('einstein.glb');

  @override
  State<EinsteinLab3DView> createState() => _EinsteinLab3DViewState();
}

const double _sheetX = 0;
const double _clockX = 30;
const double _energyX = 60;

/// Benzetim birimini dünyaya çevirir (kaçış sınırı 16 → örtü kenarı 6 m).
const double _simToWorld = 6 / escapeRadius;
const double _depthScale = 0.6;

/// Bilye benzetimi saniyede bu kadar benzetim birimi oynatılır.
const double _playback = 12;

class _EinsteinLab3DViewState extends Lab3DState<EinsteinLab3DView> {
  GlbModelLibrary get _lib => EinsteinLab3DView.models;

  @override
  int get background => 0x0A0E1F;

  EinsteinScene get _s => widget.scene;

  // Örtü.
  three.LineSegments? _grid;
  three.Mesh? _surface;
  three.Mesh? _center;
  three.Mesh? _marble;
  final List<three.Mesh> _trail = [];
  CentralMass? _gridFor;
  MarbleRun? _run;
  String _runKey = '';

  // Saat.
  three.Object3D? _ship;
  three.Mesh? _earthPhoton;
  three.Mesh? _shipPhoton;
  double _shipX = 0;
  double _earthPhase = 0;
  double _shipPhase = 0;

  // Enerji.
  final List<three.Mesh> _windows = [];
  three.Mesh? _tiny;
  final _tinyMat = three.MeshBasicMaterial.fromMap({'color': 0xFFF59D});

  // Deney saati.
  int _lastRun = -1;
  EinsteinStation? _lastStation;
  double _t = 0;

  @override
  void didUpdateWidget(EinsteinLab3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) markDirty();
  }

  three.Object3D _model(String id, {int color = 0x9E9E9E, double size = 0.3}) =>
      model(_lib, id, fallbackColor: color, size: size);

  three.Mesh _sphere(int color, double r, {bool glow = true}) =>
      three.Mesh(three.SphereGeometry(r, 20, 14), material(color, glow: glow));

  // ─────────────────────────── Kurulum ───────────────────────────

  @override
  Future<void> buildWorld(three.Scene scene) async {
    await _lib.preload();
    // Yıldızlar (üç istasyonu da kapsayan geniş bir kabuk).
    final rng = Random(5);
    final starMat = material(0xFFFFFF, glow: true);
    for (var i = 0; i < 300; i++) {
      final x = -20 + rng.nextDouble() * 100;
      final y = 2 + rng.nextDouble() * 25;
      final z = -30 - rng.nextDouble() * 15;
      scene.add(three.Mesh(unitBox, starMat)
        ..position.setValues(x, y, z)
        ..scale.setValues(0.1, 0.1, 0.1));
    }

    scene.add(_model('einstein_frame', color: 0x37474F, size: 0.2)..position.setValues(_sheetX, 0, 0));
    _center = _sphere(0xFFB300, 1);
    scene.add(_center!);
    _marble = _sphere(0xE0E0E0, 0.14, glow: false);
    scene.add(_marble!);
    final trailMat = material(0x80DEEA, glow: true);
    for (var i = 0; i < 120; i++) {
      final dot = three.Mesh(unitBox, trailMat)
        ..scale.setValues(0.05, 0.05, 0.05)
        ..visible = false;
      scene.add(dot);
      _trail.add(dot);
    }
    scene.add(_model('einstein_board', color: 0x1B3B2A, size: 1)
      ..position.setValues(_sheetX - 3, -1.2, -7.2));
    scene.add(_model('einstein_figure', color: 0x78909C, size: 0.5)
      ..position.setValues(_sheetX - 5.3, -1.2, -6.4)
      ..rotation.y = 0.5);
    scene.add(box(0x1A2238, 20, 0.2, 18)..position.setValues(_sheetX, -1.3, 0));

    // Işık saati istasyonu.
    scene.add(box(0x263238, 4, 0.4, 3)..position.setValues(_clockX - 4, -0.2, 0));
    scene.add(_model('einstein_clock', color: 0x455A64, size: 0.4)
      ..position.setValues(_clockX - 4, 0, 0));
    _earthPhoton = _sphere(0xFFEB3B, 0.07);
    scene.add(_earthPhoton!);
    _ship = three.Object3D();
    _ship!.add(_model('einstein_ship', color: 0xECEFF1, size: 0.6));
    _ship!.add(_model('einstein_clock', color: 0x455A64, size: 0.4)
      ..position.setValues(0, 0.3, 0)
      ..scale.setValues(0.7, 0.7, 0.7));
    scene.add(_ship!);
    _shipPhoton = _sphere(0xFFEB3B, 0.06);
    scene.add(_shipPhoton!);
    scene.add(_model('einstein_figure', color: 0x78909C, size: 0.5)
      ..position.setValues(_clockX - 5.6, 0, 0.6)
      ..rotation.y = 0.4);

    // E=mc² istasyonu.
    scene.add(box(0x1A2238, 16, 0.2, 10)..position.setValues(_energyX, -0.1, 0));
    scene.add(_model('einstein_pedestal', color: 0xECEFF1, size: 0.5)
      ..position.setValues(_energyX - 3, 0, 0.5));
    _tiny = three.Mesh(three.SphereGeometry(1, 16, 12), _tinyMat)
      ..position.setValues(_energyX - 3, 1.1, 0.5);
    scene.add(_tiny!);
    scene.add(_model('einstein_campfire', color: 0x6D4C41, size: 0.3)
      ..position.setValues(_energyX - 5, 0, 1.5));
    scene.add(_model('einstein_board', color: 0x1B3B2A, size: 1)
      ..position.setValues(_energyX - 3.5, 0, -2.5));
    scene.add(_model('einstein_figure', color: 0x78909C, size: 0.5)
      ..position.setValues(_energyX - 5.2, 0, -1.6)
      ..rotation.y = 0.5);
    for (var i = 0; i < cityHouseCount; i++) {
      final house = _model('einstein_house', color: 0xF1E3C8, size: 0.3)
        ..position.setValues(_energyX - 0.5 + (i % 10) * 0.65, 0, -2.6 + (i ~/ 10) * 0.6);
      scene.add(house);
      house.traverse((o) {
        if (o is three.Mesh && o.name.split('.').first == 'window') _windows.add(o);
      });
    }
  }

  /// Örtü ızgarası: 25 × 25 çizgi, her biri 48 parçada kütlenin çukuruna göre
  /// eğilir.
  void _rebuildGrid(CentralMass c) {
    if (_grid != null) threeJs.scene.remove(_grid!);
    final pts = <double>[];
    double y(double x, double z) {
      final r = sqrt(x * x + z * z) / _simToWorld;
      return -sheetDepth(c, r) * _depthScale;
    }

    const half = 6.0;
    const lines = 25;
    const segs = 48;
    for (var i = 0; i < lines; i++) {
      final a = -half + 2 * half * i / (lines - 1);
      for (var k = 0; k < segs; k++) {
        final b0 = -half + 2 * half * k / segs;
        final b1 = -half + 2 * half * (k + 1) / segs;
        pts..addAll([a, y(a, b0), b0])..addAll([a, y(a, b1), b1]);
        pts..addAll([b0, y(b0, a), a])..addAll([b1, y(b1, a), a]);
      }
    }
    final geo = three.BufferGeometry()
      ..setAttributeFromString('position', three.Float32BufferAttribute.fromList(pts, 3));
    _grid = three.LineSegments(geo, three.LineBasicMaterial.fromMap({'color': 0x4DD0E1}));
    threeJs.scene.add(_grid!);

    // Çizgilerin hemen altında aynı biçimde çöken koyu yüzey: çukurun
    // derinliğini ışıkla da gösterir ve yatık bakışta 1 piksellik çizgilerin
    // kesik görünmesini örter.
    if (_surface != null) threeJs.scene.remove(_surface!);
    const n = 60;
    final verts = <double>[];
    for (var j = 0; j <= n; j++) {
      for (var i = 0; i <= n; i++) {
        final x = -half + 2 * half * i / n;
        final z = -half + 2 * half * j / n;
        verts.addAll([x, y(x, z) - 0.015, z]);
      }
    }
    final index = <int>[];
    for (var j = 0; j < n; j++) {
      for (var i = 0; i < n; i++) {
        final a = j * (n + 1) + i;
        index.addAll([a, a + n + 1, a + 1, a + 1, a + n + 1, a + n + 2]);
      }
    }
    final surfaceGeo = three.BufferGeometry()
      ..setAttributeFromString('position', three.Float32BufferAttribute.fromList(verts, 3))
      ..setIndex(index)
      ..computeVertexNormals();
    _surface = three.Mesh(
      surfaceGeo,
      three.MeshStandardMaterial.fromMap({
        'color': 0x16264D,
        'roughness': 0.85,
        'side': three.DoubleSide,
      }),
    );
    threeJs.scene.add(_surface!);

    final bottom = -sheetDepth(c, 0) * _depthScale;
    _center!
      ..material = material(c.color, glow: true)
      ..scale.setValues(c.radius, c.radius, c.radius)
      ..position.setValues(_sheetX, bottom + c.radius * 0.6, 0);
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
    if (s.center != _gridFor) {
      _gridFor = s.center;
      _rebuildGrid(s.center);
    }
    final key = '${s.center.name}/${s.speed.name}';
    if (key != _runKey) {
      _runKey = key;
      _run = s.marble;
    }
    // Kaidedeki minik kütle: boyu kütlenin log'uyla (0,0001 g → 1 g).
    final r = 0.04 + 0.03 * (log(s.grams * 10000) / ln10).clamp(0.0, 4.0);
    _tiny!.scale.setValues(r, r, r);
    isolate(threeJs.scene);
  }

  // ─────────────────────────── Kare ───────────────────────────

  @override
  void animateWorld(double dt) {
    final s = _s;
    if (s.run > 0) _t += dt;
    _animateMarble(s);
    _animateClocks(s, dt);
    _animateCity(s);
  }

  (double, double, double) _onSheet(double px, double py) {
    final r = sqrt(px * px + py * py);
    return (
      _sheetX + px * _simToWorld,
      -sheetDepth(_s.center, r) * _depthScale + 0.14,
      -py * _simToWorld,
    );
  }

  void _animateMarble(EinsteinScene s) {
    final run = _run;
    if (run == null) return;
    final idx = s.run > 0
        ? min(run.path.length - 1, (_t * _playback / run.dtPerPoint).floor())
        : 0;
    final (px, py) = run.path[idx];
    final (x, y, z) = _onSheet(px, py);
    _marble!.position.setValues(x, y, z);
    _marble!.visible = !(run.fate == MarbleFate.fallsIn && idx == run.path.length - 1);
    // İz: yolun o ana kadarki kısmından eşit aralıklı noktalar.
    for (var i = 0; i < _trail.length; i++) {
      final k = (i * run.path.length / _trail.length).floor();
      final dot = _trail[i];
      dot.visible = s.run > 0 && k <= idx;
      if (!dot.visible) continue;
      final (tx, ty, tz) = _onSheet(run.path[k].$1, run.path[k].$2);
      dot.position.setValues(tx, ty - 0.08, tz);
    }
  }

  void _animateClocks(EinsteinScene s, double dt) {
    final v = s.shipSpeed;
    final gamma = lorentzGamma(v);
    // Gemi sağda soldan sağa uçar, sona gelince başa döner.
    _shipX += v * 4 * dt;
    if (_shipX > 7) _shipX = -1;
    _ship!.position.setValues(_clockX + _shipX, 1.5, 0);
    // Foton: aşağı-yukarı (0 → 1 → 0) bir tık = 1 sn (Dünya), γ sn (gemi).
    _earthPhase = (_earthPhase + dt) % 1.0;
    _shipPhase = (_shipPhase + dt / gamma) % 1.0;
    double bounce(double p) => p < 0.5 ? p * 2 : 2 - p * 2;
    _earthPhoton!.position.setValues(_clockX - 4, 0.17 + bounce(_earthPhase) * 0.95, 0);
    _shipPhoton!.position.setValues(
      _clockX + _shipX,
      1.5 + 0.3 + (0.12 + bounce(_shipPhase) * 0.66),
      0,
    );
  }

  void _animateCity(EinsteinScene s) {
    // Yanan evler 2 saniyede sırayla artar.
    final target = s.run > 0 ? s.housesLit : 0;
    final lit = (target * (_t / 2).clamp(0.0, 1.0)).round();
    for (var i = 0; i < _windows.length; i++) {
      _windows[i].material = material(i < lit ? 0xFFE082 : 0x37474F, glow: i < lit);
    }
    final glow = s.run > 0 ? 0.6 + 0.4 * sin(clock * 6) : 0.3;
    _tinyMat.color.setRGB(1, 0.95 * glow + 0.05, 0.6 * glow);
  }

  // ─────────────────────────── Kamera ───────────────────────────

  @override
  LabCameraShot get cameraShot => switch (_s.station) {
    EinsteinStation.sheet => (
      look: three.Vector3(_sheetX, -0.8, 0.3),
      offset: three.Vector3(0, 10.5, 8.5),
    ),
    EinsteinStation.clock => (
      look: three.Vector3(_clockX, 1.0, 0),
      offset: three.Vector3(0, 1.8, 9.5),
    ),
    EinsteinStation.energy => (
      look: three.Vector3(_energyX + 0.9, 0.6, -0.8),
      offset: three.Vector3(0, 4.6, 9.6),
    ),
  };
}
