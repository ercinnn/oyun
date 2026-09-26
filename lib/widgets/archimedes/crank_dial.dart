import 'dart:math';

import 'package:flutter/material.dart';

/// Arşimet vidasının çevrilebilir kolu: parmakla (ya da fareyle) daire
/// çizerek çevrilir. Yalnızca **saat yönündeki** dönüş suyu yukarı taşır;
/// ters çevirmek kolu döndürür ama [onTurn]'e bildirilmez.
class CrankDial extends StatefulWidget {
  const CrankDial({super.key, required this.onTurn, this.size = 132});

  /// Saat yönünde yapılan dönüş (tur cinsinden, > 0).
  final ValueChanged<double> onTurn;
  final double size;

  @override
  State<CrankDial> createState() => _CrankDialState();
}

class _CrankDialState extends State<CrankDial> {
  double _angle = 0;
  double? _lastPointerAngle;

  double _pointerAngle(Offset local) {
    final c = Offset(widget.size / 2, widget.size / 2);
    return atan2(local.dy - c.dy, local.dx - c.dx);
  }

  void _update(Offset local) {
    final a = _pointerAngle(local);
    final last = _lastPointerAngle;
    _lastPointerAngle = a;
    if (last == null) return;
    var delta = a - last;
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;
    setState(() => _angle += delta);
    // Ekran koordinatında y aşağı doğru: pozitif açı = saat yönü.
    if (delta > 0) widget.onTurn(delta / (2 * pi));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Vidanın kolu: çevirmek için daire çiz',
      child: GestureDetector(
        onPanStart: (d) => _lastPointerAngle = _pointerAngle(d.localPosition),
        onPanUpdate: (d) => _update(d.localPosition),
        onPanEnd: (_) => _lastPointerAngle = null,
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(painter: _CrankPainter(_angle)),
        ),
      ),
    );
  }
}

class _CrankPainter extends CustomPainter {
  _CrankPainter(this.angle);

  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r - 2, Paint()..color = const Color(0xFFEFE3D0));
    canvas.drawCircle(
      c,
      r - 2,
      Paint()
        ..color = const Color(0xFF7A4E2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    // Saat yönü okları.
    final arrow = Paint()
      ..color = const Color(0x557A4E2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var k = 0; k < 3; k++) {
      final start = k * 2 * pi / 3;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.78),
        start,
        1.3,
        false,
        arrow,
      );
      final tip = c + Offset(cos(start + 1.3), sin(start + 1.3)) * r * 0.78;
      canvas.drawCircle(tip, 4, Paint()..color = const Color(0x777A4E2A));
    }
    final handle = c + Offset(cos(angle), sin(angle)) * r * 0.55;
    canvas.drawLine(
      c,
      handle,
      Paint()
        ..color = const Color(0xFF546E7A)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, 9, Paint()..color = const Color(0xFF37474F));
    canvas.drawCircle(handle, 15, Paint()..color = const Color(0xFF7A4E2A));
  }

  @override
  bool shouldRepaint(_CrankPainter old) => old.angle != angle;
}
