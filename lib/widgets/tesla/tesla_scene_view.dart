import 'dart:math';

import 'package:flutter/material.dart';

import '../../config/scientists_3d.dart';
import '../../models/science/science_task.dart' show formatTr;
import '../../models/tesla/generator.dart';
import '../../models/tesla/tesla_scene.dart';
import '../../models/tesla/transmission.dart';
import '../../models/tesla/wireless.dart';
import 'tesla_lab_3d_view.dart';

/// Tesla laboratuvarı: 3B açıksa `TeslaLab3DView`, değilse 2B yedek; ikisinin
/// de üstünde istasyona göre bir gösterge (osiloskop, şehir, lamba).
///
/// 2B çizim ve göstergeler **durağandır** (sürekli animasyon yok): jeneratörün
/// dalgası iki saniyelik bir resim olarak çizilir. Dönme ve yanıp sönme
/// yalnızca 3B'dedir — testlerde `pumpAndSettle` bitsin diye.
class TeslaSceneView extends StatelessWidget {
  const TeslaSceneView({super.key, required this.scene});

  final TeslaScene scene;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: scientistsUse3d
                ? TeslaLab3DView(scene: scene)
                : CustomPaint(painter: _Tesla2DPainter(scene)),
          ),
          Positioned(left: 8, bottom: 8, child: _inset()),
        ],
      ),
    );
  }

  Widget _inset() => switch (scene.station) {
    TeslaStation.generator => OscilloscopeView(
      source: scene.source,
      turnsPerSecond: scene.turnsPerSecond,
    ),
    TeslaStation.transmission => CityMeter(scene: scene),
    TeslaStation.wireless => LampMeter(level: scene.lampLevel),
  };
}

/// Osiloskop: iki saniyelik gerilim dalgası + ters bağlı iki LED'in durumu.
class OscilloscopeView extends StatelessWidget {
  const OscilloscopeView({
    super.key,
    required this.source,
    required this.turnsPerSecond,
  });

  final PowerSource source;
  final double turnsPerSecond;

  @override
  Widget build(BuildContext context) {
    final pattern = ledPattern(source, turnsPerSecond);
    return _Panel(
      key: const Key('teslaScope'),
      children: [
        SizedBox(
          width: 220,
          height: 90,
          child: CustomPaint(painter: _ScopePainter(source, turnsPerSecond)),
        ),
        const SizedBox(height: 4),
        Text(
          source == PowerSource.battery
              ? 'Sabit ${formatTr(batteryVolts)} V · LED: ${pattern.label.toLowerCase()}'
              : 'Tepe ${formatTr(peakVolts(turnsPerSecond))} V · saniyede '
                    '${formatTr(turnsPerSecond)} dalga · LED: ${pattern.label.toLowerCase()}',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ],
    );
  }
}

class _ScopePainter extends CustomPainter {
  _ScopePainter(this.source, this.turnsPerSecond);

  final PowerSource source;
  final double turnsPerSecond;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0B2A12));
    final grid = Paint()
      ..color = const Color(0x3322FF66)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(Offset(size.width * i / 4, 0), Offset(size.width * i / 4, size.height), grid);
    }
    final mid = size.height / 2;
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), grid..color = const Color(0x6622FF66));
    // Ölçek: en yüksek tepe (3 tur/sn) kutuyu doldurur.
    final vMax = peakVolts(maxTurnsPerSecond);
    final path = Path();
    const seconds = 2.0;
    for (var i = 0; i <= 200; i++) {
      final t = seconds * i / 200;
      final v = voltsAt(source, turnsPerSecond, t);
      final p = Offset(size.width * i / 200, mid - v / vMax * (mid - 4));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF69F0AE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ScopePainter old) =>
      old.source != source || old.turnsPerSecond != turnsPerSecond;
}

/// Şehir: ulaşan enerji ve yanan evler.
class CityMeter extends StatelessWidget {
  const CityMeter({super.key, required this.scene});

  final TeslaScene scene;

  @override
  Widget build(BuildContext context) {
    final lit = scene.houses;
    return _Panel(
      key: const Key('teslaCity'),
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < cityHouses; i++)
              Icon(
                Icons.home,
                size: 18,
                color: i < lit ? const Color(0xFFFFE082) : const Color(0xFF546E7A),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${formatTr(scene.lineV, digits: 0)} V · ${formatTr(scene.distanceKm)} km · '
          'ulaşan %${formatTr(deliveredPercent(scene.lineV, scene.distanceKm), digits: 0)} · '
          '$lit/$cityHouses ev',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ],
    );
  }
}

/// Kablosuz lambanın parlaklığı.
class LampMeter extends StatelessWidget {
  const LampMeter({super.key, required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final lit = lampLit(level);
    return _Panel(
      key: const Key('teslaLampMeter'),
      children: [
        SizedBox(
          width: 180,
          child: LinearProgressIndicator(
            value: level,
            minHeight: 8,
            color: const Color(0xFF80DEEA),
            backgroundColor: const Color(0xFF37474F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lamba ${lit ? 'yanıyor' : 'sönük'} · parlaklık %${(level * 100).round()}',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xCC101418),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

/// 2B yedek: istasyonun durağan şeması.
class _Tesla2DPainter extends CustomPainter {
  _Tesla2DPainter(this.scene);

  final TeslaScene scene;

  @override
  void paint(Canvas canvas, Size size) {
    switch (scene.station) {
      case TeslaStation.generator:
        _generator(canvas, size);
      case TeslaStation.transmission:
        _city(canvas, size);
      case TeslaStation.wireless:
        _coil(canvas, size);
    }
  }

  void _generator(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF3E2F2A));
    final c = Offset(size.width * 0.45, size.height * 0.35);
    if (scene.source == PowerSource.generator) {
      canvas.drawRect(Rect.fromCenter(center: c - const Offset(0, 50), width: 110, height: 16),
          Paint()..color = const Color(0xFFD32F2F));
      canvas.drawRect(Rect.fromCenter(center: c + const Offset(0, 50), width: 110, height: 16),
          Paint()..color = const Color(0xFF1976D2));
      canvas.drawRect(
        Rect.fromCenter(center: c, width: 80, height: 70),
        Paint()
          ..color = const Color(0xFFC77B30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    } else {
      canvas.drawRect(Rect.fromCenter(center: c, width: 40, height: 80),
          Paint()..color = const Color(0xFF37474F));
    }
    final glow = bulbBrightness(scene.source, scene.turnsPerSecond);
    final bulb = Offset(size.width * 0.8, size.height * 0.3);
    canvas.drawCircle(bulb, 22 + 14 * glow,
        Paint()..color = Color.lerp(const Color(0x00FFF59D), const Color(0x99FFF59D), glow)!);
    canvas.drawCircle(bulb, 16,
        Paint()..color = Color.lerp(const Color(0xFF9E9A8A), const Color(0xFFFFF59D), glow)!);
  }

  void _city(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFBFE3F5));
    final ground = size.height * 0.62;
    canvas.drawRect(Rect.fromLTRB(0, ground, size.width, size.height),
        Paint()..color = const Color(0xFF8BC34A));
    final loss = 1 - deliveredPercent(scene.lineV, scene.distanceKm) / 100;
    final wire = Paint()
      ..color = Color.lerp(const Color(0xFF455A64), const Color(0xFFFF5722), loss)!
      ..strokeWidth = 3;
    canvas.drawRect(Rect.fromLTWH(10, ground - 50, 50, 50), Paint()..color = const Color(0xFFBCAAA4));
    canvas.drawLine(Offset(60, ground - 60), Offset(size.width * 0.62, ground - 60), wire);
    final lit = scene.houses;
    for (var i = 0; i < cityHouses; i++) {
      final x = size.width * 0.66 + (i % 5) * 24.0;
      final y = ground - (i < 5 ? 34 : 14);
      canvas.drawRect(Rect.fromLTWH(x, y, 18, 16), Paint()..color = const Color(0xFFF1E3C8));
      canvas.drawRect(Rect.fromLTWH(x + 5, y + 4, 8, 7),
          Paint()..color = i < lit ? const Color(0xFFFFE082) : const Color(0xFF37474F));
    }
  }

  void _coil(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF14161F));
    final base = Offset(size.width * 0.25, size.height * 0.85);
    canvas.drawRect(Rect.fromLTWH(base.dx - 8, base.dy - 120, 16, 120),
        Paint()..color = const Color(0xFFECEFF1));
    canvas.drawOval(Rect.fromCenter(center: base - const Offset(0, 128), width: 60, height: 18),
        Paint()..color = const Color(0xFF90A4AE));
    if (scene.coilOn) {
      final spark = Paint()
        ..color = const Color(0xFFD1C4E9)
        ..strokeWidth = 1.5;
      for (var i = 0; i < 6; i++) {
        final a = i * pi / 3;
        canvas.drawLine(base - const Offset(0, 128),
            base - const Offset(0, 128) + Offset(cos(a) * 50, sin(a) * 25), spark);
      }
    }
    final x = base.dx + 40 + scene.lampDistanceM * (size.width * 0.6 / lampMaxM);
    final level = scene.lampLevel;
    canvas.drawRect(
      Rect.fromLTWH(x - 5, base.dy - 90, 10, 60),
      Paint()..color = Color.lerp(const Color(0xFF90A4AE), const Color(0xFFE0F7FF), (level * 1.4).clamp(0.0, 1.0))!,
    );
  }

  @override
  bool shouldRepaint(_Tesla2DPainter old) => old.scene != scene;
}
