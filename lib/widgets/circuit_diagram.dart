import 'dart:math';

import 'package:flutter/material.dart';

import '../models/circuit_simulation.dart';
import '../models/circuit_spec.dart';

/// Basit pil-ampul devresinin şeması ([CustomPainter], resim yok).
///
/// [result] verilmezse (soru gösterilirken) ampuller nötr çizilir; verilirse
/// akım varsa teller sarı olur ve ampuller [glow] (0-1) oranında parlar.
/// [glow] bir animasyonla 0'dan 1'e çıkarılırsa ampuller yavaşça ışır.
class CircuitDiagram extends StatelessWidget {
  const CircuitDiagram({
    super.key,
    required this.spec,
    this.result,
    this.glow = 1,
    this.height = 180,
  });

  final CircuitSpec spec;
  final CircuitResult? result;
  final double glow;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _CircuitPainter(spec, result, glow)),
    );
  }
}

/// [CircuitDiagram]'ı açılışta 0'dan 1'e sonlu bir animasyonla ışıtan sarmal.
/// Anahtarı ([key]) değişince animasyon baştan başlar.
class AnimatedCircuitDiagram extends StatelessWidget {
  const AnimatedCircuitDiagram({
    super.key,
    required this.spec,
    required this.result,
  });

  final CircuitSpec spec;
  final CircuitResult result;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, _) =>
          CircuitDiagram(spec: spec, result: result, glow: value),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  _CircuitPainter(this.spec, this.result, this.glow);

  final CircuitSpec spec;
  final CircuitResult? result;
  final double glow;

  static const _wireOff = Color(0xFF78909C);
  static const _wireOn = Color(0xFFF9A825);

  @override
  void paint(Canvas canvas, Size size) {
    final left = 28.0;
    final right = size.width - 20;
    final top = 26.0;
    final bottom = size.height - 26;
    final cy = (top + bottom) / 2;
    final flowing = result?.closed ?? false;
    final wire = Paint()
      ..color = flowing ? _wireOn : _wireOff
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), wire);

    // ── Pil (sol kenar) ──
    final cellHeight = 9.0;
    final batteryHeight = spec.batteries * (cellHeight + 3);
    final batteryTop = cy - batteryHeight / 2;
    line(left, top, left, batteryTop);
    line(left, batteryTop + batteryHeight, left, bottom);
    for (var i = 0; i < spec.batteries; i++) {
      final y = batteryTop + i * (cellHeight + 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left - 12, y, 24, cellHeight),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF455A64),
      );
    }
    _text(canvas, '+', Offset(left + 16, batteryTop - 4), 13);

    // ── Anahtar (üst kenar) ──
    final switchX = left + (right - left) * 0.25;
    line(left, top, switchX - 14, top);
    if (spec.switchClosed) {
      line(switchX - 14, top, switchX + 14, top);
    } else {
      line(switchX - 14, top, switchX + 8, top - 15);
    }
    canvas.drawCircle(Offset(switchX - 14, top), 3.5, Paint()..color = _wireOff);
    canvas.drawCircle(Offset(switchX + 14, top), 3.5, Paint()..color = _wireOff);

    // ── Boşluk (alt kenar) ──
    final gapX = (left + right) / 2 - 30;
    final material = spec.material;
    if (material == null) {
      line(left, bottom, right, bottom);
    } else {
      line(left, bottom, gapX - 18, bottom);
      final blocked = !material.conductive;
      final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(gapX - 18, bottom - 15, 36, 30),
        const Radius.circular(6),
      );
      canvas.drawRRect(box, Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawRRect(
        box,
        Paint()
          ..color = blocked ? const Color(0xFFE53935) : const Color(0xFF2E7D32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _text(canvas, material.emoji, Offset(gapX - 10, bottom - 11), 20);
      final rightWire = Paint()
        ..color = (flowing && !blocked) ? _wireOn : _wireOff
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(gapX + 18, bottom), Offset(right, bottom), rightWire);
    }

    // ── Ampuller (sağ taraf) ──
    final n = spec.lampCount;
    double lampY(int i) => top + (bottom - top) * (i + 1) / (n + 1);

    if (spec.layout == LampLayout.series) {
      line(switchX + 14, top, right, top);
      line(right, top, right, bottom);
      for (var i = 0; i < n; i++) {
        _lamp(canvas, Offset(right, lampY(i)), i);
      }
    } else {
      final rail1 = right - 70;
      line(switchX + 14, top, rail1, top);
      line(rail1, top, rail1, lampY(n - 1));
      line(right, lampY(0), right, bottom);
      for (var i = 0; i < n; i++) {
        line(rail1, lampY(i), right, lampY(i));
        _lamp(canvas, Offset(rail1 + 35, lampY(i)), i);
      }
    }
  }

  void _lamp(Canvas canvas, Offset center, int index) {
    const radius = 12.0;
    final state = result?.states[index];
    final brightness = (result?.brightness[index] ?? 0) * glow;

    if (state != null && state.isLit && brightness > 0) {
      canvas.drawCircle(
        center,
        radius + 10 * brightness,
        Paint()..color = Color.fromRGBO(255, 193, 7, 0.55 * brightness),
      );
    }

    final Color fill;
    if (state == LampState.burnt) {
      fill = const Color(0xFF424242);
    } else if (state != null && state.isLit) {
      fill = Color.lerp(const Color(0xFFEEEEEE), const Color(0xFFFFD54F), brightness)!;
    } else {
      fill = const Color(0xFFEEEEEE);
    }
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF616161)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Filaman ya da patlak ampulün çarpısı.
    if (state == LampState.burnt) {
      final x = Paint()
        ..color = const Color(0xFFE53935)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center + const Offset(-7, -7), center + const Offset(7, 7), x);
      canvas.drawLine(center + const Offset(-7, 7), center + const Offset(7, -7), x);
    } else {
      final path = Path()
        ..moveTo(center.dx - 6, center.dy + 4)
        ..lineTo(center.dx - 3, center.dy - 4)
        ..lineTo(center.dx + 3, center.dy + 4)
        ..lineTo(center.dx + 6, center.dy - 4);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF757575)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _text(Canvas canvas, String text, Offset offset, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: const Color(0xFF37474F)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _CircuitPainter oldDelegate) => true;
}

/// Ampullerin durumlarını yazıyla listeler ("Ampul 1: Normal parlak").
class LampStateList extends StatelessWidget {
  const LampStateList({super.key, required this.result});

  final CircuitResult result;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      children: [
        for (var i = 0; i < result.states.length; i++)
          Text('Ampul ${i + 1}: ${result.states[i].label}', style: style),
      ],
    );
  }
}

/// Pilin ne kadar çabuk biteceğini gösteren küçük çubuk.
class BatteryDrainBar extends StatelessWidget {
  const BatteryDrainBar({super.key, required this.result});

  final CircuitResult result;

  @override
  Widget build(BuildContext context) {
    final value = min(1.0, result.current / 4.5);
    final label = result.current == 0
        ? 'Pil harcanmıyor'
        : (value > 0.6 ? 'Pil çabuk biter' : 'Pil normal harcanıyor');
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: value, minHeight: 8),
        ),
      ],
    );
  }
}
