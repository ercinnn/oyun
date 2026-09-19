import 'dart:math';

import 'package:flutter/material.dart';

import '../models/plant_growth.dart';
import '../models/plant_species.dart';

/// Bir bitkiyi (saksı + gövde + yapraklar) [CustomPainter] ile çizer. Resim
/// dosyası kullanılmaz: boy, yaprak sayısı ve renk doğrudan [PlantSnapshot]'tan
/// gelir, bu yüzden aynı çizim her gün ve her koşul için çalışır.
class PlantView extends StatelessWidget {
  const PlantView({
    super.key,
    required this.species,
    required this.snapshot,
    this.height = 170,
  });

  final PlantSpecies species;
  final PlantSnapshot snapshot;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _PlantPainter(species, snapshot)),
    );
  }
}

/// Sağlık durumuna göre yaprak rengi.
Color plantLeafColor(PlantSnapshot snapshot) {
  switch (snapshot.health) {
    case PlantHealth.healthy:
      return Color.lerp(
        const Color(0xFF9CCC65),
        const Color(0xFF2E9E44),
        snapshot.vigor,
      )!;
    case PlantHealth.slow:
      return const Color(0xFF5DB96A);
    case PlantHealth.pale:
      return const Color(0xFFD8E6A3);
    case PlantHealth.wilted:
      return const Color(0xFFA9A552);
    case PlantHealth.rotting:
      return const Color(0xFFE3C43B);
    case PlantHealth.scorched:
      return const Color(0xFF9C7A5B);
    case PlantHealth.weak:
      return const Color(0xFFA5C48A);
  }
}

class _PlantPainter extends CustomPainter {
  _PlantPainter(this.species, this.snapshot);

  final PlantSpecies species;
  final PlantSnapshot snapshot;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final potHeight = size.height * 0.2;
    final potTopWidth = min(size.width * 0.5, 90.0);
    final potBottomWidth = potTopWidth * 0.72;
    final potTop = size.height - potHeight;

    _paintPot(canvas, size, cx, potTop, potTopWidth, potBottomWidth);

    final fraction = (snapshot.heightCm / species.maxHeightCm).clamp(0.06, 1.0);
    final maxLength = potTop - 10;
    final stemLength = maxLength * (0.10 + 0.90 * fraction);
    final color = plantLeafColor(snapshot);

    switch (species.shape) {
      case PlantShape.cactus:
        _paintCactus(canvas, size, cx, potTop, stemLength, fraction, color);
      case PlantShape.grass:
        _paintGrass(canvas, size, cx, potTop, stemLength, color);
      case PlantShape.leafy:
        _paintLeafy(canvas, size, cx, potTop, stemLength, fraction, color);
    }
  }

  void _paintPot(
    Canvas canvas,
    Size size,
    double cx,
    double potTop,
    double topWidth,
    double bottomWidth,
  ) {
    final path = Path()
      ..moveTo(cx - topWidth / 2, potTop)
      ..lineTo(cx + topWidth / 2, potTop)
      ..lineTo(cx + bottomWidth / 2, size.height)
      ..lineTo(cx - bottomWidth / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFB5651D));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, potTop),
          width: topWidth + 8,
          height: 8,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF9A5216),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, potTop + 1),
        width: topWidth - 6,
        height: 7,
      ),
      Paint()..color = const Color(0xFF5D4037),
    );
  }

  bool get _drooping =>
      snapshot.health == PlantHealth.wilted ||
      snapshot.health == PlantHealth.rotting;

  void _paintLeafy(
    Canvas canvas,
    Size size,
    double cx,
    double potTop,
    double stemLength,
    double fraction,
    Color leafColor,
  ) {
    final thin = snapshot.health == PlantHealth.pale;
    canvas.drawLine(
      Offset(cx, potTop),
      Offset(cx, potTop - stemLength),
      Paint()
        ..color = thin ? const Color(0xFFC5D68A) : const Color(0xFF558B2F)
        ..strokeWidth = thin ? 2 : 4
        ..strokeCap = StrokeCap.round,
    );

    final leafLength =
        min(size.width * 0.22, 12 + fraction * 22) *
        (snapshot.health == PlantHealth.slow || snapshot.health == PlantHealth.weak
            ? 0.7
            : 1.0);
    final paint = Paint()..color = leafColor;
    final count = snapshot.leafCount;

    for (var i = 0; i < count; i++) {
      final t = (i + 1) / (count + 1);
      final y = potTop - stemLength * t;
      final side = i.isEven ? 1.0 : -1.0;
      // Dik büyüyen yaprak yukarı, solmuş yaprak aşağı bakar.
      final up = _drooping ? -0.7 : 0.5;
      canvas.save();
      canvas.translate(cx, y);
      canvas.rotate(-side * up);
      canvas.drawOval(
        Rect.fromLTWH(
          side > 0 ? 0 : -leafLength,
          -leafLength * 0.22,
          leafLength,
          leafLength * 0.44,
        ),
        paint,
      );
      canvas.restore();
    }

    // Tepe yaprağı.
    canvas.drawCircle(
      Offset(cx, potTop - stemLength),
      leafLength * 0.28,
      paint,
    );
  }

  void _paintCactus(
    Canvas canvas,
    Size size,
    double cx,
    double potTop,
    double stemLength,
    double fraction,
    Color color,
  ) {
    final paint = Paint()..color = color;
    final width = max(14.0, size.width * 0.17);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - width / 2, potTop - stemLength, width, stemLength),
        Radius.circular(width / 2),
      ),
      paint,
    );

    if (fraction > 0.45) {
      final armWidth = width * 0.6;
      final armY = potTop - stemLength * 0.45;
      final armHeight = stemLength * 0.28;
      for (final side in [-1.0, 1.0]) {
        final left = side < 0
            ? cx - width / 2 - armWidth * 1.6
            : cx + width / 2 - 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, armY, armWidth * 1.6 + 2, armWidth),
            Radius.circular(armWidth / 2),
          ),
          paint,
        );
        final armLeft = side < 0 ? left : left + armWidth * 1.6 + 2 - armWidth;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(armLeft, armY - armHeight, armWidth, armHeight + armWidth),
            Radius.circular(armWidth / 2),
          ),
          paint,
        );
      }
    }
  }

  void _paintGrass(
    Canvas canvas,
    Size size,
    double cx,
    double potTop,
    double stemLength,
    Color color,
  ) {
    final blades = 3 + snapshot.leafCount;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < blades; i++) {
      final offset = (i - (blades - 1) / 2) * 0.16;
      final length = stemLength * (0.7 + 0.3 * ((i * 7) % 5) / 4);
      // Solmuş otlar yana doğru sarkar.
      final bend = _drooping ? 0.6 : 0.25;
      final tip = Offset(
        cx + sin(offset) * length * bend + (_drooping ? offset * 20 : 0),
        potTop - cos(offset) * length * (_drooping ? 0.75 : 1.0),
      );
      final path = Path()
        ..moveTo(cx + offset * 10, potTop)
        ..quadraticBezierTo(
          cx + offset * 10,
          potTop - length * 0.6,
          tip.dx,
          tip.dy,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) => true;
}
