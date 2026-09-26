import 'dart:math';

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../../models/fleming/fleming_scene.dart';
import '../../models/fleming/hygiene.dart';
import '../../models/fleming/petri.dart';
import '../../models/fleming/resistance.dart';
import '../glb_model_library.dart';
import '../science_lab/lab_3d_state.dart';

/// Fleming'in laboratuvarının 3B görünümü. Modeller Blender'da üretilmiştir
/// (`assets/models/fleming.glb`, üretici `tool/blender/build_fleming.py`);
/// koloniler, küf, temiz halka ve bakteriler kodla kurulan basit şekillerdir.
///
/// Günler görünümde yumuşakça akar; koloni boyları, halka ve bakteri sayıları
/// her karede **modelden** (`colonyRadius`, `inhibitionRadius`,
/// `simulateTreatment`) okunur.
class FlemingLab3DView extends StatefulWidget {
  const FlemingLab3DView({super.key, required this.scene});

  final FlemingScene scene;

  static final models = GlbModelLibrary('fleming.glb');

  @override
  State<FlemingLab3DView> createState() => _FlemingLab3DViewState();
}

const double _petriX = 0;
const double _hygieneX = 24;
const double _medicineX = 48;
const double _bench = 0.85;

/// Kabın agar yüzeyi (tezgâhtan) ve agar yarıçapı (model birimi).
const double _agarTop = 0.041;
const double _agarR = 0.33;

/// Mikroskop görüntüsünde en çok çizilen bakteri.
const int _maxBacteria = 150;

class _FlemingLab3DViewState extends Lab3DState<FlemingLab3DView> {
  GlbModelLibrary get _lib => FlemingLab3DView.models;
  FlemingScene get _s => widget.scene;

  // Petri.
  final List<three.Mesh> _coloniesA = [];
  final List<three.Mesh> _coloniesB = [];
  three.Object3D? _mold;
  three.Mesh? _zone;
  double _shownDay = 0;
  static const _dishA = (_petriX - 0.45, -0.05);
  static const _dishB = (_petriX + 0.45, -0.05);

  // Temizlik.
  three.Object3D? _lid;
  final List<three.Mesh> _hygieneColonies = [];
  double _grow = 0;

  // İlaç.
  final List<three.Mesh> _bacteria = [];
  double _shownMedDay = 0;

  @override
  void didUpdateWidget(FlemingLab3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) markDirty();
  }

  three.Object3D _model(String id, {int color = 0x9E9E9E, double size = 0.3}) =>
      model(_lib, id, fallbackColor: color, size: size);

  /// Adı `_glass` ile biten cam parçaları saydam olur (agar görünsün).
  void _glassify(three.Object3D root) {
    root.traverse((o) {
      if (o is three.Mesh && o.name.split('.').first.endsWith('_glass')) {
        // Çok saydam: kapak agarın rengini soluklaştırmasın.
        o.material = material(0xE1F5FE, roughness: 0.1, opacity: 0.12);
      }
    });
  }

  three.Object3D _dish(double x, double z) {
    final d = _model('fleming_dish', color: 0xF2D38A, size: 0.3)..position.setValues(x, _bench, z);
    _glassify(d);
    // Agar koyu kehribar: açık renkli koloniler üstünde seçilsin (Blender'daki
    // açık sarı, ışık altında kolonilerle neredeyse aynı tona çıkıyordu).
    d.traverse((o) {
      if (o is three.Mesh && o.name.split('.').first == 'agar') {
        o.material = material(0xC98A2E, roughness: 0.5);
      }
    });
    return d;
  }

  three.Mesh _disc(int color, {double opacity = 1}) => three.Mesh(
    three.CylinderGeometry(1, 1, 0.004, 18),
    material(color, roughness: 0.6, opacity: opacity),
  );

  // ─────────────────────────── Kurulum ───────────────────────────

  @override
  Future<void> buildWorld(three.Scene scene) async {
    await _lib.preload();
    for (final x in [_petriX, _hygieneX]) {
      scene.add(_model('fleming_lab', color: 0xE8E0D0, size: 0.1)..position.setValues(x, 0, 0));
    }

    // Petri: iki kap, koloniler, küf, halka.
    scene.add(_dish(_dishA.$1, _dishA.$2));
    scene.add(_dish(_dishB.$1, _dishB.$2));
    for (final (list, dish) in [(_coloniesA, _dishA), (_coloniesB, _dishB)]) {
      for (final c in petriColonies) {
        final m = _disc(0xFFFDF5)
          ..position.setValues(dish.$1 + c.x * _agarR, _bench + _agarTop + 0.003, dish.$2 - c.y * _agarR)
          ..visible = false;
        scene.add(m);
        list.add(m);
      }
    }
    _zone = _disc(0xE2B25A, opacity: 0.7)
      ..position.setValues(_dishA.$1 + moldX * _agarR, _bench + _agarTop + 0.001, _dishA.$2 - moldY * _agarR);
    scene.add(_zone!);
    _mold = three.Object3D()
      ..position.setValues(_dishA.$1 + moldX * _agarR, _bench + _agarTop + 0.004, _dishA.$2 - moldY * _agarR);
    _mold!.add(_disc(0x26A69A));
    final fuzz = material(0x80CBC4, roughness: 1);
    for (var i = 0; i < 6; i++) {
      final a = i * pi / 3;
      _mold!.add(three.Mesh(three.SphereGeometry(0.28, 8, 6), fuzz)
        ..position.setValues(cos(a) * 0.55, 0.05, sin(a) * 0.55));
    }
    scene.add(_mold!);
    scene.add(_model('fleming_microscope', color: 0x263238, size: 0.3)
      ..position.setValues(_petriX + 1.25, _bench, 0.0)
      ..rotation.y = -0.4);
    scene.add(_model('fleming_figure', color: 0xF5F5F5, size: 0.5)
      ..position.setValues(_petriX - 1.9, 0, 0.6)
      ..rotation.y = 0.5);

    // Temizlik: tek kap (kapağı kalkabilir), lavabo ve sabun.
    final dish = _dish(_hygieneX, -0.05);
    scene.add(dish);
    _lid = GlbModelLibrary.find(dish, 'Lid');
    final spots = hygieneColonySpots(
      hygieneColonies(lidOpen: true, hand: HandTouch.unwashed),
    );
    for (var i = 0; i < spots.length; i++) {
      final (x, y) = spots[i];
      final m = _disc(i < openLidColonies ? 0xECEFF1 : 0xFFB74D)
        ..position.setValues(_hygieneX + x * _agarR, _bench + _agarTop + 0.003, -0.05 - y * _agarR)
        ..visible = false;
      scene.add(m);
      _hygieneColonies.add(m);
    }
    scene.add(_model('fleming_sink', color: 0xECEFF1, size: 0.6)
      ..position.setValues(_hygieneX + 2.4, 0, 1.0)
      ..rotation.y = -0.6);
    scene.add(_model('fleming_figure', color: 0xF5F5F5, size: 0.5)
      ..position.setValues(_hygieneX - 1.9, 0, 0.6)
      ..rotation.y = 0.5);

    // İlaç: büyütülmüş mikroskop görüntüsü (dik duran daire), bakteriler.
    scene.add(box(0xECEFF1, 14, 0.2, 10)..position.setValues(_medicineX, -0.1, 0));
    scene.add(three.Mesh(
      three.CylinderGeometry(1.6, 1.6, 0.05, 48),
      material(0x1B2A3A, roughness: 0.8),
    )
      ..rotation.x = pi / 2
      ..position.setValues(_medicineX, 1.9, -0.5));
    scene.add(three.Mesh(
      three.TorusGeometry(1.62, 0.07, 8, 60),
      material(0x455A64, roughness: 0.4),
    )..position.setValues(_medicineX, 1.9, -0.47));
    final rng = Random(31);
    final capsule = three.CylinderGeometry(0.035, 0.035, 0.16, 8);
    for (var i = 0; i < _maxBacteria; i++) {
      double x, y;
      do {
        x = rng.nextDouble() * 2 - 1;
        y = rng.nextDouble() * 2 - 1;
      } while (x * x + y * y > 0.85);
      final m = three.Mesh(capsule, material(0x66BB6A, roughness: 0.5))
        ..position.setValues(_medicineX + x * 1.5, 1.9 + y * 1.5, -0.44)
        ..rotation.z = rng.nextDouble() * pi
        ..visible = false;
      scene.add(m);
      _bacteria.add(m);
    }
    scene.add(_model('fleming_bottle', color: 0x8D6E63, size: 0.2)
      ..position.setValues(_medicineX + 2.2, 0.75, 0.6)
      ..scale.setValues(2.2, 2.2, 2.2));
    scene.add(box(0x8D6E63, 1.0, 0.75, 0.6)..position.setValues(_medicineX + 2.2, 0.375, 0.6));
    scene.add(_model('fleming_figure', color: 0xF5F5F5, size: 0.5)
      ..position.setValues(_medicineX - 2.4, 0, 0.6)
      ..rotation.y = 0.5);
  }

  // ─────────────────────────── Eşleme ───────────────────────────

  @override
  void syncWorld() {}

  // ─────────────────────────── Kare ───────────────────────────

  @override
  void animateWorld(double dt) {
    final s = _s;
    _animatePetri(s, dt);
    _animateHygiene(s, dt);
    _animateMedicine(s, dt);
  }

  void _animatePetri(FlemingScene s, double dt) {
    final diff = s.day - _shownDay;
    final step = 1.5 * dt;
    _shownDay += diff.abs() <= step ? diff : step * diff.sign;
    final d = _shownDay;
    for (var i = 0; i < petriColonies.length; i++) {
      final c = petriColonies[i];
      // Koloniler görünsün diye gerçek oranın 1,4 katı çizilir.
      final r = colonyRadius(c, d) * _agarR * 1.4;
      final a = _coloniesA[i];
      a.visible = r > 0.001 && !colonyBlocked(c, d, mold: s.mold);
      a.scale.setValues(r, 1, r);
      final b = _coloniesB[i];
      b.visible = r > 0.001;
      b.scale.setValues(r, 1, r);
    }
    final moldR = s.mold ? moldRadius(d) * _agarR : 0.0;
    _mold!.visible = moldR > 0;
    _mold!.scale.setValues(max(moldR, 0.001), max(moldR, 0.001), max(moldR, 0.001));
    final zoneR = s.mold ? inhibitionRadius(d) * _agarR : 0.0;
    _zone!.visible = zoneR > 0;
    _zone!.scale.setValues(max(zoneR, 0.001), 1, max(zoneR, 0.001));
  }

  void _animateHygiene(FlemingScene s, double dt) {
    // Kapak açıkken kalkıp yana yatar.
    final lift = s.lidOpen ? 0.22 : 0.0;
    final lid = _lid;
    if (lid != null) {
      lid.position.y += (lift - lid.position.y) * min(1.0, dt * 4);
      lid.rotation.z += ((s.lidOpen ? 0.5 : 0.0) - lid.rotation.z) * min(1.0, dt * 4);
    }
    _grow += ((s.incubated ? 1.0 : 0.0) - _grow) * min(1.0, dt * 1.5);
    final airCount = s.lidOpen ? openLidColonies : 0;
    final handCount = s.hand.colonies;
    for (var i = 0; i < _hygieneColonies.length; i++) {
      // İlk [openLidColonies] tanesi havadan, kalanları elden gelir.
      final fromAir = i < openLidColonies;
      final shown = fromAir ? i < airCount : (i - openLidColonies) < handCount;
      final m = _hygieneColonies[i];
      m.visible = shown && _grow > 0.02;
      final r = 0.028 * _grow * (0.7 + (i % 5) * 0.12);
      m.scale.setValues(max(r, 0.001), 1, max(r, 0.001));
    }
  }

  void _animateMedicine(FlemingScene s, double dt) {
    final diff = s.medicineDay - _shownMedDay;
    final step = 2.0 * dt;
    _shownMedDay += diff.abs() <= step ? diff : step * diff.sign;
    final course = s.course;
    final i0 = _shownMedDay.floor().clamp(0, observedDays);
    final i1 = min(i0 + 1, observedDays);
    final f = _shownMedDay - i0;
    final sens = course[i0].sensitive + (course[i1].sensitive - course[i0].sensitive) * f;
    final res = course[i0].resistant + (course[i1].resistant - course[i0].resistant) * f;
    int toDots(double n) => n <= 0 ? 0 : max(1, (n / populationCap * _maxBacteria).round());
    final resDots = toDots(res);
    final sensDots = toDots(sens);
    for (var i = 0; i < _bacteria.length; i++) {
      final m = _bacteria[i];
      if (i < resDots) {
        m.visible = true;
        m.material = material(0xE53935, roughness: 0.5);
      } else if (i < resDots + sensDots) {
        m.visible = true;
        m.material = material(0x66BB6A, roughness: 0.5);
      } else {
        m.visible = false;
      }
    }
  }

  // ─────────────────────────── Kamera ───────────────────────────

  @override
  LabCameraShot get cameraShot => switch (_s.station) {
    FlemingStation.petri => (
      look: three.Vector3(_petriX, 0.9, -0.05),
      offset: three.Vector3(0, 1.1, 1.45),
    ),
    FlemingStation.hygiene => (
      look: three.Vector3(_hygieneX + 0.3, 0.95, 0),
      offset: three.Vector3(0, 1.2, 2.2),
    ),
    FlemingStation.medicine => (
      look: three.Vector3(_medicineX, 1.6, 0),
      offset: three.Vector3(0, 0.6, 5.2),
    ),
  };
}
