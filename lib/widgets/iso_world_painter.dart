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

/// Bina duvar ve çatı yükseklikleri (piksel, dünya birimi).
const double buildingWallHeight = 58;
const double buildingRoofHeight = 34;

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
      final top = IsoProjection.toScreen(b.x.toDouble(), b.y.toDouble()).dy -
          (buildingWallHeight + buildingRoofHeight + 8);
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

  static Color _shade(Color c, double t) => t >= 0
      ? Color.lerp(c, const Color(0xFF000000), t)!
      : Color.lerp(c, const Color(0xFFFFFFFF), -t)!;

  /// Üç boyutlu (duvarlı, kirişli çatılı, kapılı, pencereli) bina. Işık sol
  /// üstten gelir: sol-ön yüz aydınlık, sağ-ön yüz gölgede; çatı, saçak,
  /// pervaz, denizlik, gölge ve zemin kararması gradyan/alfa ile verilir.
  /// Hepsi `Canvas` ile çizilir (resim yok).
  void _paintBuilding(Canvas canvas, TownBuilding b) {
    const wallH = buildingWallHeight;
    const roofH = buildingRoofHeight;
    final x0 = b.x.toDouble(), y0 = b.y.toDouble();
    final x1 = x0 + b.w, y1 = y0 + b.h;
    final cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;

    Offset pt(double x, double y, [double z = 0]) =>
        IsoProjection.toScreen(x, y) + Offset(0, -z);

    final (wall, roof, trim) = switch (b.kind) {
      DoorKind.wardrobe => (
        const Color(0xFFF8BBD0),
        const Color(0xFFC2185B),
        const Color(0xFFFFF3F8),
      ),
      DoorKind.market => (
        const Color(0xFFFFE0B2),
        const Color(0xFFE65100),
        const Color(0xFFFFF8E1),
      ),
      DoorKind.home => (
        const Color(0xFFBBDEFB),
        const Color(0xFF8D3B2E),
        const Color(0xFFFFFFFF),
      ),
      DoorKind.arcade => (
        const Color(0xFFB39DDB),
        const Color(0xFF311B92),
        const Color(0xFFEDE7F6),
      ),
    };

    Path poly(List<Offset> pts) {
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    void fill(Path p, Color c) => canvas.drawPath(p, Paint()..color = c);

    void gradient(Path p, Color top, Color bottom) {
      final r = p.getBounds();
      canvas.drawPath(
        p,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ).createShader(r),
      );
    }

    void line(Offset a, Offset c, Color color, double width) {
      canvas.drawLine(
        a,
        c,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    // Bir yüzün (A→B, yerden z0..z1 arası, t0..t1 aralığı) dörtgeni.
    Path faceQuad(Offset a, Offset c, double t0, double t1, double z0, double z1) {
      Offset at(double t, double z) => a + (c - a) * t + Offset(0, -z);
      return poly([at(t0, z0), at(t1, z0), at(t1, z1), at(t0, z1)]);
    }

    // ── Gölge: ışık sol üstten, gölge sağ-alta düşer (iki katman = yumuşak).
    final p00 = pt(x0, y0), p10 = pt(x1, y0), p11 = pt(x1, y1), p01 = pt(x0, y1);
    for (final (shift, alpha) in [
      (const Offset(34, 15), 0x14),
      (const Offset(22, 10), 0x1A),
      (const Offset(10, 5), 0x22),
    ]) {
      fill(
        poly([p00 + shift, p10 + shift, p11 + shift, p01 + shift, p01, p11]),
        Color.fromARGB(alpha, 0, 0, 0),
      );
    }

    // Kapı basamağı (yerde, kapının önünde).
    final doorFrac = ((b.doorX + 0.5 - b.x) / b.w).clamp(0.1, 0.9);
    final doorX = x0 + b.w * doorFrac;
    fill(
      poly([
        pt(doorX - 0.36, y1),
        pt(doorX + 0.36, y1),
        pt(doorX + 0.36, y1 + 0.16),
        pt(doorX - 0.36, y1 + 0.16),
      ]),
      const Color(0xFFCFD8DC),
    );

    // ── Duvarlar.
    final frontA = p01, frontB = p11; // sol-ön yüz (y1 kenarı), t: x boyunca
    final sideA = p11, sideB = p10; // sağ-ön yüz (x1 kenarı), t: y boyunca
    final frontW = b.w.toDouble(), sideW = b.h.toDouble();

    gradient(
      faceQuad(frontA, frontB, 0, 1, 0, wallH),
      _shade(wall, -0.10),
      _shade(wall, 0.06),
    );
    gradient(
      faceQuad(sideA, sideB, 0, 1, 0, wallH),
      _shade(wall, 0.16),
      _shade(wall, 0.32),
    );

    // Yatay kaplama çizgileri.
    for (var z = 12.0; z < wallH - 6; z += 9) {
      line(
        frontA + Offset(0, -z),
        frontB + Offset(0, -z),
        const Color(0x14000000),
        1,
      );
      line(
        sideA + Offset(0, -z),
        sideB + Offset(0, -z),
        const Color(0x18000000),
        1,
      );
    }

    // Taş temel.
    fill(faceQuad(frontA, frontB, 0, 1, 0, 7), const Color(0xFF90A4AE));
    fill(faceQuad(sideA, sideB, 0, 1, 0, 7), const Color(0xFF607D8B));
    line(frontA + const Offset(0, -7), frontB + const Offset(0, -7),
        const Color(0x55FFFFFF), 1);

    // Köşe pervazları.
    final cornerFront = 0.09 / frontW, cornerSide = 0.09 / sideW;
    fill(faceQuad(frontA, frontB, 0, cornerFront, 0, wallH), _shade(trim, 0.04));
    fill(faceQuad(frontA, frontB, 1 - cornerFront, 1, 0, wallH), _shade(trim, 0.12));
    fill(faceQuad(sideA, sideB, 0, cornerSide, 0, wallH), _shade(trim, 0.16));
    fill(faceQuad(sideA, sideB, 1 - cornerSide, 1, 0, wallH), _shade(trim, 0.26));

    // Saçak altı gölgesi ve silme.
    gradient(
      faceQuad(frontA, frontB, 0, 1, wallH - 18, wallH - 6),
      const Color(0x00000000),
      const Color(0x44000000),
    );
    gradient(
      faceQuad(sideA, sideB, 0, 1, wallH - 18, wallH - 6),
      const Color(0x00000000),
      const Color(0x4D000000),
    );
    fill(faceQuad(frontA, frontB, 0, 1, wallH - 6, wallH), trim);
    fill(faceQuad(sideA, sideB, 0, 1, wallH - 6, wallH), _shade(trim, 0.2));

    // Zemin teması karartması.
    gradient(
      faceQuad(frontA, frontB, 0, 1, 7, 16),
      const Color(0x00000000),
      const Color(0x18000000),
    );

    // ── Pencereler.
    void window(Offset a, Offset c, double n, int i, {required bool lit}) {
      final mid = (i + 0.5) / n;
      final half = 0.22 / n;
      const z0 = 28.0, z1 = 47.0;
      final sh = 0.05 / n;
      // Çerçeve.
      fill(faceQuad(a, c, mid - half - sh, mid + half + sh, z0 - 2.5, z1 + 2.5), trim);
      // Cam.
      final glass = faceQuad(a, c, mid - half, mid + half, z0, z1);
      if (lit) {
        gradient(glass, const Color(0xFFFF80AB), const Color(0xFF7C4DFF));
      } else {
        gradient(glass, const Color(0xFFE1F5FE), const Color(0xFF4FC3F7));
        // Yansıma.
        fill(
          faceQuad(a, c, mid - half, mid - half * 0.2, z0 + (z1 - z0) * 0.55, z1),
          const Color(0x55FFFFFF),
        );
      }
      // Ara çıtalar.
      final zm = (z0 + z1) / 2;
      final left = a + (c - a) * (mid - half);
      final right = a + (c - a) * (mid + half);
      final top = a + (c - a) * mid;
      line(left + Offset(0, -zm), right + Offset(0, -zm), trim, 1.4);
      line(top + const Offset(0, -z0), top + const Offset(0, -z1), trim, 1.4);
      // Denizlik.
      fill(
        faceQuad(a, c, mid - half - sh * 1.6, mid + half + sh * 1.6, z0 - 5, z0 - 2.5),
        _shade(trim, 0.18),
      );
      if (b.kind == DoorKind.home) {
        // Panjur + çiçek kasası.
        const shutter = Color(0xFF2E7D32);
        fill(faceQuad(a, c, mid - half - sh * 4.2, mid - half - sh, z0 - 2.5, z1 + 2.5), shutter);
        fill(faceQuad(a, c, mid + half + sh, mid + half + sh * 4.2, z0 - 2.5, z1 + 2.5), shutter);
        fill(faceQuad(a, c, mid - half, mid + half, z0 - 11, z0 - 5), const Color(0xFF6D4C41));
        for (var k = 0; k < 4; k++) {
          final t = mid - half + (2 * half) * (k + 0.5) / 4;
          final p = a + (c - a) * t + Offset(0, -(z0 - 11));
          canvas.drawCircle(p, 2.1, Paint()..color = k.isEven ? const Color(0xFFFF5252) : const Color(0xFFFFEB3B));
        }
      }
    }

    final doorCol = (b.doorX - b.x).clamp(0, b.w - 1);
    for (var i = 0; i < b.w; i++) {
      if (i == doorCol) continue;
      window(frontA, frontB, frontW, i, lit: b.kind == DoorKind.arcade);
    }
    for (var i = 0; i < b.h; i++) {
      window(sideA, sideB, sideW, i, lit: b.kind == DoorKind.arcade);
    }

    // ── Kapı.
    {
      final tc = doorFrac;
      final half = 0.3 / frontW;
      const dz = 37.0;
      fill(faceQuad(frontA, frontB, tc - half - 0.05 / frontW, tc + half + 0.05 / frontW, 0, dz + 4), trim);
      final body = faceQuad(frontA, frontB, tc - half, tc + half, 0, dz);
      gradient(body, const Color(0xFF8D6E63), const Color(0xFF4E342E));
      // İç panolar.
      for (final z in [3.0, 21.0]) {
        fill(
          faceQuad(frontA, frontB, tc - half * 0.7, tc + half * 0.7, z, z + 13),
          const Color(0x33000000),
        );
      }
      final knob = frontA + (frontB - frontA) * (tc + half * 0.68) + const Offset(0, -18);
      canvas.drawCircle(knob, 1.9, Paint()..color = const Color(0xFFFFCA28));
      if (b.kind == DoorKind.arcade) {
        // Neon çerçeve.
        final glow = 0.6 + sin(world.time * 5) * 0.25;
        final edge = Paint()
          ..color = Color.fromRGBO(0, 229, 255, glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawPath(
          faceQuad(frontA, frontB, tc - half, tc + half, 0, dz),
          edge,
        );
      }
    }

    // Tente (giyim ve market): çizgili, kapının üstünde öne uzanır.
    if (b.kind == DoorKind.wardrobe || b.kind == DoorKind.market) {
      final tc = doorFrac;
      final half = 0.62 / frontW;
      const out = Offset(-13, 7);
      final stripeA = b.kind == DoorKind.wardrobe
          ? const Color(0xFFEC407A)
          : const Color(0xFFEF6C00);
      const stripeB = Color(0xFFFFFFFF);
      const n = 7;
      Offset wallPt(double t, double z) =>
          frontA + (frontB - frontA) * t + Offset(0, -z);
      // Tente altı gölgesi (duvarda).
      fill(
        poly([
          wallPt(tc - half, 40),
          wallPt(tc + half, 40),
          wallPt(tc + half, 26),
          wallPt(tc - half, 26),
        ]),
        const Color(0x22000000),
      );
      for (var k = 0; k < n; k++) {
        final ta = tc - half + 2 * half * k / n;
        final tb = tc - half + 2 * half * (k + 1) / n;
        final path = poly([
          wallPt(ta, 46),
          wallPt(tb, 46),
          wallPt(tb, 37) + out,
          wallPt(ta, 37) + out,
        ]);
        gradient(
          path,
          k.isEven ? stripeA : stripeB,
          _shade(k.isEven ? stripeA : stripeB, 0.14),
        );
      }
      // Kenar pervazı.
      line(wallPt(tc - half, 37) + out, wallPt(tc + half, 37) + out,
          _shade(stripeA, 0.25), 2);
    }

    // Arcade: cephe boyunca yanıp sönen ampuller.
    if (b.kind == DoorKind.arcade) {
      final count = b.w * 4;
      for (var k = 0; k < count; k++) {
        final t = (k + 0.5) / count;
        final on = ((world.time * 3).floor() + k).isEven;
        canvas.drawCircle(
          frontA + (frontB - frontA) * t + const Offset(0, -wallH + 3),
          1.9,
          Paint()..color = on ? const Color(0xFFFFEE58) : const Color(0xFFFF4081),
        );
      }
    }

    // ── Çatı (kirişli, saçak taşmalı).
    const o = 0.16;
    final e00 = pt(x0 - o, y0 - o, wallH);
    final e10 = pt(x1 + o, y0 - o, wallH);
    final e11 = pt(x1 + o, y1 + o, wallH);
    final e01 = pt(x0 - o, y1 + o, wallH);
    const top = wallH + roofH;
    final alongX = b.w >= b.h;
    final d = (alongX ? b.w - b.h : b.h - b.w) / 2;
    final r1 = alongX ? pt(cx - d, cy, top) : pt(cx, cy - d, top);
    final r2 = alongX ? pt(cx + d, cy, top) : pt(cx, cy + d, top);

    // Saçak kalınlığı.
    const fascia = Offset(0, 5);
    fill(poly([e01, e11, e11 + fascia, e01 + fascia]), _shade(roof, 0.42));
    fill(poly([e11, e10, e10 + fascia, e11 + fascia]), _shade(roof, 0.55));

    final left = alongX ? [e01, e00, r1] : [e00, e01, r2, r1];
    final back = alongX ? [e00, e10, r2, r1] : [e00, e10, r1];
    final right = alongX ? [e10, e11, r2] : [e10, e11, r2, r1];
    final front = alongX ? [e11, e01, r1, r2] : [e01, e11, r2];
    fill(poly(left), _shade(roof, 0.5));
    fill(poly(back), _shade(roof, 0.55));
    gradient(poly(right), _shade(roof, 0.22), _shade(roof, 0.42));
    gradient(poly(front), _shade(roof, -0.02), _shade(roof, 0.2));

    // Kiremit sıraları ve sırt.
    void courses(Offset ea, Offset eb, Offset ra, Offset rb, double alpha) {
      final paint = Paint()
        ..color = Color.fromRGBO(0, 0, 0, alpha)
        ..strokeWidth = 1;
      for (var k = 1; k <= 4; k++) {
        final t = k / 5;
        canvas.drawLine(Offset.lerp(ea, ra, t)!, Offset.lerp(eb, rb, t)!, paint);
      }
    }

    if (alongX) {
      courses(e11, e01, r2, r1, 0.16);
      courses(e10, e11, r2, r2, 0.2);
    } else {
      courses(e01, e11, r2, r2, 0.16);
      courses(e10, e11, r1, r2, 0.2);
    }
    // Ön saçak parlak kenar çizgisi.
    line(e01, e11, _shade(roof, -0.3), 1.6);
    line(e11, e10, _shade(roof, -0.1), 1.4);
    if ((r1 - r2).distance > 1) {
      line(r1, r2, _shade(roof, 0.35), 3);
      line(r1, r2, _shade(roof, -0.25), 1);
    }

    // Baca (ev).
    if (b.kind == DoorKind.home) {
      final bx = x0 + b.w * 0.28, by = cy - 0.05;
      const bw = 0.34, z0 = wallH + roofH * 0.5, z1 = z0 + 28;
      final base = [
        pt(bx, by + bw, z0),
        pt(bx + bw, by + bw, z0),
        pt(bx + bw, by, z0),
      ];
      fill(poly([base[0], base[1], base[1] + const Offset(0, -28), base[0] + const Offset(0, -28)]),
          const Color(0xFFB0574A));
      fill(poly([base[1], base[2], base[2] + const Offset(0, -28), base[1] + const Offset(0, -28)]),
          const Color(0xFF8A3F35));
      fill(
        poly([
          pt(bx - 0.04, by + bw + 0.04, z1),
          pt(bx + bw + 0.04, by + bw + 0.04, z1),
          pt(bx + bw + 0.04, by - 0.04, z1),
          pt(bx - 0.04, by - 0.04, z1),
        ]),
        const Color(0xFF6D2F27),
      );
      // Duman.
      for (var k = 0; k < 3; k++) {
        final phase = (world.time * 0.7 + k / 3) % 1;
        canvas.drawCircle(
          pt(bx + bw / 2, by + bw / 2, z1) + Offset(sin(phase * 5 + k) * 4, -phase * 26),
          3 + phase * 5,
          Paint()..color = Color.fromRGBO(255, 255, 255, 0.5 * (1 - phase)),
        );
      }
    }

    // Çatı tabelası: yuvarlak levha (yazı tipine bağlı emoji yerine paketli ikon
    // fontu; emoji yazı tipi geç yüklenirse önbellekteki çizim kutucuk gösterirdi).
    final signAt = alongX
        ? Offset.lerp((e11 + e01) / 2, (r1 + r2) / 2, 0.5)!
        : Offset.lerp((e01 + e11) / 2, r2, 0.5)!;
    canvas.drawCircle(signAt + const Offset(0, 1.5), 17, Paint()..color = const Color(0x44000000));
    canvas.drawCircle(signAt, 16, Paint()..color = _shade(roof, -0.05));
    canvas.drawCircle(
      signAt,
      16,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _paintIcon(canvas, _signIcon(b.kind), signAt, 22);
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
