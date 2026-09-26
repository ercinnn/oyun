import 'dart:math';

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../../data/curie_samples.dart';
import '../../models/curie/curie_scene.dart';
import '../../models/curie/shielding.dart';
import '../glb_model_library.dart';
import '../science_lab/lab_3d_state.dart';

/// Marie Curie'nin laboratuvarının 3B görünümü. Modeller Blender'da
/// üretilmiştir (`assets/models/curie.glb`, üretici `tool/blender/build_curie.py`).
///
/// - Sayaç: sonda seçilen numuneye uzaklık kadar yaklaşır; kadran ibresi
///   sayımı (logaritmik) gösterir, sayacın ışığı rastgele tıklarla çakar
///   (ortalama hız modeldeki tık/sn). Radyum hafifçe yeşil parlar.
/// - Kalkanlar: kaynaktan ışın parçacıkları çıkar; her biri kalkanı modeldeki
///   geçirme oranıyla geçer ya da orada söner.
/// - Tedavi: halkadan hastanın gövdesine ışınlar; kalınlıkları güçleriyle
///   orantılı. Doz haritası Flutter katmanındadır.
class CurieLab3DView extends StatefulWidget {
  const CurieLab3DView({super.key, required this.scene});

  final CurieScene scene;

  static final models = GlbModelLibrary('curie.glb');

  @override
  State<CurieLab3DView> createState() => _CurieLab3DViewState();
}

const double _labX = 0;
const double _shieldX = 24;
const double _therapyX = 48;
const double _bench = 0.85;
const double _sampleZ = -0.1;

/// Numunelerin tezgâhtaki x konumu (sıra `curieSamples` ile aynı).
double _sampleX(int i) => _labX - 1.25 + i * 0.5;

/// Sayacın ekrandaki uzaklığı: gerçek cm'nin iki katı (10 cm → 0,2 m).
double _visualDistance(double cm) => cm * 0.02;

class _CurieLab3DViewState extends Lab3DState<CurieLab3DView> {
  GlbModelLibrary get _lib => CurieLab3DView.models;
  final Random _rng = Random(11);

  CurieScene get _s => widget.scene;

  // Sayaç.
  three.Object3D? _probe;
  three.Object3D? _needle;
  three.Mesh? _clickLight;
  final _clickMat = three.MeshBasicMaterial.fromMap({'color': 0x5D1F1F});
  final _radiumMat = three.MeshBasicMaterial.fromMap({'color': 0x2E7D32});
  double _needleAngle = pi / 3;
  double _flash = 0;
  final three.Vector3 _probePos = three.Vector3(_labX + 1.0, _bench + 0.02, 0.3);

  // Kalkan.
  three.Mesh? _shieldPlate;
  Shield? _shieldShown;
  final List<_Particle> _particles = [];
  three.Object3D? _shieldNeedle;
  double _shieldNeedleAngle = pi / 3;

  // Tedavi.
  final List<three.Mesh> _beams = [];
  String _beamSignature = '';

  static three.Color _c(int hex) => three.Color.fromHex32(hex);
  static final _clickOff = _c(0x5D1F1F), _clickOn = _c(0xFF5252);
  static final _radiumDim = _c(0x2E7D32), _radiumBright = _c(0x76FF03);
  CurieStation? _backgroundFor;

  @override
  void didUpdateWidget(CurieLab3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) markDirty();
  }

  three.Object3D _model(String id, {int color = 0x9E9E9E, double size = 0.2}) =>
      model(_lib, id, fallbackColor: color, size: size);

  /// Adı `_glass` ile biten parçalar saydam cam olur (içleri görünsün).
  void _glassify(three.Object3D root) {
    root.traverse((o) {
      if (o is three.Mesh && o.name.split('.').first.endsWith('_glass')) {
        o.material = material(0xB3E5FC, roughness: 0.1, opacity: 0.35);
      }
    });
  }

  // ─────────────────────────── Kurulum ───────────────────────────

  @override
  Future<void> buildWorld(three.Scene scene) async {
    await _lib.preload();
    _buildGeiger(scene);
    _buildShield(scene);
    _buildTherapy(scene);
  }

  void _buildGeiger(three.Scene scene) {
    scene.add(_model('curie_lab', color: 0xD7CCC8, size: 0.1)..position.setValues(_labX, 0, 0));
    for (var i = 0; i < curieSamples.length; i++) {
      final s = curieSamples[i];
      final m = _model(s.modelId, color: 0x9E9E9E, size: 0.1)
        ..position.setValues(_sampleX(i), _bench, _sampleZ);
      _glassify(m);
      m.traverse((o) {
        if (o is three.Mesh && o.name.split('.').first == 'sample_glow') o.material = _radiumMat;
      });
      scene.add(m);
    }
    final counter = _model('curie_counter', color: 0x455A64, size: 0.2)
      ..position.setValues(_labX + 1.3, _bench, -0.25)
      ..rotation.y = -0.35;
    scene.add(counter);
    _needle = GlbModelLibrary.find(counter, 'Needle');
    _clickLight = three.Mesh(three.SphereGeometry(0.02, 10, 8), _clickMat)
      ..position.setValues(_labX + 1.35, _bench + 0.24, -0.25);
    scene.add(_clickLight!);
    _probe = _model('curie_probe', color: 0x90A4AE, size: 0.05)..rotation.y = pi / 2;
    scene.add(_probe!);
    scene.add(_model('curie_figure', color: 0xF5F5F5, size: 0.5)
      ..position.setValues(_labX - 2.1, 0, 0.7)
      ..rotation.y = 0.5);
  }

  void _buildShield(three.Scene scene) {
    scene.add(box(0xECEFF1, 12, 0.2, 8)..position.setValues(_shieldX, -0.1, 0));
    scene.add(box(0x8D6E63, 3.2, 0.05, 1.0)..position.setValues(_shieldX, _bench - 0.025, 0));
    for (final (x, z) in const [(-1.5, -0.45), (1.5, -0.45), (1.5, 0.45), (-1.5, 0.45)]) {
      scene.add(box(0x5D4037, 0.08, _bench, 0.08)..position.setValues(_shieldX + x, _bench / 2, z));
    }
    scene.add(_model('curie_source', color: 0x546E7A, size: 0.24)
      ..position.setValues(_shieldX - 1.2, _bench, 0));
    final counter = _model('curie_counter', color: 0x455A64, size: 0.2)
      ..position.setValues(_shieldX + 1.25, _bench, 0.1)
      ..rotation.y = -0.6;
    scene.add(counter);
    _shieldNeedle = GlbModelLibrary.find(counter, 'Needle');
    scene.add(_model('curie_probe', color: 0x90A4AE, size: 0.05)
      ..position.setValues(_shieldX + 1.0, _bench + 0.1, 0)
      ..rotation.y = pi);
    _shieldPlate = three.Mesh(unitBox, material(0xFFFFFF));
    scene.add(_shieldPlate!);
    for (var i = 0; i < 36; i++) {
      final m = three.Mesh(three.SphereGeometry(0.018, 8, 6), material(0xFFFFFF, glow: true))
        ..visible = false;
      scene.add(m);
      _particles.add(_Particle(m));
    }
    scene.add(_model('curie_figure', color: 0xF5F5F5, size: 0.5)
      ..position.setValues(_shieldX + 0.2, 0, -1.0));
  }

  void _buildTherapy(three.Scene scene) {
    scene.add(box(0xE0F2F1, 12, 0.2, 8)..position.setValues(_therapyX, -0.1, 0));
    scene.add(_model('curie_bed', color: 0xECEFF1, size: 0.6)..position.setValues(_therapyX, 0, 0));
    scene.add(_model('curie_gantry', color: 0xFAFAFA, size: 0.6)
      ..position.setValues(_therapyX - 0.15, 0, 0));
    scene.add(_model('curie_figure', color: 0xF5F5F5, size: 0.5)
      ..position.setValues(_therapyX + 1.3, 0, -1.1)
      ..rotation.y = -0.4);
  }

  // ─────────────────────────── Eşleme ───────────────────────────

  @override
  void syncWorld() {
    final s = _s;
    if (s.shield != _shieldShown) {
      _shieldShown = s.shield;
      final (w, color, visible) = switch (s.shield) {
        Shield.none => (0.01, 0xFFFFFF, false),
        Shield.paper => (0.006, 0xFFFDE7, true),
        Shield.aluminum => (0.025, 0xB0BEC5, true),
        Shield.lead => (0.1, 0x455A64, true),
      };
      _shieldPlate!
        ..visible = visible
        ..material = material(color, roughness: 0.4)
        ..scale.setValues(w, 0.45, 0.5)
        ..position.setValues(_shieldX, _bench + 0.225, 0);
    }
    final signature = s.beams.map((b) => '${b.angleDeg}/${b.strength}').join(',');
    if (signature != _beamSignature) {
      _beamSignature = signature;
      for (final b in _beams) {
        b.parent?.remove(b);
      }
      _beams.clear();
      for (final beam in s.beams) {
        // Işın, hastanın gövdesinden (x ekseni) geçen yz düzlemindeki bir
        // şerit; kalınlığı gücüyle orantılı.
        final m = three.Mesh(unitBox, material(0xFFD54F, glow: true, opacity: 0.55))
          ..position.setValues(_therapyX - 0.15, 0.95, 0)
          ..scale.setValues(0.05, 1.7, 0.02 + beam.strength * 0.03);
        m.rotation.x = beam.angleDeg * pi / 180;
        threeJs.scene.add(m);
        _beams.add(m);
      }
    }
    isolate(threeJs.scene);
  }

  // ─────────────────────────── Kare ───────────────────────────

  /// Kadran açısı: log ölçek, 0,1…1000 tık/sn → +60°…−60°.
  static double _dialAngle(double cps) {
    final f = ((log(max(cps, 0.1)) / ln10 + 1) / 4).clamp(0.0, 1.0);
    return pi / 3 - f * 2 * pi / 3;
  }

  @override
  void animateWorld(double dt) {
    final s = _s;
    if (_backgroundFor != s.station) {
      _backgroundFor = s.station;
      threeJs.scene.background = _c(switch (s.station) {
        CurieStation.geiger => 0x2F3437,
        CurieStation.shield => 0xCFD8DC,
        CurieStation.therapy => 0xE0F2F1,
      });
    }

    // Sonda: seçili numunenin önüne, uzaklık kadar geriye.
    final i = s.sample == null ? -1 : curieSamples.indexWhere((x) => x.id == s.sample!.id);
    final target = i < 0
        ? three.Vector3(_labX + 1.0, _bench + 0.02, 0.3)
        : three.Vector3(_sampleX(i), _bench + 0.04, _sampleZ + 0.27 + _visualDistance(s.distanceCm));
    final k = min(1.0, dt * 4);
    _probePos.x += (target.x - _probePos.x) * k;
    _probePos.y += (target.y - _probePos.y) * k;
    _probePos.z += (target.z - _probePos.z) * k;
    _probe?.position.setFrom(_probePos);

    final cps = s.geigerCps;
    _needleAngle += (_dialAngle(cps) - _needleAngle) * min(1.0, dt * 3);
    _needle?.rotation.z = _needleAngle + (_rng.nextDouble() - 0.5) * 0.03;
    // Rastgele tıklar: bu karede tık olma olasılığı hız × dt.
    if (_rng.nextDouble() < cps * dt) _flash = 1;
    _flash = max(0, _flash - dt * 12);
    _clickMat.color.lerpColors(_clickOff, _clickOn, _flash);
    final pulse = 0.6 + 0.4 * sin(clock * 2.2);
    _radiumMat.color.lerpColors(_radiumDim, _radiumBright, pulse);

    _animateParticles(s, dt);
    _shieldNeedleAngle += (_dialAngle(s.shieldCps) - _shieldNeedleAngle) * min(1.0, dt * 3);
    _shieldNeedle?.rotation.z = _shieldNeedleAngle;
    // Tedavi ışınları yalnızca açıkken görünür (doz haritasıyla tutarlı).
    for (final b in _beams) {
      b.visible = s.beamsOn;
    }
  }

  void _animateParticles(CurieScene s, double dt) {
    const start = _shieldX - 1.07;
    const end = _shieldX + 1.0;
    final pass = transmission(s.ray, s.shield);
    final speed = switch (s.ray) {
      RayType.alpha => 0.8,
      RayType.beta => 1.6,
      RayType.gamma => 2.4,
    };
    for (final p in _particles) {
      if (!p.active) {
        if (_rng.nextDouble() < dt * 1.5) {
          p
            ..active = true
            ..x = start
            ..y = _bench + 0.12 + (_rng.nextDouble() - 0.5) * 0.05
            ..z = (_rng.nextDouble() - 0.5) * 0.05
            ..passes = _rng.nextDouble() < pass;
          p.mesh
            ..visible = true
            ..material = material(s.ray.color, glow: true);
          // Doğduğu karede konum atanmazsa bir kare boyunca dünya merkezinde
          // (laboratuvarın zemininde) görünürdü.
          p.mesh.position.setValues(p.x, p.y, p.z);
          // Sonradan verilen malzeme de Android renk sızmasından korunsun.
          isolate(p.mesh);
        }
        continue;
      }
      p.x += speed * dt;
      final blocked = !p.passes && s.shield != Shield.none && p.x >= _shieldX;
      if (blocked || p.x >= end) {
        p.active = false;
        p.mesh.visible = false;
        continue;
      }
      p.mesh.position.setValues(p.x, p.y, p.z);
    }
  }

  // ─────────────────────────── Kamera ───────────────────────────

  @override
  LabCameraShot get cameraShot => switch (_s.station) {
    CurieStation.geiger => (
      look: three.Vector3(_labX, 1.0, -0.1),
      offset: three.Vector3(0, 0.85, 2.7),
    ),
    CurieStation.shield => (
      look: three.Vector3(_shieldX, 1.0, 0),
      offset: three.Vector3(0, 0.8, 2.9),
    ),
    CurieStation.therapy => (
      look: three.Vector3(_therapyX, 0.95, 0),
      offset: three.Vector3(1.6, 1.1, 2.6),
    ),
  };
}

class _Particle {
  _Particle(this.mesh);

  final three.Mesh mesh;
  bool active = false;
  bool passes = true;
  double x = 0, y = 0, z = 0;
}
