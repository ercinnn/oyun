import 'dart:math';

import 'package:flutter/material.dart';

import '../models/town/avatar_spec.dart';
import '../models/town/iso_projection.dart';
import '../models/town/town_map.dart';
import '../models/town/town_world.dart';
import 'avatar_painter.dart';

/// Bir çizim işi ve derinlik anahtarı. Anahtarı küçük olan önce (arkada) çizilir.
class _Drawable {
  _Drawable(this.depth, this.draw);

  final double depth;
  final void Function(Canvas canvas) draw;
}

/// Bina taban kareleri için derinlik anahtarı: binanın **sol-ön** köşesinin
/// toplamı (`x + y + h`). Kapı önünde (güneyde) duran karakterin toplamı
/// (`x + y`) hep bundan büyüktür ve bina yüzünün önüne çizilir; kuzeyde duran
/// karakter küçüktür ve binanın arkasında kalır. Yalnızca test için açık.
double buildingDepth(TownBuilding building) =>
    building.x + building.y + building.h.toDouble();

/// Tek karelik nesnenin (ağaç, lamba, altın…) derinlik anahtarı.
double tileObjectDepth(double x, double y) => x + y;

/// Dünyayı izometrik olarak çizer: zemin karoları, sonra derinliğe göre sıralı
/// nesneler (binalar, ağaçlar, altınlar, NPC'ler, avatar, mini oyun nesneleri).
/// Kamera avatarı izler. Resim yok; her şey `Canvas` ile çizilir.
class IsoWorldPainter extends CustomPainter {
  IsoWorldPainter({
    required this.world,
    required this.avatar,
    required this.zoom,
    super.repaint,
  });

  final TownWorld world;
  final AvatarSpec avatar;
  final double zoom;

  static final Map<String, TextPainter> _textCache = {};

  /// Kamera merkezi: avatarın ekran konumu (biraz yukarıda, gövde ortası).
  static Offset cameraCenter(TownWorld world) {
    final p = IsoProjection.toScreen(world.x, world.y);
    return p + const Offset(0, -12);
  }

  /// Bir yerel ekran noktasını (tuval koordinatı) kare koordinatına çevirir.
  /// Dokun-yürü bunu kullanır; çizimle aynı dönüşümü paylaşır.
  static Offset canvasToTile(Offset local, Size size, TownWorld world, double zoom) {
    final camera = cameraCenter(world);
    final worldScreen = (local - size.center(Offset.zero)) / zoom + camera;
    // Zemin karosu yüzeyindeki nokta (yükseklik 0).
    return IsoProjection.toTile(worldScreen.dx, worldScreen.dy);
  }

  /// Dokunulan/tıklanan noktanın **yürünecek karesi**. Önce üstünde durulan
  /// nesneye bakar: altın/yıldız/sandık (havada süzüldükleri için zemin karesi
  /// değil, çizildikleri yer esas alınır) ve bina/kapı (binaya ya da kapı
  /// paspasına dokunmak kapısına yürütür). Hiçbiri isabet etmezse dokunulan
  /// zemin karesidir. Fare ve parmak aynı yolu kullanır.
  static (int, int) tapTarget(Offset local, Size size, TownWorld world, double zoom) {
    final camera = cameraCenter(world);
    final p = (local - size.center(Offset.zero)) / zoom + camera;

    const hitRadius = 26.0;
    var best = double.infinity;
    (int, int)? target;
    void consider(Offset at, int tx, int ty, double radius) {
      final d = (p - at).distance;
      if (d < radius && d < best) {
        best = d;
        target = (tx, ty);
      }
    }

    for (final coin in world.coins) {
      if (!coin.active) continue;
      consider(
        IsoProjection.toScreen(coin.x, coin.y) + const Offset(0, -12),
        coin.x.floor(),
        coin.y.floor(),
        hitRadius,
      );
    }
    for (final prop in world.props) {
      if (prop.kind != 'chest' || prop.data == 1) continue;
      consider(
        IsoProjection.toScreen(prop.x, prop.y) + const Offset(0, -8),
        prop.x.floor(),
        prop.y.floor(),
        hitRadius,
      );
    }
    for (final b in world.map.buildings) {
      consider(
        IsoProjection.toScreen(b.doorX + 0.5, b.doorY + 0.5),
        b.doorX,
        b.doorY,
        hitRadius + 6,
      );
    }
    if (target != null) return target!;

    // Binanın gövdesine (çatı dahil) dokunmak kapısına yürütür.
    for (final b in world.map.buildings) {
      final left = IsoProjection.toScreen(b.x.toDouble(), (b.y + b.h).toDouble()).dx;
      final right = IsoProjection.toScreen((b.x + b.w).toDouble(), b.y.toDouble()).dx;
      final top = IsoProjection.toScreen(b.x.toDouble(), b.y.toDouble()).dy - 78;
      final bottom =
          IsoProjection.toScreen((b.x + b.w).toDouble(), (b.y + b.h).toDouble()).dy;
      if (Rect.fromLTRB(left, top, right, bottom).contains(p)) {
        return (b.doorX, b.doorY);
      }
    }

    final tile = IsoProjection.toTile(p.dx, p.dy);
    return (tile.dx.floor(), tile.dy.floor());
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF7CB342),
    );

    final camera = cameraCenter(world);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(zoom);
    canvas.translate(-camera.dx, -camera.dy);

    final visible = Rect.fromCenter(
      center: camera,
      width: size.width / zoom + 160,
      height: size.height / zoom + 200,
    );

    _paintGround(canvas, visible);
    _paintObjects(canvas, visible);

    canvas.restore();
  }

  // ─────────────────────────── Zemin ───────────────────────────

  void _paintGround(Canvas canvas, Rect visible) {
    final map = world.map;
    final paint = Paint();
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        final top = IsoProjection.toScreen(x.toDouble(), y.toDouble());
        final bounds = Rect.fromLTWH(
          top.dx - IsoProjection.tileW / 2,
          top.dy,
          IsoProjection.tileW,
          IsoProjection.tileH,
        );
        if (!bounds.overlaps(visible)) continue;

        final kind = map.kindAt(x, y);
        final shade = (x + y).isEven ? 0.0 : 0.05;
        paint.color = _groundColor(kind, shade);
        canvas.drawPath(_diamond(top), paint);

        if (kind == TileKind.water) {
          _paintWave(canvas, top, x, y);
        } else if (kind == TileKind.goal) {
          _paintGoalChecker(canvas, x, y);
        } else if (kind == TileKind.door) {
          paint.color = const Color(0xFF8D6E63);
          canvas.drawPath(_diamondAt(x + 0.15, y + 0.15, 0.7), paint);
        }
      }
    }
  }

  Color _groundColor(TileKind kind, double shade) {
    final base = switch (kind) {
      TileKind.road => const Color(0xFF90A4AE),
      TileKind.sand => const Color(0xFFF3E1A0),
      TileKind.water => const Color(0xFF4FC3F7),
      TileKind.mud => const Color(0xFF8D6E63),
      TileKind.door => const Color(0xFFB0BEC5),
      TileKind.start => const Color(0xFFAED581),
      TileKind.goal => const Color(0xFFFFFFFF),
      _ => const Color(0xFF8BC34A),
    };
    return Color.lerp(base, const Color(0xFF000000), shade)!;
  }

  Path _diamond(Offset top) => Path()
    ..moveTo(top.dx, top.dy)
    ..lineTo(top.dx + IsoProjection.tileW / 2, top.dy + IsoProjection.tileH / 2)
    ..lineTo(top.dx, top.dy + IsoProjection.tileH)
    ..lineTo(top.dx - IsoProjection.tileW / 2, top.dy + IsoProjection.tileH / 2)
    ..close();

  Path _diamondAt(double x, double y, double size) {
    final a = IsoProjection.toScreen(x, y);
    final b = IsoProjection.toScreen(x + size, y);
    final c = IsoProjection.toScreen(x + size, y + size);
    final d = IsoProjection.toScreen(x, y + size);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(d.dx, d.dy)
      ..close();
  }

  void _paintWave(Canvas canvas, Offset top, int x, int y) {
    final wave = sin(world.time * 2 + x * 0.9 + y * 0.6);
    final paint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final cy = top.dy + IsoProjection.tileH / 2 + wave * 2;
    canvas.drawLine(Offset(top.dx - 10, cy), Offset(top.dx + 10, cy), paint);
  }

  void _paintGoalChecker(Canvas canvas, int x, int y) {
    final paint = Paint()..color = const Color(0xFF212121);
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        if ((i + j).isEven) continue;
        canvas.drawPath(_diamondAt(x + i / 4, y + j / 4, 0.25), paint);
      }
    }
  }

  // ─────────────────────────── Nesneler ───────────────────────────

  void _paintObjects(Canvas canvas, Rect visible) {
    final map = world.map;
    final items = <_Drawable>[];

    for (final b in map.buildings) {
      items.add(_Drawable(buildingDepth(b), (c) => _paintBuilding(c, b)));
    }

    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        final kind = map.kindAt(x, y);
        if (kind != TileKind.tree &&
            kind != TileKind.fountain &&
            kind != TileKind.lamp) {
          continue;
        }
        final base = IsoProjection.toScreen(x + 0.5, y + 0.5);
        if (!visible.contains(base)) continue;
        final depth = tileObjectDepth(x + 0.5, y + 0.5);
        switch (kind) {
          case TileKind.tree:
            items.add(_Drawable(depth, (c) => _paintTree(c, base, x, y)));
          case TileKind.fountain:
            items.add(_Drawable(depth, (c) => _paintFountain(c, base)));
          default:
            items.add(_Drawable(depth, (c) => _paintLamp(c, base)));
        }
      }
    }

    for (final coin in world.coins) {
      if (!coin.active) continue;
      final base = IsoProjection.toScreen(coin.x, coin.y);
      if (!visible.contains(base)) continue;
      items.add(_Drawable(coin.x + coin.y - 0.3, (c) => _paintCoin(c, base, coin)));
    }

    for (final prop in world.props) {
      final base = IsoProjection.toScreen(prop.x, prop.y);
      final depth = prop.x + prop.y - 0.2;
      switch (prop.kind) {
        case 'barrel':
          items.add(_Drawable(depth, (c) => _paintBarrel(c, base)));
        case 'chest':
          items.add(_Drawable(depth, (c) => _paintChest(c, base, prop.data == 1)));
      }
    }

    if (map.goalX >= 0) {
      final flag = IsoProjection.toScreen(map.goalX + 0.5, map.goalY + 0.5);
      items.add(
        _Drawable(map.goalX + map.goalY + 1.0, (c) => _paintFlag(c, flag)),
      );
    }

    for (final npc in world.npcs) {
      final base = IsoProjection.toScreen(npc.x, npc.y);
      items.add(
        _Drawable(npc.x + npc.y, (c) {
          paintAvatar(
            c,
            base,
            0.95,
            npc.avatar,
            facing: npc.facing,
            moving: npc.moving,
            time: world.time,
          );
        }),
      );
    }

    final me = IsoProjection.toScreen(world.x, world.y);
    items.add(
      _Drawable(world.x + world.y + 0.001, (c) {
        paintAvatar(
          c,
          me,
          1.0,
          avatar,
          facing: world.facing,
          moving: world.moving,
          time: world.time,
        );
      }),
    );

    items.sort((a, b) => a.depth.compareTo(b.depth));
    for (final item in items) {
      item.draw(canvas);
    }
  }

  // Binalar ────────────────────────────────────────────────

  void _paintBuilding(Canvas canvas, TownBuilding b) {
    const heightPx = 78.0;
    final up = const Offset(0, -heightPx);
    final p00 = IsoProjection.toScreen(b.x.toDouble(), b.y.toDouble());
    final p10 = IsoProjection.toScreen((b.x + b.w).toDouble(), b.y.toDouble());
    final p11 = IsoProjection.toScreen((b.x + b.w).toDouble(), (b.y + b.h).toDouble());
    final p01 = IsoProjection.toScreen(b.x.toDouble(), (b.y + b.h).toDouble());

    final (wall, roof) = switch (b.kind) {
      DoorKind.wardrobe => (const Color(0xFFF48FB1), const Color(0xFFAD1457)),
      DoorKind.market => (const Color(0xFFFFB74D), const Color(0xFFE65100)),
      DoorKind.home => (const Color(0xFF64B5F6), const Color(0xFF1565C0)),
      DoorKind.arcade => (const Color(0xFFB39DDB), const Color(0xFF4527A0)),
    };

    Path quad(Offset a, Offset bb, Offset c, Offset d) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(bb.dx, bb.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(d.dx, d.dy)
      ..close();

    final paint = Paint();
    // Yer gölgesi.
    paint.color = const Color(0x22000000);
    canvas.drawPath(quad(p00 + const Offset(6, 4), p10 + const Offset(6, 4), p11 + const Offset(6, 4), p01 + const Offset(6, 4)), paint);

    // Sol-ön (güneybatı) yüz ve sağ-ön (güneydoğu) yüz.
    paint.color = Color.lerp(wall, const Color(0xFF000000), 0.06)!;
    canvas.drawPath(quad(p01, p11, p11 + up, p01 + up), paint);
    paint.color = Color.lerp(wall, const Color(0xFF000000), 0.24)!;
    canvas.drawPath(quad(p11, p10, p10 + up, p11 + up), paint);

    // Çatı: hafif taşan üst yüz.
    final center = (p00 + p11) / 2 + up;
    Offset grow(Offset p) => center + (p + up - center) * 1.07;
    paint.color = Color.lerp(roof, const Color(0xFF000000), 0.2)!;
    canvas.drawPath(quad(grow(p00), grow(p10), grow(p11), grow(p01)), paint);
    paint.color = roof;
    canvas.drawPath(quad(p00 + up, p10 + up, p11 + up, p01 + up), paint);

    // Pencereler (güneybatı yüzü).
    Offset onFace(double t, double h) => p01 + (p11 - p01) * t + Offset(0, -h);
    paint.color = const Color(0xFFE3F2FD);
    for (final t in [0.18, 0.72]) {
      canvas.drawPath(
        quad(onFace(t, 38), onFace(t + 0.1, 38), onFace(t + 0.1, 58), onFace(t, 58)),
        paint,
      );
    }
    // Kapı.
    final doorT = ((b.doorX + 0.5 - b.x) / b.w).clamp(0.1, 0.9);
    paint.color = const Color(0xFF6D4C41);
    canvas.drawPath(
      quad(
        onFace(doorT - 0.07, 0),
        onFace(doorT + 0.07, 0),
        onFace(doorT + 0.07, 30),
        onFace(doorT - 0.07, 30),
      ),
      paint,
    );

    // Çatı tabelası: yazı tipine bağlı emoji yerine paketli ikon fontu (emoji
    // yazı tipi geç yüklenirse önbellekteki çizim kutucuk gösterirdi).
    _paintIcon(canvas, _signIcon(b.kind), center + const Offset(0, 2), 30);
  }

  // Ağaç, çeşme, lamba ─────────────────────────────────────

  void _paintTree(Canvas canvas, Offset base, int x, int y) {
    final sway = sin(world.time * 1.5 + x * 1.7 + y) * 1.5;
    final paint = Paint()..color = const Color(0x33000000);
    canvas.drawOval(Rect.fromCenter(center: base, width: 34, height: 14), paint);
    paint.color = const Color(0xFF795548);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - 4, base.dy - 26, 8, 26),
        const Radius.circular(3),
      ),
      paint,
    );
    final top = base + Offset(sway, -34);
    paint.color = const Color(0xFF2E7D32);
    canvas.drawCircle(top + const Offset(-10, 6), 15, paint);
    canvas.drawCircle(top + const Offset(10, 6), 15, paint);
    paint.color = const Color(0xFF43A047);
    canvas.drawCircle(top, 19, paint);
    paint.color = const Color(0xFF66BB6A);
    canvas.drawCircle(top + const Offset(-5, -6), 8, paint);
  }

  void _paintFountain(Canvas canvas, Offset base) {
    final paint = Paint()..color = const Color(0x33000000);
    canvas.drawOval(Rect.fromCenter(center: base, width: 60, height: 28), paint);
    paint.color = const Color(0xFFB0BEC5);
    canvas.drawOval(Rect.fromCenter(center: base + const Offset(0, -6), width: 56, height: 26), paint);
    paint.color = const Color(0xFF4FC3F7);
    canvas.drawOval(Rect.fromCenter(center: base + const Offset(0, -8), width: 44, height: 19), paint);
    paint.color = const Color(0xFFCFD8DC);
    canvas.drawRect(Rect.fromLTWH(base.dx - 4, base.dy - 30, 8, 24), paint);
    // Fışkıran su.
    final t = world.time * 3;
    paint
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 3; i++) {
      final phase = (t + i * 1.3) % 3;
      final h = sin(phase / 3 * pi) * 16;
      final side = (i - 1) * 8.0;
      canvas.drawLine(
        base + Offset(side * 0.3, -30),
        base + Offset(side, -30 + h * 0.4),
        paint,
      );
    }
    paint.style = PaintingStyle.fill;
  }

  void _paintLamp(Canvas canvas, Offset base) {
    final paint = Paint()..color = const Color(0x33000000);
    canvas.drawOval(Rect.fromCenter(center: base, width: 18, height: 8), paint);
    paint.color = const Color(0xFF37474F);
    canvas.drawRect(Rect.fromLTWH(base.dx - 2, base.dy - 46, 4, 46), paint);
    final glow = 0.55 + sin(world.time * 2) * 0.1;
    paint.color = Color.fromRGBO(255, 235, 59, glow * 0.4);
    canvas.drawCircle(base + const Offset(0, -50), 14, paint);
    paint.color = const Color(0xFFFFEE58);
    canvas.drawCircle(base + const Offset(0, -50), 6, paint);
  }

  // Altın, yıldız, varil, sandık, bayrak ──────────────────

  void _paintCoin(Canvas canvas, Offset base, WorldCoin coin) {
    final bob = sin(world.time * 4 + coin.x * 2 + coin.y) * 3;
    final center = base + Offset(0, -12 + bob);
    final paint = Paint()..color = const Color(0x33000000);
    canvas.drawOval(Rect.fromCenter(center: base, width: 12, height: 5), paint);
    if (coin.isStar) {
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final angle = -pi / 2 + i * pi / 5;
        final r = i.isEven ? 9.0 : 4.0;
        final p = center + Offset(cos(angle) * r, sin(angle) * r);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      paint.color = const Color(0xFFFFD600);
      canvas.drawPath(path, paint);
      paint
        ..color = const Color(0xFFFF8F00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(path, paint);
      paint.style = PaintingStyle.fill;
    } else {
      paint.color = const Color(0xFFFFC107);
      canvas.drawCircle(center, 7, paint);
      paint.color = const Color(0xFFFFE082);
      canvas.drawCircle(center + const Offset(-1.5, -1.5), 3.2, paint);
    }
  }

  void _paintBarrel(Canvas canvas, Offset base) {
    final paint = Paint()..color = const Color(0x33000000);
    canvas.drawOval(Rect.fromCenter(center: base, width: 26, height: 10), paint);
    paint.color = const Color(0xFF8D6E63);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - 11, base.dy - 26, 22, 26),
        const Radius.circular(6),
      ),
      paint,
    );
    paint.color = const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromLTWH(base.dx - 11, base.dy - 20, 22, 3), paint);
    canvas.drawRect(Rect.fromLTWH(base.dx - 11, base.dy - 9, 22, 3), paint);
  }

  void _paintChest(Canvas canvas, Offset base, bool opened) {
    final paint = Paint()..color = const Color(0x33000000);
    canvas.drawOval(Rect.fromCenter(center: base, width: 30, height: 12), paint);
    paint.color = const Color(0xFF8D6E63);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(base.dx - 13, base.dy - 16, 26, 16), const Radius.circular(3)),
      paint,
    );
    paint.color = opened ? const Color(0xFFFFD54F) : const Color(0xFF6D4C41);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - 13, base.dy - (opened ? 24 : 22), 26, 8),
        const Radius.circular(3),
      ),
      paint,
    );
    paint.color = const Color(0xFFFFC107);
    canvas.drawRect(Rect.fromLTWH(base.dx - 2, base.dy - 15, 4, 8), paint);
  }

  void _paintFlag(Canvas canvas, Offset base) {
    final paint = Paint()..color = const Color(0xFF546E7A);
    canvas.drawRect(Rect.fromLTWH(base.dx - 1.5, base.dy - 48, 3, 48), paint);
    final wave = sin(world.time * 5) * 3;
    paint.color = const Color(0xFFE53935);
    final flag = Path()
      ..moveTo(base.dx + 1.5, base.dy - 48)
      ..lineTo(base.dx + 24, base.dy - 42 + wave)
      ..lineTo(base.dx + 1.5, base.dy - 34)
      ..close();
    canvas.drawPath(flag, paint);
  }

  static IconData _signIcon(DoorKind kind) => switch (kind) {
    DoorKind.wardrobe => Icons.checkroom,
    DoorKind.market => Icons.weekend,
    DoorKind.home => Icons.home,
    DoorKind.arcade => Icons.sports_esports,
  };

  void _paintIcon(Canvas canvas, IconData icon, Offset center, double size) {
    final key = '${icon.codePoint}@$size';
    final painter = _textCache.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: size,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant IsoWorldPainter oldDelegate) => true;
}
