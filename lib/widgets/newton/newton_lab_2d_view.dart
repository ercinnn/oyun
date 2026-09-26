import 'package:flutter/material.dart';

import '../../models/newton/cart.dart';
import '../../models/newton/falling.dart';
import '../../models/newton/newton_scene.dart';
import '../../models/newton/prism.dart';
import '../../models/science/science_task.dart' show formatTr;

/// Newton laboratuvarının 2B yan kesiti: 3B görünümün (`NewtonLab3DView`)
/// yedeği; testler ve 3B kapalı derlemeler bunu kullanır. Deney saati
/// gerçek süreyle ilerler (sonlu animasyon, `pumpAndSettle` biter) ve
/// konumlar modelden okunur.
class NewtonLab2DView extends StatelessWidget {
  const NewtonLab2DView({super.key, required this.scene});

  final NewtonScene scene;

  @override
  Widget build(BuildContext context) {
    final running = scene.run > 0;
    final seconds = running ? scene.duration : 0.0;
    return ClipRect(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('newton-${scene.station.name}-${scene.run}'),
        tween: Tween(begin: 0, end: seconds),
        duration: Duration(milliseconds: (seconds * 1000).round()),
        builder: (context, t, _) => CustomPaint(
          painter: _NewtonPainter(scene, t),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _NewtonPainter extends CustomPainter {
  _NewtonPainter(this.scene, this.t);

  final NewtonScene scene;

  /// Deney başladığından beri geçen süre (s).
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    switch (scene.station) {
      case NewtonStation.fall:
        _paintFall(canvas, size);
      case NewtonStation.prism:
        _paintPrism(canvas, size);
      case NewtonStation.cart:
        _paintCart(canvas, size);
    }
  }

  // ─────────────────────────── Düşme ───────────────────────────

  void _paintFall(Canvas canvas, Size size) {
    final env = scene.environment;
    final moon = env == FallEnvironment.moon;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = moon ? const Color(0xFF0B1020) : const Color(0xFFE3F2FD),
    );
    final groundY = size.height - 24;
    canvas.drawRect(
      Rect.fromLTRB(0, groundY, size.width, size.height),
      Paint()..color = moon ? const Color(0xFF9E9E9E) : const Color(0xFF7CB342),
    );
    final topY = 34.0;
    final cx = size.width / 2;
    final tower = Paint()
      ..color = const Color(0xFFA9713F)
      ..strokeWidth = 4;
    canvas.drawLine(Offset(cx, groundY), Offset(cx, topY - 10), tower);
    canvas.drawLine(Offset(cx - 90, topY - 10), Offset(cx + 90, topY - 10), tower);
    if (env == FallEnvironment.vacuum) {
      canvas.drawRect(
        Rect.fromLTRB(cx - 120, topY - 24, cx + 120, groundY),
        Paint()
          ..color = const Color(0x5581D4FA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final objects = [scene.fallA, scene.fallB];
    for (var i = 0; i < objects.length; i++) {
      final o = objects[i];
      if (o == null) continue;
      final d = scene.run > 0 ? fallDistance(o, t, env) : 0.0;
      final y = topY + (groundY - topY - 14) * d / towerHeightM;
      final x = cx + (i == 0 ? -70.0 : 70.0);
      _text(canvas, o.emoji, Offset(x, y + 4), 26, Colors.black, center: true);
      _text(canvas, i == 0 ? 'A' : 'B', Offset(x, topY - 30), 14,
          moon ? Colors.white : Colors.black87,
          center: true);
      if (scene.run > 0 && d >= towerHeightM - 1e-6) {
        _text(canvas, '${formatTr(fallTime(o, env))} sn', Offset(x, groundY + 4),
            12, Colors.white, center: true);
      }
    }
    _text(canvas, env.label, const Offset(10, 8), 13,
        moon ? Colors.white : Colors.black87);
  }

  // ─────────────────────────── Prizma ───────────────────────────

  void _paintPrism(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF263238));
    final midY = size.height / 2;
    final lamp = Offset(size.width * 0.08, midY);
    final prism = Offset(size.width * 0.38, midY);
    final screenX = size.width * 0.9;
    // Fener ve prizma.
    canvas.drawRect(
      Rect.fromCenter(center: lamp, width: 30, height: 40),
      Paint()..color = const Color(0xFF607D8B),
    );
    _triangle(canvas, prism, 34, up: true);
    final second = Offset(size.width * 0.52, midY);
    if (scene.secondPrism) _triangle(canvas, second, 34, up: false);
    canvas.drawRect(
      Rect.fromLTRB(screenX, midY - 70, screenX + 8, midY + 70),
      Paint()..color = Colors.white,
    );
    if (scene.run == 0) return;

    final colors = scene.light.colors;
    final grow = (t / 0.6).clamp(0.0, 1.0);
    final inColor = scene.light.onlyColorId == null
        ? Colors.white
        : Color(0xFF000000 | colors.single.hex);
    canvas.drawLine(
      lamp,
      Offset.lerp(lamp, prism, grow)!,
      Paint()
        ..color = inColor
        ..strokeWidth = 3,
    );
    final fan = ((t - 0.6) / 0.6).clamp(0.0, 1.0);
    if (fan <= 0) return;
    final mean = spectrumColors.map(deviationDeg).reduce((a, b) => a + b) /
        spectrumColors.length;
    for (final c in colors) {
      // Aşağı doğru sapma ekranda büyütüldü (gerçek fark ~5°).
      final spread = (deviationDeg(c) - mean) * 10;
      final end = scene.secondPrism
          ? second
          : Offset(screenX, midY + spread + 10);
      canvas.drawLine(
        prism,
        Offset.lerp(prism, end, fan)!,
        Paint()
          ..color = Color(0xFF000000 | c.hex)
          ..strokeWidth = 2.5,
      );
      if (!scene.secondPrism && fan >= 1) {
        canvas.drawRect(
          Rect.fromCenter(center: end, width: 10, height: colors.length == 1 ? 14 : 8),
          Paint()..color = Color(0xFF000000 | c.hex),
        );
      }
    }
    if (scene.secondPrism && fan >= 1) {
      final end = Offset(screenX, midY);
      final out = Color(0xFF000000 | scene.prism.recombinedHex);
      canvas.drawLine(second, end, Paint()
        ..color = out
        ..strokeWidth = 3);
      canvas.drawCircle(end, 7, Paint()..color = out);
    }
  }

  void _triangle(Canvas canvas, Offset c, double r, {required bool up}) {
    final s = up ? 1 : -1;
    final path = Path()
      ..moveTo(c.dx, c.dy - r * s)
      ..lineTo(c.dx + r * 0.87, c.dy + r * 0.5 * s)
      ..lineTo(c.dx - r * 0.87, c.dy + r * 0.5 * s)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0x88B3E5FC));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFB3E5FC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  // ─────────────────────────── Araba ───────────────────────────

  void _paintCart(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEFEBE9));
    const left = 24.0;
    final right = size.width - 16;
    final pxPerM = (right - left) / trackLengthM;
    final lanes = [scene.laneA, scene.laneB];
    for (var i = 0; i < lanes.length; i++) {
      final lane = lanes[i];
      if (lane == null) continue;
      final y = size.height * (i == 0 ? 0.3 : 0.7);
      canvas.drawRect(
        Rect.fromLTRB(left, y - 16, right, y + 16),
        Paint()
          ..color = switch (lane.surface) {
            CartSurface.ice => const Color(0xFFE1F5FE),
            CartSurface.wood => const Color(0xFFC19A6B),
            CartSurface.carpet => const Color(0xFFB23A48),
          },
      );
      final x = scene.run > 0 ? cartPositionAt(lane, scene.push, t) : 0.0;
      final cartRect = Rect.fromLTWH(left + x * pxPerM, y - 12, 34, 20);
      canvas.drawRect(cartRect, Paint()..color = const Color(0xFF1E88E5));
      for (var b = 0; b < lane.boxes; b++) {
        canvas.drawRect(
          Rect.fromLTWH(cartRect.left + 2 + b * 10, cartRect.top - 10, 9, 9),
          Paint()..color = const Color(0xFFC68A4E),
        );
      }
      _text(canvas, '${i == 0 ? 'A' : 'B'} · ${lane.surface.label}',
          Offset(left, y - 34), 12, Colors.black87);
      if (scene.run > 0 && t >= cartTravelTime(lane, scene.push) - 1e-6) {
        _text(canvas, '${formatTr(cartDistance(lane, scene.push))} m',
            Offset(cartRect.right + 6, y - 8), 12, Colors.black87);
      }
    }
    final tick = Paint()
      ..color = Colors.black45
      ..strokeWidth = 1;
    for (var m = 0; m <= trackLengthM; m++) {
      final x = left + m * pxPerM;
      canvas.drawLine(Offset(x, size.height - 14), Offset(x, size.height - 6), tick);
    }
  }

  // ─────────────────────────── Yardımcı ───────────────────────────

  /// Emoji önbelleğe alınmadan her karede yerleştirilir (CLAUDE.md "Emoji
  /// tuzağı").
  void _text(
    Canvas canvas,
    String text,
    Offset at,
    double size,
    Color color, {
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: size, color: color, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center ? at - Offset(tp.width / 2, 0) : at);
  }

  @override
  bool shouldRepaint(_NewtonPainter old) => old.scene != scene || old.t != t;
}
