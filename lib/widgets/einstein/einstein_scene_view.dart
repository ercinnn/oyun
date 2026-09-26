import 'dart:math';

import 'package:flutter/material.dart';

import '../../config/scientists_3d.dart';
import '../../models/einstein/einstein_scene.dart';
import '../../models/einstein/mass_energy.dart';
import '../../models/einstein/spacetime.dart';
import '../../models/einstein/time_dilation.dart';
import '../../models/science/science_task.dart' show formatTr;
import '../science_lab/lab_labels.dart';
import '../science_lab/lab_style.dart';
import 'einstein_lab_3d_view.dart';

/// Einstein laboratuvarı: 3B açıksa `EinsteinLab3DView`, değilse 2B yedek;
/// üstünde istasyona göre bir gösterge. Deney ilerlemesi (bilyenin yolu,
/// akan yıllar, yanan evler) sonlu bir animasyonla ilerler.
class EinsteinSceneView extends StatelessWidget {
  const EinsteinSceneView({super.key, required this.scene});

  final EinsteinScene scene;

  @override
  Widget build(BuildContext context) {
    // İlerleme animasyonu yalnızca 2B çizimi ve göstergeyi sarar; 3B görünüm
    // anahtarlı bir alt ağaçta olsaydı her denemede baştan kurulurdu.
    Widget progressive(Widget Function(double progress) child) =>
        TweenAnimationBuilder<double>(
          key: ValueKey('einstein-${scene.station.name}-${scene.run}'),
          tween: Tween(begin: 0, end: scene.run > 0 ? 1 : 0),
          duration: const Duration(milliseconds: 2500),
          builder: (context, progress, _) => child(progress),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: scientistsUse3d
                ? EinsteinLab3DView(scene: scene)
                : ValueListenableBuilder<bool>(
                    valueListenable: labLabelsOn,
                    builder: (context, showLabels, _) => progressive(
                      (p) => CustomPaint(
                        painter: _Einstein2DPainter(scene, p, showLabels: showLabels),
                      ),
                    ),
                  ),
          ),
          Positioned(left: 8, bottom: 8, child: progressive(_inset)),
        ],
      ),
    );
  }

  Widget _inset(double progress) {
    switch (scene.station) {
      case EinsteinStation.sheet:
        return LabInset(
          key: const Key('einsteinSheetMeter'),
          children: [
            LabInsetValue(
              scene.run > 0
                  ? 'Bilye: ${scene.marble.fate.label.toLowerCase()}'
                  : scene.center.label,
              color: scene.run > 0 ? const Color(0xFF80DEEA) : Colors.white,
            ),
            LabInsetCaption('${scene.center.label} · ${scene.speed.label} fırlatış'),
          ],
        );
      case EinsteinStation.clock:
        final earth = scene.earthYears * progress;
        final ship = shipYears(earth, scene.shipSpeed);
        return LabInset(
          key: const Key('einsteinTwins'),
          children: [
            LabInsetValue('🌍 Dünya: ${formatTr(earth)} yıl'),
            LabInsetValue(
              '🚀 Gemi: ${formatTr(ship)} yıl',
              color: const Color(0xFFFFEB3B),
            ),
            const SizedBox(height: 2),
            LabInsetCaption(
              'Gemi ışık hızının ${percentOfC(scene.shipSpeed)}\'iyle gidiyor. '
              'Gemide 1 sn = Dünya\'da '
              '${formatTr(lorentzGamma(scene.shipSpeed), digits: 2)} sn',
            ),
          ],
        );
      case EinsteinStation.energy:
        final homes = homesPowered(scene.grams) * progress;
        return LabInset(
          key: const Key('einsteinEnergy'),
          children: [
            LabInsetValue(
              '⚡ ${friendlyNumber(homes)} evin',
              color: const Color(0xFFFFE082),
            ),
            LabInsetCaption(
              'bir yıllık elektriği · ${formatGrams(scene.grams)} g kütleden',
            ),
            const SizedBox(height: 4),
            LabInsetCaption('🔥 Aynı kütleyi yakmak: ${burningPhrase(scene.grams)}'),
          ],
        );
    }
  }
}

/// 2B yedek: istasyonun şeması; [progress] deneyin 0-1 ilerlemesi.
class _Einstein2DPainter extends CustomPainter {
  _Einstein2DPainter(this.scene, this.progress, {required this.showLabels});

  final EinsteinScene scene;
  final double progress;

  /// Sahne etiketleri (merkezdeki kütle, bilye, saatler, şehir).
  final bool showLabels;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A0E1F));
    switch (scene.station) {
      case EinsteinStation.sheet:
        _sheet(canvas, size);
      case EinsteinStation.clock:
        _clock(canvas, size);
      case EinsteinStation.energy:
        _energy(canvas, size);
    }
  }

  void _sheet(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final unit = min(size.width, size.height) / (2 * escapeRadius) * 0.95;
    final ring = Paint()
      ..color = const Color(0xFF4DD0E1)
      ..style = PaintingStyle.stroke;
    // Eş derinlik halkaları: ağır kütlede merkeze yakın sıklaşır.
    for (var k = 1; k <= 8; k++) {
      final r = k * 2.0;
      ring.strokeWidth = 0.5 + sheetDepth(scene.center, r) * 0.8;
      canvas.drawCircle(c, r * unit, ring);
    }
    canvas.drawCircle(c, scene.center.radius * unit * 1.6,
        Paint()..color = Color(0xFF000000 | scene.center.color));
    final run = scene.marble;
    final shown = scene.run > 0 ? (progress * (run.path.length - 1)).round() : 0;
    final trail = Paint()
      ..color = const Color(0xFF80DEEA)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i <= shown; i++) {
      final p = c + Offset(run.path[i].$1, -run.path[i].$2) * unit;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, trail);
    final m = run.path[shown];
    final marble = c + Offset(m.$1, -m.$2) * unit;
    canvas.drawCircle(marble, 4, Paint()..color = Colors.white);
    if (showLabels) {
      paintLabLabel(canvas, c - Offset(0, scene.center.radius * unit * 1.6 + 2),
          LabLabel(scene.center.label), bounds: size);
      paintLabLabel(canvas, marble - const Offset(0, 6), const LabLabel.value('Bilye'),
          bounds: size, scale: 0.85);
    }
  }

  void _clock(Canvas canvas, Size size) {
    void clock(double x, String label, double slowdown) {
      final top = size.height * 0.15, bottom = size.height * 0.7;
      final mirror = Paint()
        ..color = const Color(0xFFCFD8DC)
        ..strokeWidth = 4;
      canvas.drawLine(Offset(x - 25, top), Offset(x + 25, top), mirror);
      canvas.drawLine(Offset(x - 25, bottom), Offset(x + 25, bottom), mirror);
      // Durağan resim: fotonun yolu; yavaş saatte ışık çapraz gider.
      final lean = 40 * (1 - 1 / slowdown);
      canvas.drawLine(Offset(x - lean, bottom), Offset(x + lean, top),
          Paint()
            ..color = const Color(0xFFFFEB3B)
            ..strokeWidth = 2);
      if (showLabels) {
        paintLabLabel(canvas, Offset(x, top - 6), LabLabel(label), bounds: size);
      } else {
        final tp = TextPainter(
          text: TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, bottom + 8));
      }
    }

    clock(size.width * 0.3, "Dünya'daki saat", 1);
    clock(size.width * 0.7, 'Gemideki saat', lorentzGamma(scene.shipSpeed));
  }

  void _energy(Canvas canvas, Size size) {
    final lit = (scene.housesLit * progress).round();
    final cell = min(size.width * 0.6, size.height * 0.7) / 10;
    final origin = Offset(size.width * 0.3, size.height * 0.1);
    for (var i = 0; i < cityHouseCount; i++) {
      final r = Rect.fromLTWH(origin.dx + (i % 10) * cell, origin.dy + (i ~/ 10) * cell,
          cell * 0.8, cell * 0.8);
      canvas.drawRect(r, Paint()..color = i < lit ? const Color(0xFFFFE082) : const Color(0xFF37474F));
    }
    if (showLabels) {
      paintLabLabel(canvas, Offset(origin.dx + cell * 5, origin.dy - 2),
          const LabLabel('Şehir: 100 ev', emoji: '🏘️'), bounds: size);
      paintLabLabel(canvas, Offset(size.width * 0.14, size.height * 0.55),
          LabLabel.value('${formatGrams(scene.grams)} g'), bounds: size);
    }
  }

  @override
  bool shouldRepaint(_Einstein2DPainter old) =>
      old.scene != scene ||
      old.progress != progress ||
      old.showLabels != showLabels;
}
