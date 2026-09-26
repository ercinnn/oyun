import 'dart:math';

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../../models/tesla/generator.dart';
import '../../models/tesla/tesla_scene.dart';
import '../../models/tesla/transmission.dart';
import '../glb_model_library.dart';
import '../science_lab/lab_3d_state.dart';

/// Tesla'nın laboratuvarının 3B görünümü. Modeller Blender'da üretilmiştir
/// (`assets/models/tesla.glb`, üretici `tool/blender/build_tesla.py`).
///
/// Jeneratör sürekli döner: bobinin açısından gerilim hesaplanır
/// (`peakVolts · sin θ`) ve ampul/LED'ler her karede ona göre yanar — akımın
/// yön değiştirmesi gözle görülür. Şehir hattında tellerin kızıllığı kaybolan
/// enerjiyle, yanan pencereler ulaşan enerjiyle orantılıdır. Tesla bobininde
/// kıvılcımlar çakar, lamba modeldeki parlaklıkla yanar.
class TeslaLab3DView extends StatefulWidget {
  const TeslaLab3DView({super.key, required this.scene});

  final TeslaScene scene;

  static final models = GlbModelLibrary('tesla.glb');

  @override
  State<TeslaLab3DView> createState() => _TeslaLab3DViewState();
}

const double _labX = 0;
const double _cityX = 32;
const double _coilX = 64;
const double _bench = 0.85;

/// Ev pencerelerinin sönük ve yanık renkleri.
const int _windowDark = 0x37474F;
const int _windowLit = 0xFFE082;

class _TeslaLab3DViewState extends Lab3DState<TeslaLab3DView> {
  GlbModelLibrary get _lib => TeslaLab3DView.models;

  // Jeneratör.
  three.Object3D? _rotor;
  double _rotorAngle = 0;
  final _bulbMat = three.MeshBasicMaterial.fromMap({'color': 0x9E9A8A});
  final _ledRedMat = three.MeshBasicMaterial.fromMap({'color': 0x4A1212});
  final _ledGreenMat = three.MeshBasicMaterial.fromMap({'color': 0x103D12});
  three.PointLight? _bulbLight;
  three.Object3D? _battery;

  // Şehir.
  final List<three.Object3D> _pylons = [];
  final List<three.Mesh> _wires = [];
  final List<List<three.Mesh>> _windows = [];
  final _wireMat = three.MeshBasicMaterial.fromMap({'color': 0x455A64});
  double _shownLoss = 0;
  double _shownHouses = 0;
  String _citySignature = '';

  // Tesla bobini.
  three.Object3D? _lamp;
  final _tubeMat = three.MeshBasicMaterial.fromMap({'color': 0x90A4AE});
  final List<three.Mesh> _sparks = [];
  three.PointLight? _lampLight;
  double _shownLamp = 0;
  double _shownLampX = 1;
  final Random _rng = Random(3);

  TeslaScene get _s => widget.scene;

  static three.Color _c(int hex) => three.Color.fromHex32(hex);
  static final _bulbOff = _c(0x9E9A8A), _bulbOn = _c(0xFFF59D);
  static final _redOff = _c(0x4A1212), _redOn = _c(0xFF1744);
  static final _greenOff = _c(0x103D12), _greenOn = _c(0x00E676);
  static final _wireCold = _c(0x455A64), _wireHot = _c(0xFF5722);
  static final _tubeOff = _c(0x90A4AE), _tubeOn = _c(0xE0F7FF);
  TeslaStation? _backgroundFor;

  @override
  void didUpdateWidget(TeslaLab3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) markDirty();
  }

  three.Object3D _model(String id, {int color = 0x9E9E9E, double size = 0.3}) =>
      model(_lib, id, fallbackColor: color, size: size);

  /// [root] altında adı [name] ile başlayan örgülere [m] malzemesini verir.
  void _paint(three.Object3D root, String name, three.Material m) {
    root.traverse((o) {
      if (o is three.Mesh && o.name.split('.').first == name) o.material = m;
    });
  }

  three.Mesh _bar(double w, double h, double d, three.Material m) =>
      three.Mesh(unitBox, m)..scale.setValues(w, h, d);

  // ─────────────────────────── Kurulum ───────────────────────────

  @override
  Future<void> buildWorld(three.Scene scene) async {
    await _lib.preload();
    _buildLab(scene);
    _buildCity(scene);
    _buildCoil(scene);
  }

  void _buildLab(three.Scene scene) {
    scene.add(_model('tesla_lab', color: 0x6D4C41, size: 0.1)..position.setValues(_labX, 0, 0));
    final gen = _model('tesla_generator', color: 0x8D5A34, size: 0.3)
      ..position.setValues(_labX - 0.6, _bench, -0.35);
    scene.add(gen);
    _rotor = GlbModelLibrary.find(gen, 'Rotor');

    final bulb = _model('tesla_bulb', color: 0xFFF8E1, size: 0.15)
      ..position.setValues(_labX + 0.2, _bench, -0.35);
    _paint(bulb, 'bulb_glass', _bulbMat);
    scene.add(bulb);
    _bulbLight = three.PointLight(0xFFE0A0, 0, 3, 2)
      ..position.setValues(_labX + 0.2, _bench + 0.14, -0.25);
    scene.add(_bulbLight!);

    final leds = _model('tesla_leds', color: 0x2E7D32, size: 0.1)
      ..position.setValues(_labX + 0.6, _bench, -0.3);
    _paint(leds, 'led_red', _ledRedMat);
    _paint(leds, 'led_green', _ledGreenMat);
    scene.add(leds);

    _battery = _model('tesla_battery', color: 0x37474F, size: 0.2)
      ..position.setValues(_labX - 1.25, _bench, -0.35);
    scene.add(_battery!);
    scene.add(_model('tesla_scope', color: 0x607D8B, size: 0.3)
      ..position.setValues(_labX + 1.15, _bench, -0.1)
      ..rotation.y = -0.3);
    // Jeneratörden ampule ve LED'lere giden teller.
    final wire = material(0xB87333, roughness: 0.4);
    scene.add(_bar(0.8, 0.01, 0.01, wire)..position.setValues(_labX - 0.02, _bench + 0.005, -0.28));
    scene.add(_bar(0.4, 0.01, 0.01, wire)..position.setValues(_labX + 0.4, _bench + 0.005, -0.26));
    scene.add(_model('tesla_figure', color: 0x23252B, size: 0.5)
      ..position.setValues(_labX + 1.8, 0, 0.9)
      ..rotation.y = -0.6);
  }

  void _buildCity(three.Scene scene) {
    scene.add(box(0x8BC34A, 34, 0.2, 14)..position.setValues(_cityX, -0.1, 0));
    scene.add(box(0x4FC3F7, 3, 0.05, 14)..position.setValues(_cityX - 16, 0.02, 0));
    scene.add(_model('tesla_plant', color: 0xBCAAA4, size: 2)
      ..position.setValues(_cityX - 12.5, 0, -1));
    scene.add(_model('tesla_transformer', color: 0x90A4AE, size: 0.8)
      ..position.setValues(_cityX - 9.5, 0, 0.8));
    scene.add(_model('tesla_transformer', color: 0x90A4AE, size: 0.8)
      ..position.setValues(_cityX + 7.5, 0, 0.8)
      ..rotation.y = pi);
    for (var i = 0; i < cityHouses; i++) {
      final house = _model('tesla_house', color: 0xF1E3C8, size: 0.8)
        ..position.setValues(_cityX + 9.5 + (i % 5) * 1.3, 0, i < 5 ? -1.2 : 0.8);
      scene.add(house);
      final panes = <three.Mesh>[];
      house.traverse((o) {
        if (o is three.Mesh && o.name.startsWith('window')) panes.add(o);
      });
      _windows.add(panes);
    }
    scene.add(_model('tesla_figure', color: 0x23252B, size: 0.5)
      ..position.setValues(_cityX - 8, 0, 3)
      ..rotation.y = 0.2);
  }

  void _buildCoil(three.Scene scene) {
    scene.add(box(0x37474F, 14, 0.2, 10)..position.setValues(_coilX, -0.1, 0));
    scene.add(_model('tesla_coil', color: 0xECEFF1, size: 0.6)..position.setValues(_coilX, 0, 0));
    _lamp = _model('tesla_lamp', color: 0xE0F7FA, size: 0.2);
    _paint(_lamp!, 'lamp_tube', _tubeMat);
    scene.add(_lamp!);
    _lampLight = three.PointLight(0xB2EBF2, 0, 3, 2);
    scene.add(_lampLight!);
    final spark = material(0xD1C4E9, glow: true);
    for (var i = 0; i < 8; i++) {
      final m = three.Mesh(unitBox, spark)..visible = false;
      scene.add(m);
      _sparks.add(m);
    }
    scene.add(_model('tesla_figure', color: 0x23252B, size: 0.5)
      ..position.setValues(_coilX - 1.7, 0, -0.9)
      ..rotation.y = 0.5);
  }

  // ─────────────────────────── Eşleme ───────────────────────────

  @override
  void syncWorld() {
    _syncCity(_s);
  }

  /// Direk sayısı uzaklıkla artar (ekranda hat boyu sabit, sıkıştırılmış).
  void _syncCity(TeslaScene s) {
    final count = s.distanceKm <= 1 ? 2 : (s.distanceKm <= 10 ? 4 : 7);
    final signature = '$count';
    if (signature == _citySignature) return;
    _citySignature = signature;
    for (final n in [..._pylons, ..._wires]) {
      n.parent?.remove(n);
    }
    _pylons.clear();
    _wires.clear();
    const x0 = _cityX - 8.2, x1 = _cityX + 6.2;
    final xs = [for (var i = 0; i < count; i++) x0 + (x1 - x0) * i / (count - 1)];
    for (final x in xs) {
      final p = _model('tesla_pylon', color: 0x607D8B, size: 0.5)..position.setValues(x, 0, 0);
      threeJs.scene.add(p);
      _pylons.add(p);
    }
    for (var i = 0; i + 1 < xs.length; i++) {
      for (final z in [-0.9, 0.9]) {
        final w = _bar(xs[i + 1] - xs[i], 0.04, 0.04, _wireMat)
          ..position.setValues((xs[i] + xs[i + 1]) / 2, 3.75, z);
        threeJs.scene.add(w);
        _wires.add(w);
      }
    }
    isolate(threeJs.scene);
  }

  // ─────────────────────────── Kare ───────────────────────────

  @override
  void animateWorld(double dt) {
    final s = _s;
    if (_backgroundFor != s.station) {
      _backgroundFor = s.station;
      threeJs.scene.background = _c(switch (s.station) {
        TeslaStation.generator => 0x3E2F2A,
        TeslaStation.transmission => 0xBFE3F5,
        TeslaStation.wireless => 0x14161F,
      });
    }
    _animateGenerator(s, dt);
    _animateCity(s, dt);
    _animateCoil(s, dt);
  }

  void _animateGenerator(TeslaScene s, double dt) {
    final ac = s.source == PowerSource.generator;
    if (ac) _rotorAngle += 2 * pi * s.turnsPerSecond * dt;
    _rotor?.rotation.x = _rotorAngle;
    // Bobinin açısından anlık gerilim; pilde sabit.
    final v = ac ? peakVolts(s.turnsPerSecond) * sin(_rotorAngle) : batteryVolts;
    final glow = (v.abs() / bulbFullVolts).clamp(0.0, 1.0);
    _bulbMat.color.lerpColors(_bulbOff, _bulbOn, glow);
    _bulbLight?.intensity = glow * 1.6;
    final red = v >= ledThresholdVolts;
    final green = v <= -ledThresholdVolts;
    _ledRedMat.color.lerpColors(_redOff, _redOn, red ? 1 : 0);
    _ledGreenMat.color.lerpColors(_greenOff, _greenOn, green ? 1 : 0);
    // Pil devrede değilken biraz geride dursun.
    _battery?.position.z = ac ? -0.55 : -0.35;
  }

  void _animateCity(TeslaScene s, double dt) {
    final lossFraction = 1 - deliveredPercent(s.lineV, s.distanceKm) / 100;
    _shownLoss += (lossFraction - _shownLoss) * min(1.0, dt * 2);
    _wireMat.color.lerpColors(_wireCold, _wireHot, _shownLoss);
    _shownHouses += (s.houses - _shownHouses) * min(1.0, dt * 3);
    final lit = _shownHouses.round();
    for (var i = 0; i < _windows.length; i++) {
      final m = material(i < lit ? _windowLit : _windowDark, glow: i < lit);
      for (final pane in _windows[i]) {
        pane.material = m;
      }
    }
  }

  void _animateCoil(TeslaScene s, double dt) {
    _shownLampX += (s.lampDistanceM - _shownLampX) * min(1.0, dt * 3);
    _lamp?.position.setValues(_coilX + 0.4 + _shownLampX, 0, 0.4);
    _shownLamp += (s.lampLevel - _shownLamp) * min(1.0, dt * 4);
    final flicker = s.coilOn ? 0.9 + 0.1 * _rng.nextDouble() : 1.0;
    _tubeMat.color.lerpColors(_tubeOff, _tubeOn, (_shownLamp * 1.4 * flicker).clamp(0.0, 1.0));
    _lampLight?.position.setValues(_coilX + 0.4 + _shownLampX, 0.85, 0.5);
    _lampLight?.intensity = _shownLamp * 2.5;
    // Kıvılcımlar: tepe halkasından rastgele yönlere kısa, titreşen çizgiler.
    for (final spark in _sparks) {
      spark.visible = s.coilOn && _rng.nextDouble() < 0.7;
      if (!spark.visible) continue;
      final a = _rng.nextDouble() * 2 * pi;
      final len = 0.3 + _rng.nextDouble() * 0.5;
      spark
        ..position.setValues(
          _coilX + cos(a) * (0.35 + len / 2),
          1.6 + (_rng.nextDouble() - 0.5) * 0.4,
          -sin(a) * (0.35 + len / 2),
        )
        ..rotation.set(0, a, (_rng.nextDouble() - 0.5) * 0.8)
        ..scale.setValues(len, 0.015, 0.015);
    }
  }

  // ─────────────────────────── Kamera ───────────────────────────

  @override
  LabCameraShot get cameraShot => switch (_s.station) {
    TeslaStation.generator => (
      look: three.Vector3(_labX - 0.25, 0.98, -0.35),
      offset: three.Vector3(0.1, 0.6, 1.75),
    ),
    TeslaStation.transmission => (
      look: three.Vector3(_cityX - 0.8, 1.2, 0),
      offset: three.Vector3(0, 10, 21),
    ),
    TeslaStation.wireless => (
      look: three.Vector3(_coilX + 1.4, 0.9, 0),
      offset: three.Vector3(0, 1.8, 5.6),
    ),
  };
}
