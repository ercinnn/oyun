import 'dart:math';

import 'package:flutter/material.dart';

import '../../config/scientists_3d.dart';
import '../../models/galileo/galileo_scene.dart';
import '../../models/galileo/jupiter.dart';
import '../../models/galileo/solar.dart';
import '../../models/galileo/telescope.dart';
import 'galileo_insets.dart';
import 'galileo_lab_3d_view.dart';

/// Galileo gözlemevi: 3B açıksa `GalileoLab3DView`, değilse 2B yedek; ikisinin
/// de üstünde istasyona göre bir iç pencere (göz merceği, teleskop şeridi ya
/// da Dünya'dan Venüs). İç pencere ve 2B çizim, sahne değerlerine sonlu
/// animasyonlarla ilerler (`pumpAndSettle` biter).
class GalileoSceneView extends StatelessWidget {
  const GalileoSceneView({super.key, required this.scene});

  final GalileoScene scene;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _Tweened(
        scene: scene,
        builder: (tube, nights, day) => Stack(
          children: [
            Positioned.fill(
              child: scientistsUse3d
                  ? GalileoLab3DView(scene: scene)
                  : CustomPaint(
                      painter: _Galileo2DPainter(scene, tube, nights, day),
                    ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: _inset(tube, nights, day),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inset(double tube, double nights, double day) {
    switch (scene.station) {
      case GalileoStation.telescope:
        return EyepieceView(
          target: scene.target,
          magnification: scene.magnificationValue,
          focusError: focusErrorCm(scene.objectiveCm, scene.eyepieceCm, tube),
          size: 140,
        );
      case GalileoStation.jupiter:
        return JupiterStrip(
          nights: nights,
          highlightId: scene.highlightMoonId,
          width: 240,
        );
      case GalileoStation.solar:
        if (!scene.showVenusView) return const SizedBox.shrink();
        return VenusPhaseView(view: scene.venusViewAt(day), size: 120);
    }
  }
}

/// Tüp boyu, gece ve günü sahnedeki değerlerine doğru ilerletir.
class _Tweened extends StatelessWidget {
  const _Tweened({required this.scene, required this.builder});

  final GalileoScene scene;
  final Widget Function(double tube, double nights, double day) builder;

  static const _duration = Duration(milliseconds: 1400);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: scene.tubeCm),
      duration: const Duration(milliseconds: 500),
      builder: (context, tube, _) => TweenAnimationBuilder<double>(
        tween: Tween(end: scene.nights),
        duration: _duration,
        builder: (context, nights, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: scene.day),
          duration: _duration,
          builder: (context, day, _) => builder(tube, nights, day),
        ),
      ),
    );
  }
}

class _Galileo2DPainter extends CustomPainter {
  _Galileo2DPainter(this.scene, this.tube, this.nights, this.day);

  final GalileoScene scene;
  final double tube;
  final double nights;
  final double day;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0B1026));
    final star = Paint()..color = Colors.white54;
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset((i * 97 % 100) / 100 * size.width, (i * 61 % 100) / 100 * size.height),
        0.9,
        star,
      );
    }
    switch (scene.station) {
      case GalileoStation.telescope:
        _telescope(canvas, size);
      case GalileoStation.jupiter:
        _jupiter(canvas, size);
      case GalileoStation.solar:
        _solar(canvas, size);
    }
  }

  void _telescope(Canvas canvas, Size size) {
    // Yandan teleskop: dış tüp sabit, iç tüp tüp boyuna göre dışarı çıkar.
    final base = Offset(size.width * 0.62, size.height * 0.7);
    final outer = size.width * 0.28;
    final inner = outer * 0.6 * (tube - tubeMinCm) / (tubeMaxCm - tubeMinCm);
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(-0.4);
    canvas.drawRect(Rect.fromLTWH(-outer * 0.3, -9, outer, 18),
        Paint()..color = const Color(0xFF8B3A2B));
    canvas.drawRect(Rect.fromLTWH(-outer * 0.3 - inner, -6, inner + 4, 12),
        Paint()..color = const Color(0xFF5A2419));
    canvas.restore();
    final leg = Paint()
      ..color = const Color(0xFF5D3A22)
      ..strokeWidth = 3;
    canvas.drawLine(base, base + Offset(-20, size.height * 0.28), leg);
    canvas.drawLine(base, base + Offset(20, size.height * 0.28), leg);
  }

  void _jupiter(Canvas canvas, Size size) {
    // Yukarıdan bakış: yörüngeler elips (Dünya aşağıda).
    final c = Offset(size.width * 0.5, size.height * 0.42);
    final scale = min(size.width / 2.3, size.height / 1.1) / 14;
    canvas.drawCircle(c, scale * 1.4, Paint()..color = const Color(0xFFD7A86E));
    for (final m in jupiterMoons) {
      final r = (2.2 + m.distance * 0.42) * scale;
      canvas.drawOval(
        Rect.fromCenter(center: c, width: 2 * r, height: r * 0.8),
        Paint()
          ..color = const Color(0xFF33415E)
          ..style = PaintingStyle.stroke,
      );
      final a = m.angleAt(nights);
      final p = c + Offset(r * cos(a), r * 0.4 * sin(a));
      canvas.drawCircle(p, m.id == scene.highlightMoonId ? 5 : 3.5,
          Paint()..color = Color(0xFF000000 | m.color));
    }
  }

  void _solar(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.55, size.height * 0.4);
    final scale = min(size.width / 2.2, size.height / 1.0) / 8.6;
    canvas.drawCircle(c, scale * 0.9, Paint()..color = const Color(0xFFFFD54F));
    Offset? earth;
    Offset? venus;
    for (final p in planets) {
      final r = (3.2 * sqrt(p.orbitAu) + 0.8) * scale;
      canvas.drawOval(
        Rect.fromCenter(center: c, width: 2 * r, height: r * 1.1),
        Paint()
          ..color = const Color(0xFF33415E)
          ..style = PaintingStyle.stroke,
      );
      final a = p.id == 'venus' ? scene.venusAngleAt(day) : p.angleAt(day);
      final pos = c + Offset(r * cos(a), -r * 0.55 * sin(a));
      if (p.id == 'earth') earth = pos;
      if (p.id == 'venus') venus = pos;
      final hl = scene.highlightPlanetIds.contains(p.id);
      canvas.drawCircle(pos, hl ? 6 : 4, Paint()..color = Color(0xFF000000 | p.color));
    }
    if (scene.venusOffsetDeg != null && earth != null && venus != null) {
      canvas.drawLine(earth, venus, Paint()
        ..color = const Color(0xFF80DEEA)
        ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_Galileo2DPainter old) =>
      old.scene != scene || old.tube != tube || old.nights != nights || old.day != day;
}
