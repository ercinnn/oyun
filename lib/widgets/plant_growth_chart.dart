import 'package:flutter/material.dart';

import '../models/plant_conditions.dart';
import '../models/plant_growth.dart';
import '../models/plant_species.dart';

/// A ve B saksısının boyunun günlere göre çizgi grafiği. Yatay eksen gün,
/// dikey eksen boy (bitkinin ideal boyuna göre ölçeklenir). O anki gün dikey
/// bir çizgiyle gösterilir.
class PlantGrowthChart extends StatelessWidget {
  const PlantGrowthChart({
    super.key,
    required this.species,
    required this.potA,
    required this.potB,
    required this.day,
    this.height = 120,
  });

  /// A saksısının çizgi rengi.
  static const colorA = Color(0xFF1E88E5);

  /// B saksısının çizgi rengi.
  static const colorB = Color(0xFFF57C00);

  final PlantSpecies species;
  final PlantConditions potA;
  final PlantConditions potB;
  final double day;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ChartPainter(
          species: species,
          potA: potA,
          potB: potB,
          day: day,
          gridColor: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.species,
    required this.potA,
    required this.potB,
    required this.day,
    required this.gridColor,
  });

  final PlantSpecies species;
  final PlantConditions potA;
  final PlantConditions potB;
  final double day;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    final plot = Rect.fromLTWH(
      pad,
      pad,
      size.width - 2 * pad,
      size.height - 2 * pad,
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawRect(plot, gridPaint..style = PaintingStyle.stroke);
    for (final t in [0.25, 0.5, 0.75]) {
      final y = plot.bottom - plot.height * t;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }

    Offset point(double d, double heightCm) => Offset(
      plot.left + plot.width * d / plantExperimentDays,
      plot.bottom - plot.height * (heightCm / species.maxHeightCm).clamp(0, 1),
    );

    void drawSeries(PlantConditions conditions, Color color) {
      final path = Path();
      for (var d = 0; d <= plantExperimentDays; d++) {
        final p = point(
          d.toDouble(),
          simulatePlant(species, conditions, d.toDouble()).heightCm,
        );
        if (d == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawCircle(
        point(day, simulatePlant(species, conditions, day).heightCm),
        5,
        Paint()..color = color,
      );
    }

    // O anki günü gösteren dikey çizgi.
    final x = plot.left + plot.width * day / plantExperimentDays;
    canvas.drawLine(
      Offset(x, plot.top),
      Offset(x, plot.bottom),
      Paint()
        ..color = gridColor
        ..strokeWidth = 2,
    );

    drawSeries(potA, PlantGrowthChart.colorA);
    drawSeries(potB, PlantGrowthChart.colorB);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
