import 'dart:math';

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../../models/galileo/galileo_scene.dart';
import '../../models/galileo/jupiter.dart';
import '../../models/galileo/solar.dart';
import '../../models/galileo/telescope.dart';
import '../glb_model_library.dart';
import '../science_lab/lab_3d_state.dart';

/// Galileo'nun gözlemevinin 3B görünümü. Modeller Blender'da üretilmiştir
/// (`assets/models/galileo.glb`, üretici `tool/blender/build_galileo.py`);
/// gezegenler, uydular ve yörüngeler kodla kurulan basit kürelerdir.
///
/// Görünüm [GalileoScene]'e doğru ilerler: tüp kayar, geceler ve günler akar
/// (büyük farklarda hızlanarak). Göz merceği / teleskop şeridi / Venüs
/// kutuları Flutter katmanıdır (`GalileoSceneView`), 2B yedekle ortaktır.
class GalileoLab3DView extends StatefulWidget {
  const GalileoLab3DView({super.key, required this.scene});

  final GalileoScene scene;

  static final models = GlbModelLibrary('galileo.glb');

  @override
  State<GalileoLab3DView> createState() => _GalileoLab3DViewState();
}

const double _balconyX = 0;
const double _jupiterX = 45;
const double _solarX = 90;
const double _spaceY = 3;

/// Uydu yörüngelerinin ekrandaki yarıçapı: gerçek oran korunur ama sıkıştırılır
/// (Kallisto 26 Jüpiter yarıçapı uzakta; olduğu gibi çizilse ekrana sığmaz).
double _moonOrbit(JupiterMoon m) => 2.2 + m.distance * 0.42;

/// Gezegen yörüngelerinin ekrandaki yarıçapı (karekökle sıkıştırılmış).
double _planetOrbit(Planet p) => 3.2 * sqrt(p.orbitAu) + 0.8;

class _GalileoLab3DViewState extends Lab3DState<GalileoLab3DView> {
  GlbModelLibrary get _lib => GalileoLab3DView.models;

  @override
  int get background => 0x0B1026;

  three.Object3D? _drawTube;
  three.Object3D? _skyTarget;
  SkyTarget? _skyTargetKind;
  three.Object3D? _stars;

  final Map<String, three.Object3D> _moons = {};
  final Map<String, three.Object3D> _planets = {};
  three.Mesh? _moonMarker;
  final List<three.Mesh> _planetMarkers = [];
  three.Mesh? _sightLine;

  double _shownTube = 85;
  double _shownNights = 0;
  double _shownDay = 0;

  GalileoScene get _s => widget.scene;

  @override
  void didUpdateWidget(GalileoLab3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) markDirty();
  }

  three.Object3D _model(String id, {int color = 0x9E9E9E, double size = 0.3}) =>
      model(_lib, id, fallbackColor: color, size: size);

  three.Mesh _sphere(int color, double r, {bool glow = false}) =>
      three.Mesh(three.SphereGeometry(r, 20, 14), material(color, glow: glow));

  three.Mesh _ring(double radius, int color, {double tube = 0.02}) {
    final ring = three.Mesh(
      three.TorusGeometry(radius, tube, 6, 96),
      material(color, glow: true),
    );
    ring.rotation.x = pi / 2; // yatay düzlemde
    return ring;
  }

  // ─────────────────────────── Kurulum ───────────────────────────

  @override
  Future<void> buildWorld(three.Scene scene) async {
    await _lib.preload();
    _stars = three.Object3D();
    final starMat = material(0xFFFFFF, glow: true);
    final rng = Random(7);
    for (var i = 0; i < 260; i++) {
      // Kameranın çevresinde bir kabuk (uzak düzlemin içinde kalsın).
      final u = rng.nextDouble() * 2 - 1;
      final a = rng.nextDouble() * 2 * pi;
      final r = 55.0;
      final s = sqrt(1 - u * u);
      final star = three.Mesh(unitBox, starMat)
        ..position.setValues(r * s * cos(a), r * u.abs() + 2, r * s * sin(a))
        ..scale.setValues(0.12, 0.12, 0.12);
      _stars!.add(star);
    }
    scene.add(_stars!);

    _buildBalcony(scene);
    _buildJupiterSystem(scene);
    _buildSolarSystem(scene);
  }

  void _buildBalcony(three.Scene scene) {
    scene.add(_model('galileo_balcony', color: 0xD8CBB3, size: 0.1)
      ..position.setValues(_balconyX, 0, 0));
    scene.add(_model('galileo_desk', color: 0x8D5A34, size: 0.7)
      ..position.setValues(_balconyX - 2.2, 0, 0.3)
      ..rotation.y = 0.3);
    scene.add(_model('galileo_figure', color: 0x1F1F24, size: 0.5)
      ..position.setValues(_balconyX - 0.9, 0, 0.5)
      ..rotation.y = -0.9);
    final telescope = _model('galileo_telescope', color: 0x8B3A2B, size: 0.4)
      ..position.setValues(_balconyX + 0.3, 0, 0.1);
    scene.add(telescope);
    _drawTube = GlbModelLibrary.find(telescope, 'DrawTube');
  }

  void _buildJupiterSystem(three.Scene scene) {
    final jupiter = _model('galileo_jupiter', color: 0xD7A86E, size: 2)
      ..position.setValues(_jupiterX, _spaceY, 0)
      ..scale.setValues(1.4, 1.4, 1.4);
    scene.add(jupiter);
    for (final m in jupiterMoons) {
      scene.add(_ring(_moonOrbit(m), 0x33415E)
        ..position.setValues(_jupiterX, _spaceY, 0));
      final moon = _sphere(m.color, 0.32);
      scene.add(moon);
      _moons[m.id] = moon;
    }
    _moonMarker = _ring(0.6, 0xFFEB3B, tube: 0.05)..visible = false;
    scene.add(_moonMarker!);
    // Dünya yönü (+z): "buradan bakıyoruz" oku gibi soluk bir şerit.
    scene.add(box(0x1E3A5F, 0.08, 0.02, 12, opacity: 0.6)
      ..position.setValues(_jupiterX, _spaceY - 0.02, 8));
  }

  void _buildSolarSystem(three.Scene scene) {
    scene.add(_sphere(0xFFD54F, 1.1, glow: true)
      ..position.setValues(_solarX, _spaceY, 0));
    for (final p in planets) {
      scene.add(_ring(_planetOrbit(p), 0x33415E)
        ..position.setValues(_solarX, _spaceY, 0));
      final three.Object3D node;
      if (p.id == 'jupiter') {
        node = _model('galileo_jupiter', color: p.color, size: 1)
          ..scale.setValues(0.55, 0.55, 0.55);
      } else {
        node = _sphere(p.color, switch (p.id) {
          'mercury' => 0.16,
          'venus' => 0.26,
          'earth' => 0.28,
          _ => 0.21,
        });
      }
      scene.add(node);
      _planets[p.id] = node;
    }
    for (var i = 0; i < 3; i++) {
      final marker = _ring(0.5, 0xFFEB3B, tube: 0.04)..visible = false;
      scene.add(marker);
      _planetMarkers.add(marker);
    }
    _sightLine = three.Mesh(unitBox, material(0x80DEEA, glow: true))..visible = false;
    scene.add(_sightLine!);
  }

  // ─────────────────────────── Eşleme ───────────────────────────

  @override
  void syncWorld() {
    final s = _s;
    if (s.target != _skyTargetKind) {
      _skyTargetKind = s.target;
      if (_skyTarget != null) threeJs.scene.remove(_skyTarget!);
      // Hedef, teleskobun baktığı yönde gökyüzünde.
      final node = switch (s.target) {
        SkyTarget.jupiter => _model('galileo_jupiter', color: 0xD7A86E, size: 1),
        SkyTarget.moon => _sphere(0xE0E0E0, 1.0),
        SkyTarget.venus => _sphere(0xFFF3C4, 0.6),
      };
      final elev = 25 * pi / 180;
      node.position.setValues(
        _balconyX + 0.3 + 30 * cos(elev),
        1.24 + 30 * sin(elev),
        0.1,
      );
      threeJs.scene.add(node);
      _skyTarget = node;
      isolate(node);
    }
  }

  // ─────────────────────────── Kare ───────────────────────────

  static double _approach(double shown, double target, double dt, double minRate) {
    final diff = target - shown;
    final rate = max(minRate, diff.abs() * 1.5);
    final step = rate * dt;
    return diff.abs() <= step ? target : shown + step * diff.sign;
  }

  @override
  void animateWorld(double dt) {
    final s = _s;
    _stars?.position.setValues(
      switch (s.station) {
        GalileoStation.telescope => _balconyX,
        GalileoStation.jupiter => _jupiterX,
        GalileoStation.solar => _solarX,
      },
      0,
      0,
    );

    // Tüp: 40…125 cm → iç tüp 0…0,5 m dışarı.
    _shownTube = _approach(_shownTube, s.tubeCm, dt, 30);
    _drawTube?.position.x =
        -((_shownTube - tubeMinCm) / (tubeMaxCm - tubeMinCm)) * 0.5;
    _skyTarget?.rotation.y += dt * 0.1;

    _shownNights = _approach(_shownNights, s.nights, dt, 1.2);
    for (final m in jupiterMoons) {
      final node = _moons[m.id]!;
      final a = m.angleAt(_shownNights);
      final r = _moonOrbit(m);
      node.position.setValues(
        _jupiterX + r * cos(a),
        _spaceY,
        r * sin(a),
      );
    }
    final hl = s.highlightMoon;
    _moonMarker!.visible = hl != null;
    if (hl != null) _moonMarker!.position.setFrom(_moons[hl.id]!.position);

    _shownDay = _approach(_shownDay, s.day, dt, 45);
    for (final p in planets) {
      final a = p.id == 'venus' ? s.venusAngleAt(_shownDay) : p.angleAt(_shownDay);
      final r = _planetOrbit(p);
      _planets[p.id]!.position.setValues(
        _solarX + r * cos(a),
        _spaceY,
        -r * sin(a),
      );
    }
    for (var i = 0; i < _planetMarkers.length; i++) {
      final marker = _planetMarkers[i];
      final id = i < s.highlightPlanetIds.length ? s.highlightPlanetIds[i] : null;
      marker.visible = id != null;
      if (id != null) marker.position.setFrom(_planets[id]!.position);
    }
    // Venüs sorusunda Dünya'dan Venüs'e bakış çizgisi.
    final sight = s.venusOffsetDeg != null;
    _sightLine!.visible = sight;
    if (sight) {
      final e = _planets['earth']!.position;
      final v = _planets['venus']!.position;
      final dx = v.x - e.x, dz = v.z - e.z;
      final len = sqrt(dx * dx + dz * dz);
      _sightLine!
        ..position.setValues((e.x + v.x) / 2, _spaceY, (e.z + v.z) / 2)
        ..scale.setValues(len, 0.03, 0.03)
        ..rotation.y = atan2(-dz, dx);
    }
  }

  // ─────────────────────────── Kamera ───────────────────────────

  @override
  LabCameraShot get cameraShot => switch (_s.station) {
    GalileoStation.telescope => (
      look: three.Vector3(_balconyX - 0.3, 1.3, 0.2),
      offset: three.Vector3(0.6, 1.1, 5.4),
    ),
    GalileoStation.jupiter => (
      look: three.Vector3(_jupiterX, _spaceY, 0),
      offset: three.Vector3(0, 11, 20),
    ),
    GalileoStation.solar => (
      look: three.Vector3(_solarX, _spaceY, 0),
      offset: three.Vector3(0, 12, 8.5),
    ),
  };
}
