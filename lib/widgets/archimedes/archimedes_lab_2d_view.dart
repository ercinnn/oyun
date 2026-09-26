import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/archimedes/archimedes_scene.dart';
import '../../models/archimedes/archimedes_screw.dart';
import '../../models/archimedes/buoyancy.dart';

/// Arşimet atölyesinin 2B yan kesiti: 3B görünümün (`ArchimedesLab3DView`)
/// yedeği. Testler ve 3B kapalı derlemeler bunu kullanır; aynı
/// [ArchimedesScene] verisini çizer.
///
/// Animasyonlar sonludur (`pumpAndSettle` biter): son bırakılan cisim
/// düşer, vida ve tarla yeni değerlerine doğru ilerler.
class ArchimedesLab2DView extends StatelessWidget {
  const ArchimedesLab2DView({super.key, required this.scene});

  final ArchimedesScene scene;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('drop-${scene.station.name}-${scene.revision}'),
        tween: Tween(begin: scene.revision == 0 ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, drop, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: scene.screwTurns),
          duration: const Duration(milliseconds: 1600),
          builder: (context, turns, _) => TweenAnimationBuilder<double>(
            tween: Tween(end: scene.fieldLitres),
            duration: const Duration(milliseconds: 1600),
            builder: (context, litres, _) => TweenAnimationBuilder<double>(
              tween: Tween(
                end: scene.boat == null
                    ? 0
                    : scene.boat!.sinks(scene.crates)
                    ? 1.6
                    : scene.boat!.draftRatio(scene.crates),
              ),
              duration: const Duration(milliseconds: 900),
              builder: (context, draft, _) => CustomPaint(
                painter: _LabPainter(
                  scene: scene,
                  drop: drop,
                  turns: turns,
                  litres: litres,
                  draft: draft,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabPainter extends CustomPainter {
  _LabPainter({
    required this.scene,
    required this.drop,
    required this.turns,
    required this.litres,
    required this.draft,
  });

  final ArchimedesScene scene;
  final double drop;
  final double turns;
  final double litres;

  /// Gemi gömülme oranı; 1'den büyükse gemi batıyor.
  final double draft;

  static const _water = Color(0xFF4FC3F7);
  static const _waterDeep = Color(0xFF0288D1);
  static const _frame = Color(0xFF455A64);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE3F2FD),
    );
    switch (scene.station) {
      case ArchimedesStation.tank:
        _paintTanks(canvas, size);
      case ArchimedesStation.boat:
        _paintBoat(canvas, size);
      case ArchimedesStation.screw:
        _paintScrew(canvas, size);
    }
  }

  // ─────────────────────────── Su kabı ───────────────────────────

  void _paintTanks(Canvas canvas, Size size) {
    final n = scene.tanks.length;
    final slot = size.width / n;
    for (var i = 0; i < n; i++) {
      _paintTank(
        canvas,
        Rect.fromLTWH(i * slot, 0, slot, size.height),
        scene.tanks[i],
      );
    }
  }

  void _paintTank(Canvas canvas, Rect area, TankState tank) {
    final beakerRoom = tank.brimFull ? area.width * 0.28 : 0.0;
    final tankH = min(area.height * 0.7, (area.width - beakerRoom) * 0.9);
    final tankW = tankH * 0.8;
    final left = area.left + (area.width - beakerRoom - tankW) / 2;
    final bottom = area.bottom - area.height * 0.08;
    final box = Rect.fromLTWH(left, bottom - tankH, tankW, tankH);
    final pxPerCm = tankH / tankHeightCm;

    // Su: son cisim düşerken seviye eskisinden yenisine ilerler.
    final dropped = tank.dropped;
    final before = dropped.isEmpty ? dropped : dropped.sublist(0, dropped.length - 1);
    final levelBefore = tank.brimFull ? tankHeightCm : tankWaterLevelCm(before);
    final level = levelBefore + (tank.waterLevelCm - levelBefore) * drop;
    final waterTop = bottom - level * pxPerCm;
    canvas.drawRect(
      Rect.fromLTRB(box.left, waterTop, box.right, bottom),
      Paint()..color = _water.withValues(alpha: 0.55),
    );

    // Cetvel: her 5 cm'de bir çizgi.
    final tick = Paint()
      ..color = _frame
      ..strokeWidth = 1;
    for (var cm = 5; cm < tankHeightCm; cm += 5) {
      final y = bottom - cm * pxPerCm;
      canvas.drawLine(Offset(box.left, y), Offset(box.left + 8, y), tick);
    }
    _label(canvas, '${level.toStringAsFixed(1).replaceAll('.', ',')} cm',
        Offset(box.left + 10, waterTop - 16), 11, _waterDeep);

    // Cisimler.
    for (var k = 0; k < dropped.length; k++) {
      final o = dropped[k];
      final t = k == dropped.length - 1 ? drop : 1.0;
      final d = _objectSize(o, pxPerCm);
      final restBottom = o.floats
          ? waterTop + d * o.submergedFraction
          : bottom - 1;
      final startBottom = box.top - 10;
      final objBottom = startBottom + (restBottom - startBottom) * t;
      final cx = box.left + tankW * (0.3 + 0.4 * ((k % 2 == 0) ? 0.2 : 0.8));
      _emoji(canvas, o.emoji, Offset(cx, objBottom - d / 2), d);
    }
    if (tank.held != null) {
      final d = _objectSize(tank.held!, pxPerCm);
      _emoji(canvas, tank.held!.emoji,
          Offset(box.center.dx, box.top - d / 2 - 6), d);
    }

    // Kap çerçevesi (yanlar + taban, ağız açık).
    final wall = Paint()
      ..color = _frame
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(box.left, box.top)
        ..lineTo(box.left, box.bottom)
        ..lineTo(box.right, box.bottom)
        ..lineTo(box.right, box.top),
      wall,
    );

    if (tank.label != null) {
      _label(canvas, tank.label!, Offset(box.center.dx - 6, bottom + 2), 14,
          Colors.black87);
    }

    if (tank.brimFull) {
      // Ölçü kabı: taşan su (mL) burada toplanır.
      final bw = beakerRoom * 0.6;
      final bh = tankH * 0.45;
      final beaker = Rect.fromLTWH(box.right + beakerRoom * 0.25, bottom - bh, bw, bh);
      final ml = tank.overflowMl * drop;
      // 80 mL kabı doldurur (taç deneyinde 52 / 65 mL farkı görünsün).
      final fillH = bh * (ml / 80).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTRB(beaker.left, beaker.bottom - fillH, beaker.right, beaker.bottom),
        Paint()..color = _water.withValues(alpha: 0.7),
      );
      canvas.drawPath(
        Path()
          ..moveTo(beaker.left, beaker.top)
          ..lineTo(beaker.left, beaker.bottom)
          ..lineTo(beaker.right, beaker.bottom)
          ..lineTo(beaker.right, beaker.top),
        wall..strokeWidth = 2,
      );
      _label(canvas, '${ml.round()} mL', Offset(beaker.left, beaker.top - 16),
          11, _waterDeep);
    }
  }

  /// Cismin çizim boyu: hacmin küp kökü (gerçek oranlı), okunaklı kalsın diye
  /// alttan sınırlı.
  double _objectSize(BuoyancyObject o, double pxPerCm) =>
      max(14.0, pow(o.volumeCm3, 1 / 3) * pxPerCm * 1.1);

  // ─────────────────────────── Gemi ───────────────────────────

  void _paintBoat(Canvas canvas, Size size) {
    final waterY = size.height * 0.55;
    canvas.drawRect(
      Rect.fromLTRB(0, waterY, size.width, size.height),
      Paint()..color = _water.withValues(alpha: 0.6),
    );
    final boat = scene.boat;
    if (boat == null) return;
    final hullW = min(size.width * 0.55, 320.0);
    final hullH = hullW * 0.22;
    final cx = size.width / 2;
    final sinking = draft > 1;
    final hullBottom = waterY - hullH * (1 - min(draft, 1.0)) + hullH +
        (sinking ? (draft - 1) * hullH * 2 : 0);
    final hullTop = hullBottom - hullH;
    final hull = Path()
      ..moveTo(cx - hullW / 2, hullTop)
      ..lineTo(cx + hullW / 2, hullTop)
      ..lineTo(cx + hullW * 0.38, hullBottom)
      ..lineTo(cx - hullW * 0.38, hullBottom)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFFB07A45));
    // Sandıklar: güverte üstünde 3'lü sıralar.
    final crate = hullH * 0.8;
    for (var i = 0; i < scene.crates; i++) {
      final col = i % 3;
      final row = i ~/ 3;
      final r = Rect.fromLTWH(
        cx - crate * 1.6 + col * crate * 1.1,
        hullTop - crate * (row + 1) - 2 * row,
        crate,
        crate,
      );
      canvas.drawRect(r, Paint()..color = const Color(0xFFC68A4E));
      canvas.drawRect(
        r,
        Paint()
          ..color = const Color(0xFF6D4C41)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    // Suyun önü: batan kısım suyun arkasında görünsün.
    canvas.drawRect(
      Rect.fromLTRB(0, waterY, size.width, size.height),
      Paint()..color = _water.withValues(alpha: 0.35),
    );
    canvas.drawLine(
      Offset(0, waterY),
      Offset(size.width, waterY),
      Paint()
        ..color = _waterDeep
        ..strokeWidth = 2,
    );
    _label(
      canvas,
      sinking
          ? 'Battı!'
          : '${boat.name}: ${scene.crates} sandık, '
                '${boat.draftCm(scene.crates).toStringAsFixed(1).replaceAll('.', ',')} cm gömüldü',
      const Offset(12, 10),
      13,
      sinking ? Colors.red.shade700 : Colors.black87,
    );
  }

  // ─────────────────────────── Vida ───────────────────────────

  void _paintScrew(Canvas canvas, Size size) {
    final unit = min(size.width / 7.5, size.height / 3.4); // px / m
    final riverY = size.height * 0.78;
    final pivot = Offset(size.width * 0.12, riverY + unit * 0.2);
    canvas.drawRect(
      Rect.fromLTRB(0, riverY, size.width, size.height),
      Paint()..color = _water.withValues(alpha: 0.7),
    );
    // Tarla.
    final fieldLeft = pivot.dx + unit * 2.95;
    final fieldTop = riverY - fieldHeightM * unit;
    canvas.drawRect(
      Rect.fromLTRB(fieldLeft, fieldTop, size.width, riverY),
      Paint()..color = const Color(0xFF7CB342),
    );
    final wet = (litres / fieldNeedLitres).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTRB(fieldLeft, fieldTop - 6, size.width, fieldTop),
      Paint()
        ..color = Color.lerp(
          const Color(0xFF8D6E63),
          const Color(0xFF2E7D32),
          wet,
        )!,
    );
    // Filizler su geldikçe uzar.
    final sprout = Paint()
      ..color = const Color(0xFF43A047)
      ..strokeWidth = 3;
    for (var x = fieldLeft + 14; x < size.width - 6; x += 22) {
      canvas.drawLine(
        Offset(x, fieldTop - 6),
        Offset(x, fieldTop - 8 - 22 * wet),
        sprout,
      );
    }

    // Vida: eğik boru + dönen sarmal çizgileri.
    final a = scene.screwAngle * pi / 180;
    final dir = Offset(cos(a), -sin(a));
    final top = pivot + dir * (screwLengthM * unit);
    final normal = Offset(-dir.dy, dir.dx);
    final r = unit * 0.22;
    final tube = Paint()
      ..color = const Color(0xFF7A4E2A)
      ..strokeWidth = 3;
    canvas.drawLine(pivot + normal * r, top + normal * r, tube);
    canvas.drawLine(pivot - normal * r, top - normal * r, tube);
    final blade = Paint()
      ..color = const Color(0xFFB07A45)
      ..strokeWidth = 2.5;
    const pitches = 12;
    final phase = turns % 1;
    for (var i = 0; i < pitches; i++) {
      final u = (i + phase) / pitches;
      final p = pivot + dir * (u * screwLengthM * unit);
      canvas.drawLine(
        p + normal * r + dir * (unit * 0.08),
        p - normal * r - dir * (unit * 0.08),
        blade,
      );
    }
    // Ceplerdeki su damlaları.
    final fill = screwPocketFill(scene.screwAngle);
    if (fill > 0) {
      final dropPaint = Paint()..color = _waterDeep;
      for (var i = 0; i < pitches; i++) {
        final u = (i + phase + 0.5) / pitches;
        if (u > 1) continue;
        final p = pivot + dir * (u * screwLengthM * unit) - normal * (r * 0.5);
        canvas.drawCircle(p, 2 + 4 * fill, dropPaint);
      }
    }
    _label(
      canvas,
      '${scene.screwAngle.round()}°  ·  Tarla: ${litres.round()} / '
      '${fieldNeedLitres.round()} litre',
      const Offset(12, 10),
      13,
      Colors.black87,
    );
  }

  // ─────────────────────────── Yardımcılar ───────────────────────────

  void _label(Canvas canvas, String text, Offset at, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  /// Emoji önbelleğe alınmadan her karede yerleştirilir (bkz. CLAUDE.md
  /// "Emoji tuzağı": CanvasKit emoji yazı tipini geç yükleyebilir).
  void _emoji(Canvas canvas, String emoji, Offset center, double size) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: size * 0.85)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_LabPainter old) =>
      old.scene != scene ||
      old.drop != drop ||
      old.turns != turns ||
      old.litres != litres ||
      old.draft != draft;
}
