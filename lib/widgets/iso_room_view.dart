import 'dart:math';

import 'package:flutter/material.dart';

import '../models/town/iso_projection.dart';
import '../models/town/room_layout.dart';
import '../models/town/shop_catalog.dart';

/// Odanın izometrik görünümü: zemin, iki arka duvar ve mobilyalar. Dokunulan
/// karoyu [onTapTile] bildirir; seçili eşya vurgulanır.
///
/// Kamera sabittir: odanın merkezi tuvalin ortasında, ölçek tuvale sığacak
/// biçimde hesaplanır — hem çizim hem dokunma aynı dönüşümü kullanır
/// ([tileAt]).
class IsoRoomView extends StatelessWidget {
  const IsoRoomView({
    super.key,
    required this.layout,
    required this.onTapTile,
    this.selectedIndex = -1,
  });

  final RoomLayout layout;
  final void Function(int x, int y) onTapTile;

  /// Seçili yerleştirilmiş eşyanın indeksi (-1: yok).
  final int selectedIndex;


  static const double _wallHeight = 84;
  static const double _unitHeight = 46; // mobilya yüksekliği: karo başına px

  /// Tuval boyutuna göre ölçek.
  static double _scale(Size size) {
    const worldWidth = roomSize * IsoProjection.tileW + 40;
    const worldHeight = roomSize * IsoProjection.tileH + _wallHeight + 60;
    return min(size.width / worldWidth, size.height / worldHeight);
  }

  static Offset _origin(Size size) {
    // Odanın merkezi (4,4) tuvalin ortasında; duvarlar için biraz aşağı kaydır.
    final center = IsoProjection.toScreen(roomSize / 2, roomSize / 2);
    return size.center(Offset.zero) - center * _scale(size) + Offset(0, _wallHeight * _scale(size) / 2);
  }

  /// Tuvaldeki bir noktanın oda karosu (oda dışındaysa null).
  static (int, int)? tileAt(Offset local, Size size) {
    final scale = _scale(size);
    final world = (local - _origin(size)) / scale;
    final tile = IsoProjection.toTile(world.dx, world.dy);
    final x = tile.dx.floor();
    final y = tile.dy.floor();
    if (x < 0 || y < 0 || x >= roomSize || y >= roomSize) return null;
    return (x, y);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          key: const Key('roomTap'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final tile = tileAt(details.localPosition, size);
            if (tile != null) onTapTile(tile.$1, tile.$2);
          },
          child: CustomPaint(
            size: Size.infinite,
            painter: _RoomPainter(layout, selectedIndex),
          ),
        );
      },
    );
  }
}

class _RoomPainter extends CustomPainter {
  _RoomPainter(this.layout, this.selectedIndex);

  final RoomLayout layout;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFECEFF1));

    final scale = IsoRoomView._scale(size);
    canvas.save();
    canvas.translate(IsoRoomView._origin(size).dx, IsoRoomView._origin(size).dy);
    canvas.scale(scale);

    final floor = Color(roomFloorColors[layout.floorColor]);
    final wall = Color(roomWallColors[layout.wallColor]);
    _paintWalls(canvas, wall);
    _paintFloor(canvas, floor);
    _paintItems(canvas);

    canvas.restore();
  }

  Path _quad(Offset a, Offset b, Offset c, Offset d) => Path()
    ..moveTo(a.dx, a.dy)
    ..lineTo(b.dx, b.dy)
    ..lineTo(c.dx, c.dy)
    ..lineTo(d.dx, d.dy)
    ..close();

  void _paintWalls(Canvas canvas, Color wall) {
    const h = IsoRoomView._wallHeight;
    final up = const Offset(0, -h);
    final n = roomSize.toDouble();
    final p00 = IsoProjection.toScreen(0, 0);
    final pX = IsoProjection.toScreen(n, 0); // kuzeydoğu duvarı ucu
    final pY = IsoProjection.toScreen(0, n); // kuzeybatı duvarı ucu

    final paint = Paint()..color = Color.lerp(wall, const Color(0xFF000000), 0.08)!;
    canvas.drawPath(_quad(p00, pX, pX + up, p00 + up), paint);
    paint.color = Color.lerp(wall, const Color(0xFF000000), 0.02)!;
    canvas.drawPath(_quad(p00, pY, pY + up, p00 + up), paint);
    // Süpürgelik.
    paint.color = const Color(0x22000000);
    canvas.drawPath(_quad(p00, pX, pX + const Offset(0, -8), p00 + const Offset(0, -8)), paint);
    canvas.drawPath(_quad(p00, pY, pY + const Offset(0, -8), p00 + const Offset(0, -8)), paint);
  }

  void _paintFloor(Canvas canvas, Color floor) {
    final paint = Paint();
    for (var y = 0; y < roomSize; y++) {
      for (var x = 0; x < roomSize; x++) {
        paint.color = Color.lerp(floor, const Color(0xFF000000), (x + y).isEven ? 0 : 0.06)!;
        canvas.drawPath(_tile(x.toDouble(), y.toDouble(), 1, 1), paint);
      }
    }
  }

  Path _tile(double x, double y, double w, double d) => _quad(
    IsoProjection.toScreen(x, y),
    IsoProjection.toScreen(x + w, y),
    IsoProjection.toScreen(x + w, y + d),
    IsoProjection.toScreen(x, y + d),
  );

  void _paintItems(Canvas canvas) {
    final entries = <(double, int)>[];
    for (var i = 0; i < layout.items.length; i++) {
      final item = shopItemById(layout.items[i].itemId);
      if (item == null) continue;
      final (w, d) = RoomLayout.footprint(item, layout.items[i].rotation);
      // Zemin eşyaları (halı) en arkada; kutular ön köşe toplamına göre.
      final depth = RoomLayout.isFlat(item)
          ? -1.0
          : (layout.items[i].x + w - 1 + layout.items[i].y + d - 1).toDouble();
      entries.add((depth, i));
    }
    entries.sort((a, b) => a.$1.compareTo(b.$1));

    for (final (_, index) in entries) {
      _paintItem(canvas, layout.items[index], index == selectedIndex);
    }
  }

  void _paintItem(Canvas canvas, PlacedItem placed, bool selected) {
    final item = shopItemById(placed.itemId);
    if (item == null) return;
    final (w, d) = RoomLayout.footprint(item, placed.rotation);
    final x = placed.x.toDouble();
    final y = placed.y.toDouble();
    final color = Color(item.colorValue);
    final paint = Paint();

    if (RoomLayout.isFlat(item)) {
      paint.color = color;
      canvas.drawPath(_tile(x, y, w.toDouble(), d.toDouble()), paint);
      paint
        ..color = const Color(0x55FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(_tile(x + 0.15, y + 0.15, w - 0.3, d - 0.3), paint);
    } else {
      final up = Offset(0, -item.height * IsoRoomView._unitHeight);
      final p00 = IsoProjection.toScreen(x, y);
      final p10 = IsoProjection.toScreen(x + w, y);
      final p11 = IsoProjection.toScreen(x + w, y + d);
      final p01 = IsoProjection.toScreen(x, y + d);
      paint.color = const Color(0x22000000);
      canvas.drawPath(_quad(p00 + const Offset(4, 3), p10 + const Offset(4, 3), p11 + const Offset(4, 3), p01 + const Offset(4, 3)), paint);
      paint.color = Color.lerp(color, const Color(0xFF000000), 0.12)!;
      canvas.drawPath(_quad(p01, p11, p11 + up, p01 + up), paint);
      paint.color = Color.lerp(color, const Color(0xFF000000), 0.3)!;
      canvas.drawPath(_quad(p11, p10, p10 + up, p11 + up), paint);
      paint.color = Color.lerp(color, const Color(0xFFFFFFFF), 0.18)!;
      canvas.drawPath(_quad(p00 + up, p10 + up, p11 + up, p01 + up), paint);
      _emoji(canvas, item.emoji, (p00 + p11) / 2 + up, 24);
    }

    if (selected) {
      final outline = Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawPath(_tile(x, y, w.toDouble(), d.toDouble()), outline);
    }
  }

  /// Emoji yazı tipi geç yüklenebildiği için düzen önbelleğe alınmaz (aksi
  /// halde ilk karedeki kutucuk kalıcı olurdu); eşya sayısı azdır.
  void _emoji(Canvas canvas, String emoji, Offset center, double size) {
    final painter = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) => true;
}
