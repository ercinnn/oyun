import 'dart:math';

import 'package:flutter/material.dart' show Color;
import 'package:three_js/three_js.dart' as three;

import '../models/town/avatar_spec.dart';

/// `AvatarSpec`'ten kurulan 3B karakter (three_js ilkel şekilleriyle; model
/// dosyası yok). Mağazadaki tüm saç/kıyafet/şapka/aksesuar kimlikleri
/// gösterilir; renkler paletten gelir. Karakter **+z'ye bakar**, ayakları
/// `y = 0`'dadır, boyu ~1,35 birimdir (bir kare = 1 birim).
///
/// Kol ve bacaklar pivot gruplarıdır: [update] yürürken bunları sallar,
/// dururken hafifçe nefes aldırır; kanatlar (varsa) çırpar.
class Avatar3D {
  Avatar3D._(
    this.root, {
    required three.Group legL,
    required three.Group legR,
    required three.Group armL,
    required three.Group armR,
    required three.Group body,
    required three.Group head,
    three.Group? wingL,
    three.Group? wingR,
  }) : _legL = legL,
       _legR = legR,
       _armL = armL,
       _armR = armR,
       _body = body,
       _head = head,
       _wingL = wingL,
       _wingR = wingR;

  /// Sahneye eklenecek kök.
  final three.Group root;
  final three.Group _legL, _legR, _armL, _armR, _body, _head;
  final three.Group? _wingL, _wingR;

  static int _hex(Color c) => c.toARGB32() & 0xFFFFFF;

  /// Karakteri kurar. Malzemeler bu karaktere özeldir (renkler kişiseldir).
  static Avatar3D build(AvatarSpec spec) {
    final skin = _hex(skinPalette[spec.skin % skinPalette.length]);
    final hair = _hex(hairPalette[spec.hairColor % hairPalette.length]);
    final outfit = _hex(outfitPalette[spec.outfitColor % outfitPalette.length]);

    final cache = <int, three.MeshStandardMaterial>{};
    three.MeshStandardMaterial mat(int color) => cache.putIfAbsent(
      color,
      () => three.MeshStandardMaterial.fromMap({
        'color': color,
        'roughness': 0.85,
      }),
    );

    three.Mesh mesh(
      three.BufferGeometry g,
      int color, {
      double x = 0,
      double y = 0,
      double z = 0,
      double sx = 1,
      double sy = 1,
      double sz = 1,
      double rx = 0,
      double ry = 0,
      double rz = 0,
      three.Material? material,
    }) {
      final m = three.Mesh(g, material ?? mat(color));
      m.position.setValues(x, y, z);
      m.scale.setValues(sx, sy, sz);
      m.rotation.x = rx;
      m.rotation.y = ry;
      m.rotation.z = rz;
      return m;
    }

    final root = three.Group();
    final body = three.Group(); // gövde + kollar + baş: nefes/eğilme için
    root.add(body);

    final isDress = spec.outfit == 'outfit_dress';
    final isSpace = spec.outfit == 'outfit_space';
    final isSuit = spec.outfit == 'outfit_suit';
    final isHoodie = spec.outfit == 'outfit_hoodie';
    final longSleeves = isHoodie || isSuit || isSpace;

    final pants = isSuit ? 0x37474F : (isSpace ? 0xECEFF1 : 0x455A64);
    final shoe = isSpace ? 0xCFD8DC : 0x37474F;

    // ── Bacaklar (kalça pivotu y=0.44).
    three.Group makeLeg(double side) {
      final leg = three.Group()..position.setValues(side * 0.1, 0.44, 0);
      final legColor = isDress ? skin : pants;
      leg.add(
        mesh(three.CylinderGeometry(0.07, 0.062, 0.34, 10), legColor, y: -0.17),
      );
      leg.add(
        mesh(three.BoxGeometry(0.15, 0.09, 0.25), shoe, y: -0.385, z: 0.04),
      );
      return leg;
    }

    final legL = makeLeg(-1);
    final legR = makeLeg(1);
    root.add(legL);
    root.add(legR);

    // ── Gövde.
    final torsoColor = isSpace ? 0xECEFF1 : outfit;
    final torsoWidth = isHoodie ? 0.245 : 0.215;
    body.add(
      mesh(
        three.CylinderGeometry(torsoWidth * 0.95, torsoWidth, 0.46, 18),
        torsoColor,
        y: 0.67,
        sz: 0.66,
      ),
    );
    // Omuzlar (yuvarlak hat).
    body.add(
      mesh(
        three.SphereGeometry(torsoWidth * 0.95, 14, 8),
        torsoColor,
        y: 0.9,
        sy: 0.32,
        sz: 0.66,
      ),
    );
    // Bel/kemer.
    if (!isDress && !isSpace) {
      body.add(
        mesh(
          three.CylinderGeometry(torsoWidth, torsoWidth, 0.05, 18),
          pants,
          y: 0.46,
          sz: 0.68,
        ),
      );
    }

    if (isDress) {
      body.add(
        mesh(three.ConeGeometry(0.34, 0.4, 20, 1, true), outfit, y: 0.31),
      );
      body.add(
        mesh(
          three.CylinderGeometry(0.343, 0.343, 0.025, 20),
          _shade(outfit, 0.25),
          y: 0.115,
          sz: 1,
        ),
      );
    }
    if (isHoodie) {
      body.add(
        mesh(
          three.SphereGeometry(0.16, 12, 8),
          _shade(outfit, 0.15),
          y: 0.93,
          z: -0.13,
          sy: 0.7,
        ),
      );
      body.add(
        mesh(
          three.BoxGeometry(0.2, 0.11, 0.03),
          _shade(outfit, 0.15),
          y: 0.55,
          z: 0.155,
        ),
      );
      body.add(
        mesh(
          three.CylinderGeometry(0.012, 0.012, 0.13, 6),
          0xFFFFFF,
          x: -0.05,
          y: 0.8,
          z: 0.15,
        ),
      );
      body.add(
        mesh(
          three.CylinderGeometry(0.012, 0.012, 0.13, 6),
          0xFFFFFF,
          x: 0.05,
          y: 0.8,
          z: 0.15,
        ),
      );
    }
    if (isSuit) {
      body.add(
        mesh(three.BoxGeometry(0.12, 0.34, 0.02), 0xFFFFFF, y: 0.72, z: 0.15),
      );
      body.add(
        mesh(three.BoxGeometry(0.035, 0.22, 0.022), 0xD32F2F, y: 0.7, z: 0.16),
      );
      body.add(
        mesh(three.BoxGeometry(0.06, 0.05, 0.022), 0xD32F2F, y: 0.82, z: 0.16),
      );
      for (final s in [-1.0, 1.0]) {
        body.add(
          mesh(
            three.BoxGeometry(0.05, 0.3, 0.02),
            _shade(outfit, 0.2),
            x: s * 0.085,
            y: 0.72,
            z: 0.152,
            rz: s * 0.18,
          ),
        );
      }
    }
    if (isSpace) {
      body.add(
        mesh(three.BoxGeometry(0.2, 0.17, 0.03), outfit, y: 0.72, z: 0.15),
      );
      body.add(
        mesh(
          three.CylinderGeometry(0.022, 0.022, 0.03, 8),
          0xFF5252,
          x: -0.05,
          y: 0.74,
          z: 0.168,
          rx: pi / 2,
        ),
      );
      body.add(
        mesh(
          three.CylinderGeometry(0.022, 0.022, 0.03, 8),
          0x69F0AE,
          x: 0.05,
          y: 0.74,
          z: 0.168,
          rx: pi / 2,
        ),
      );
      body.add(
        mesh(three.BoxGeometry(0.3, 0.38, 0.13), 0xB0BEC5, y: 0.7, z: -0.19),
      ); // sırt çantası
    }

    // ── Boyun.
    body.add(
      mesh(three.CylinderGeometry(0.065, 0.07, 0.09, 10), skin, y: 0.95),
    );

    // ── Kollar (omuz pivotu).
    three.Group makeArm(double side) {
      final arm = three.Group()
        ..position.setValues(side * (torsoWidth + 0.06), 0.87, 0);
      arm.rotation.z = side * 0.09;
      final sleeve = longSleeves ? torsoColor : outfit;
      if (longSleeves) {
        arm.add(
          mesh(
            three.CylinderGeometry(0.065, 0.058, 0.34, 10),
            isSuit ? outfit : sleeve,
            y: -0.17,
          ),
        );
      } else {
        arm.add(
          mesh(
            three.CylinderGeometry(0.068, 0.064, 0.13, 10),
            sleeve,
            y: -0.065,
          ),
        );
        arm.add(
          mesh(three.CylinderGeometry(0.055, 0.05, 0.23, 10), skin, y: -0.225),
        );
      }
      arm.add(
        mesh(
          three.SphereGeometry(0.062, 10, 8),
          isSpace ? outfit : skin,
          y: -0.37,
        ),
      );
      arm.add(mesh(three.SphereGeometry(0.068, 10, 8), sleeve, y: 0));
      return arm;
    }

    final armL = makeArm(-1);
    final armR = makeArm(1);
    body.add(armL);
    body.add(armR);

    // ── Baş.
    final head = three.Group()..position.setValues(0, 1.1, 0);
    body.add(head);
    head.add(mesh(three.SphereGeometry(0.25, 22, 16), skin, sy: 0.96));
    for (final s in [-1.0, 1.0]) {
      head.add(
        mesh(
          three.SphereGeometry(0.05, 8, 6),
          skin,
          x: s * 0.245,
          y: -0.01,
          sx: 0.5,
        ),
      );
      // Gözler + parıltı.
      head.add(
        mesh(
          three.SphereGeometry(0.036, 10, 8),
          0x1B1B1B,
          x: s * 0.088,
          y: 0.01,
          z: 0.222,
          sz: 0.55,
        ),
      );
      head.add(
        mesh(
          three.SphereGeometry(0.012, 6, 5),
          0xFFFFFF,
          x: s * 0.088 + 0.012,
          y: 0.028,
          z: 0.244,
        ),
      );
      // Kaşlar.
      head.add(
        mesh(
          three.BoxGeometry(0.07, 0.014, 0.014),
          hair,
          x: s * 0.088,
          y: 0.078,
          z: 0.232,
          rz: s * -0.12,
        ),
      );
      // Yanaklar.
      head.add(
        mesh(
          three.SphereGeometry(0.038, 8, 6),
          0xFF8A80,
          x: s * 0.15,
          y: -0.06,
          z: 0.195,
          sz: 0.4,
        ),
      );
    }
    head.add(
      mesh(
        three.SphereGeometry(0.024, 8, 6),
        _shade(skin, 0.1),
        y: -0.025,
        z: 0.243,
        sz: 0.7,
      ),
    );
    // Gülümseme: torus'un alt yarısı.
    head.add(
      mesh(
        three.TorusGeometry(0.045, 0.008, 6, 14, pi),
        0x8D3B3B,
        y: -0.055,
        z: 0.232,
        rz: pi,
      ),
    );

    // ── Saç.
    final dome = three.SphereGeometry(0.268, 20, 12, 0, 2 * pi, 0, pi * 0.56);
    head.add(mesh(dome, hair, y: 0.02, z: -0.012));
    switch (spec.hairStyle) {
      case 'hair_long':
        head.add(
          mesh(three.BoxGeometry(0.5, 0.56, 0.1), hair, y: -0.18, z: -0.2),
        );
        for (final s in [-1.0, 1.0]) {
          head.add(
            mesh(
              three.BoxGeometry(0.06, 0.4, 0.14),
              hair,
              x: s * 0.24,
              y: -0.12,
              z: -0.06,
            ),
          );
        }
        head.add(
          mesh(three.BoxGeometry(0.34, 0.05, 0.04), hair, y: 0.17, z: 0.21),
        );
      case 'hair_bun':
        head.add(
          mesh(three.SphereGeometry(0.115, 12, 10), hair, y: 0.3, z: -0.06),
        );
        head.add(
          mesh(
            three.CylinderGeometry(0.06, 0.06, 0.04, 10),
            0xEC407A,
            y: 0.235,
            z: -0.045,
          ),
        );
        head.add(
          mesh(three.BoxGeometry(0.3, 0.05, 0.04), hair, y: 0.17, z: 0.21),
        );
      case 'hair_spiky':
        for (var i = 0; i < 8; i++) {
          final a = i / 8 * 2 * pi;
          head.add(
            mesh(
              three.ConeGeometry(0.06, 0.2, 8),
              hair,
              x: cos(a) * 0.17,
              y: 0.24,
              z: sin(a) * 0.17,
              rx: sin(a) * 0.5,
              rz: -cos(a) * 0.5,
            ),
          );
        }
        head.add(mesh(three.ConeGeometry(0.07, 0.24, 8), hair, y: 0.3));
      case 'hair_curly':
        for (var i = 0; i < 10; i++) {
          final a = i / 10 * 2 * pi;
          head.add(
            mesh(
              three.SphereGeometry(0.085, 8, 6),
              hair,
              x: cos(a) * 0.22,
              y: 0.1 + (i.isEven ? 0.02 : 0),
              z: sin(a) * 0.2 - 0.02,
            ),
          );
        }
        for (var i = 0; i < 4; i++) {
          final a = i / 4 * 2 * pi + 0.4;
          head.add(
            mesh(
              three.SphereGeometry(0.09, 8, 6),
              hair,
              x: cos(a) * 0.1,
              y: 0.25,
              z: sin(a) * 0.1,
            ),
          );
        }
      default: // hair_short
        head.add(
          mesh(three.BoxGeometry(0.34, 0.06, 0.04), hair, y: 0.17, z: 0.21),
        );
        for (final s in [-1.0, 1.0]) {
          head.add(
            mesh(
              three.BoxGeometry(0.045, 0.14, 0.1),
              hair,
              x: s * 0.245,
              y: 0.02,
              z: -0.02,
            ),
          );
        }
    }

    // ── Şapka.
    switch (spec.hat) {
      case 'hat_cap':
        head.add(
          mesh(
            three.SphereGeometry(0.28, 20, 10, 0, 2 * pi, 0, pi * 0.5),
            0xE53935,
            y: 0.05,
          ),
        );
        head.add(
          mesh(
            three.BoxGeometry(0.3, 0.025, 0.19),
            0xB71C1C,
            y: 0.075,
            z: 0.27,
            rx: 0.15,
          ),
        );
        head.add(mesh(three.SphereGeometry(0.03, 8, 6), 0xFFFFFF, y: 0.3));
      case 'hat_party':
        head.add(
          mesh(three.ConeGeometry(0.17, 0.4, 14), 0xAB47BC, y: 0.42, rz: 0.08),
        );
        for (var i = 0; i < 3; i++) {
          head.add(
            mesh(
              three.CylinderGeometry(
                0.15 - i * 0.04,
                0.155 - i * 0.04,
                0.03,
                14,
              ),
              0xFFEB3B,
              y: 0.3 + i * 0.1,
            ),
          );
        }
        head.add(
          mesh(three.SphereGeometry(0.05, 8, 6), 0xFF4081, y: 0.63, x: 0.03),
        );
      case 'hat_cowboy':
        head.add(
          mesh(
            three.CylinderGeometry(0.42, 0.42, 0.025, 24),
            0x8D6E63,
            y: 0.19,
          ),
        );
        head.add(
          mesh(three.CylinderGeometry(0.2, 0.235, 0.2, 20), 0x795548, y: 0.3),
        );
        head.add(
          mesh(
            three.CylinderGeometry(0.238, 0.238, 0.04, 20),
            0x4E342E,
            y: 0.23,
          ),
        );
      case 'hat_crown':
        head.add(
          mesh(
            three.CylinderGeometry(0.21, 0.23, 0.12, 20, 1, true),
            0xFFC107,
            y: 0.29,
          ),
        );
        for (var i = 0; i < 5; i++) {
          final a = i / 5 * 2 * pi;
          head.add(
            mesh(
              three.ConeGeometry(0.045, 0.13, 8),
              0xFFC107,
              x: cos(a) * 0.19,
              y: 0.4,
              z: sin(a) * 0.19,
            ),
          );
          head.add(
            mesh(
              three.SphereGeometry(0.022, 6, 5),
              i.isEven ? 0xE53935 : 0x29B6F6,
              x: cos(a) * 0.19,
              y: 0.47,
              z: sin(a) * 0.19,
            ),
          );
        }
      default:
        break;
    }

    // ── Aksesuar.
    three.Group? wingL, wingR;
    switch (spec.accessory) {
      case 'acc_glasses':
        for (final s in [-1.0, 1.0]) {
          head.add(
            mesh(
              three.TorusGeometry(0.068, 0.011, 8, 18),
              0x263238,
              x: s * 0.09,
              y: 0.012,
              z: 0.238,
            ),
          );
          head.add(
            mesh(
              three.BoxGeometry(0.012, 0.012, 0.2),
              0x263238,
              x: s * 0.158,
              y: 0.012,
              z: 0.14,
            ),
          );
        }
        head.add(
          mesh(
            three.BoxGeometry(0.05, 0.012, 0.012),
            0x263238,
            y: 0.02,
            z: 0.24,
          ),
        );
      case 'acc_necklace':
        body.add(
          mesh(
            three.TorusGeometry(0.115, 0.011, 6, 20),
            0xFFC107,
            y: 0.905,
            z: 0.02,
            rx: pi / 2 + 0.5,
            sy: 1,
          ),
        );
        body.add(
          mesh(three.SphereGeometry(0.03, 8, 6), 0xE040FB, y: 0.8, z: 0.13),
        );
      case 'acc_headphones':
        head.add(
          mesh(three.TorusGeometry(0.27, 0.02, 8, 24, pi), 0x424242, y: 0.02),
        );
        for (final s in [-1.0, 1.0]) {
          head.add(
            mesh(
              three.CylinderGeometry(0.085, 0.085, 0.07, 14),
              0xFF5252,
              x: s * 0.27,
              y: 0.0,
              rz: pi / 2,
            ),
          );
          head.add(
            mesh(
              three.CylinderGeometry(0.06, 0.06, 0.075, 14),
              0x424242,
              x: s * 0.275,
              y: 0.0,
              rz: pi / 2,
            ),
          );
        }
      case 'acc_wings':
        three.Group wing(double side) {
          final g = three.Group()..position.setValues(side * 0.12, 0.85, -0.2);
          g.add(
            mesh(
              three.SphereGeometry(1, 12, 8),
              0xFFFFFF,
              x: side * 0.17,
              y: 0.05,
              sx: 0.04,
              sy: 0.32,
              sz: 0.17,
              rz: side * -0.5,
            ),
          );
          g.add(
            mesh(
              three.SphereGeometry(1, 12, 8),
              0xE1F5FE,
              x: side * 0.27,
              y: -0.06,
              sx: 0.035,
              sy: 0.22,
              sz: 0.13,
              rz: side * -0.9,
            ),
          );
          return g;
        }
        wingL = wing(-1);
        wingR = wing(1);
        body.add(wingL);
        body.add(wingR);
      default:
        break;
    }
    // Uzay kıyafetinde kask (saydam).
    if (isSpace) {
      final glass = three.MeshStandardMaterial.fromMap({
        'color': 0x81D4FA,
        'roughness': 0.1,
        'transparent': true,
        'opacity': 0.22,
      });
      head.add(
        mesh(
          three.SphereGeometry(0.36, 20, 14),
          0x81D4FA,
          y: 0.02,
          material: glass,
        ),
      );
      head.add(
        mesh(three.CylinderGeometry(0.2, 0.22, 0.05, 16), 0xECEFF1, y: -0.27),
      );
    }

    root.traverse((o) {
      o.castShadow = true;
    });

    return Avatar3D._(
      root,
      legL: legL,
      legR: legR,
      armL: armL,
      armR: armR,
      body: body,
      head: head,
      wingL: wingL,
      wingR: wingR,
    );
  }

  static int _shade(int color, double t) {
    // t > 0 açar, t < 0 koyulaştırır.
    int ch(int v) =>
        (t >= 0 ? v + (255 - v) * t : v * (1 + t)).round().clamp(0, 255);
    final r = ch((color >> 16) & 255),
        g = ch((color >> 8) & 255),
        b = ch(color & 255);
    return (r << 16) | (g << 8) | b;
  }

  /// Her karede çağrılır: [time] dünya zamanı (saniye), [moving] yürüyor mu,
  /// [phase] karakterlerin senkron sallanmaması için kişisel kaydırma.
  void update(double time, bool moving, {double phase = 0}) {
    final swing = moving ? sin(time * 11 + phase) : 0.0;
    _legL.rotation.x = swing * 0.75;
    _legR.rotation.x = -swing * 0.75;
    final breathe = sin(time * 2 + phase) * 0.03;
    _armL.rotation.x = -swing * 0.85;
    _armR.rotation.x = swing * 0.85;
    _armL.rotation.z = -0.09 - (moving ? 0 : 0.02 + breathe);
    _armR.rotation.z = 0.09 + (moving ? 0 : 0.02 + breathe);
    _body.rotation.x = moving ? 0.07 : 0;
    _body.position.y = moving ? 0 : breathe * 0.4;
    _head.rotation.z = moving ? swing * 0.04 : sin(time * 1.3 + phase) * 0.025;
    final flap =
        sin(time * (moving ? 13 : 3.5) + phase) * (moving ? 0.35 : 0.14);
    _wingL?.rotation.y = flap;
    _wingR?.rotation.y = -flap;
  }
}
