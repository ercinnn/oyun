import 'dart:math';

import 'package:flutter/material.dart';

import '../../config/scientists_3d.dart';
import '../../models/einstein/einstein_scene.dart';
import '../../models/einstein/mass_energy.dart';
import '../../models/einstein/spacetime.dart';
import '../../models/einstein/time_dilation.dart';
import '../../models/science/science_task.dart' show formatTr;
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
                : progressive(
                    (p) => CustomPaint(painter: _Einstein2DPainter(scene, p)),
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
        return _Panel(
          key: const Key('einsteinSheetMeter'),
          children: [
            _line('${scene.center.label} · ${scene.speed.label} fırlatış', 13),
            if (scene.run > 0)
              _line('Bilye: ${scene.marble.fate.label.toLowerCase()}', 12,
                  color: const Color(0xFF80DEEA)),
          ],
        );
      case EinsteinStation.clock:
        final earth = scene.earthYears * progress;
        final ship = shipYears(earth, scene.shipSpeed);
        return _Panel(
          key: const Key('einsteinTwins'),
          children: [
            _line('Gemi: ışık hızının ${percentOfC(scene.shipSpeed)}\'i', 13),
            _line('🌍 Dünya: ${formatTr(earth)} yıl   🚀 Gemi: ${formatTr(ship)} yıl', 12,
                color: const Color(0xFFFFEB3B)),
            _line('Gemide 1 sn = Dünya\'da ${formatTr(lorentzGamma(scene.shipSpeed), digits: 2)} sn', 11),
          ],
        );
      case EinsteinStation.energy:
        final homes = homesPowered(scene.grams) * progress;
        return _Panel(
          key: const Key('einsteinEnergy'),
          children: [
            _line('${formatGrams(scene.grams)} g kütle', 13),
            _line('⚡ ${friendlyNumber(homes)} evin bir yıllık elektriği', 12,
                color: const Color(0xFFFFE082)),
            _line('🔥 Aynı kütleyi yakmak: ${burningPhrase(scene.grams)}', 11),
          ],
        );
    }
  }

  static Widget _line(String text, double size, {Color color = Colors.white}) =>
      Text(text, style: TextStyle(color: color, fontSize: size));
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

/// 2B yedek: istasyonun şeması; [progress] deneyin 0-1 ilerlemesi.
class _Einstein2DPainter extends CustomPainter {
  _Einstein2DPainter(this.scene, this.progress);

  final EinsteinScene scene;
  final double progress;

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
    canvas.drawCircle(c + Offset(m.$1, -m.$2) * unit, 4, Paint()..color = Colors.white);
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
      final tp = TextPainter(
        text: TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, bottom + 8));
    }

    clock(size.width * 0.3, 'Dünya', 1);
    clock(size.width * 0.7, 'Gemi', lorentzGamma(scene.shipSpeed));
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
  }

  @override
  bool shouldRepaint(_Einstein2DPainter old) =>
      old.scene != scene || old.progress != progress;
}
