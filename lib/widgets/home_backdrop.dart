import 'package:flutter/material.dart';

import '../theme/home_palette.dart';

/// Ana menünün arka planı: köşeden köşeye koyu bir gradyan, üzerine çok soluk
/// bir teknik ızgara ve iki yumuşak ışık lekesi. Tamamı [CustomPainter] ile
/// çizilir (görsel asset yok, `pubspec.yaml`'a dokunmaz) ve
/// `shouldRepaint => false` olduğu için kaydırma sırasında yeniden boyanmaz.
class HomeBackdrop extends StatelessWidget {
  const HomeBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HomePalette.backdropTop,
            HomePalette.backdropMid,
            HomePalette.backdropBottom,
          ],
        ),
      ),
      child: CustomPaint(painter: _BackdropPainter(), child: child),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  static const _gridSpacing = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlow(
      canvas,
      size,
      center: Offset(size.width * 0.12, -size.height * 0.02),
      radius: size.shortestSide * 0.95,
      color: HomePalette.accent,
      alpha: 0.20,
    );
    _paintGlow(
      canvas,
      size,
      center: Offset(size.width * 0.98, size.height * 0.28),
      radius: size.shortestSide * 0.75,
      color: const Color(0xFF00C2C7),
      alpha: 0.10,
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.022)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += _gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += _gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _paintGlow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
    required double alpha,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
