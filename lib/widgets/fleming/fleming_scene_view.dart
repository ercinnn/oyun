import 'dart:math';

import 'package:flutter/material.dart';

import '../../config/scientists_3d.dart';
import '../../models/fleming/fleming_scene.dart';
import '../../models/fleming/hygiene.dart';
import '../../models/fleming/petri.dart';
import '../../models/fleming/resistance.dart';
import '../../models/science/science_task.dart' show formatTr;
import '../science_lab/lab_labels.dart';
import '../science_lab/lab_style.dart';
import 'fleming_lab_3d_view.dart';

/// Fleming laboratuvarı: 3B açıksa `FlemingLab3DView`, değilse 2B yedek;
/// üstünde istasyona göre bir gösterge. Göstergeler ve 2B çizim, gün
/// değerlerine sonlu animasyonlarla ilerler (`pumpAndSettle` biter).
class FlemingSceneView extends StatelessWidget {
  const FlemingSceneView({super.key, required this.scene});

  final FlemingScene scene;

  @override
  Widget build(BuildContext context) {
    // Animasyon 3B görünümü sarmaz (anahtarsız da olsa yeniden kurulum riski
    // yok, ama 3B zaten kendi hızıyla ilerler).
    Widget animated(Widget Function(double day, double medDay) child) =>
        TweenAnimationBuilder<double>(
          tween: Tween(end: scene.day),
          duration: const Duration(milliseconds: 1200),
          builder: (context, day, _) => TweenAnimationBuilder<double>(
            tween: Tween(end: scene.medicineDay),
            duration: const Duration(milliseconds: 2500),
            builder: (context, medDay, _) => child(day, medDay),
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: scientistsUse3d
                ? FlemingLab3DView(scene: scene)
                : ValueListenableBuilder<bool>(
                    valueListenable: labLabelsOn,
                    builder: (context, showLabels, _) => animated(
                      (d, m) => CustomPaint(
                        painter: _Fleming2DPainter(scene, d, m, showLabels: showLabels),
                      ),
                    ),
                  ),
          ),
          Positioned(left: 8, bottom: 8, child: animated(_inset)),
        ],
      ),
    );
  }

  Widget _inset(double day, double medDay) {
    switch (scene.station) {
      case FlemingStation.petri:
        return LabInset(
          key: const Key('flemingPetriMeter'),
          children: [
            LabInsetValue('Gün ${formatTr(day)}'),
            const SizedBox(height: 2),
            LabInsetCaption(
              'A (${scene.mold ? 'küflü' : 'küfsüz'}): '
              '${livingColonies(day, mold: scene.mold)} koloni',
              color: const Color(0xFF90CAF9),
            ),
            LabInsetCaption(
              'B (kontrol): ${livingColonies(day, mold: false)} koloni',
              color: const Color(0xFFFFAB91),
            ),
          ],
        );
      case FlemingStation.hygiene:
        return LabInset(
          key: const Key('flemingHygieneMeter'),
          children: [
            LabInsetValue(
              scene.incubated
                  ? '${scene.hygieneCount} koloni'
                  : 'Henüz bekletilmedi',
              color: const Color(0xFFFFB74D),
            ),
            LabInsetCaption(
              '${scene.lidOpen ? 'Kapak açık' : 'Kapak kapalı'} · ${scene.hand.label}'
              '${scene.incubated ? ' · $hygieneDays gün sonra' : ''}',
            ),
          ],
        );
      case FlemingStation.medicine:
        return LabInset(
          key: const Key('flemingMedicineChart'),
          children: [
            LabInsetCaption('Günlere göre bakteri · ilaç ${scene.treatmentDays} gün (mavi)'),
            const SizedBox(height: 4),
            SizedBox(
              width: 220,
              height: 80,
              child: CustomPaint(
                painter: _CoursePainter(scene.course, medDay, scene.treatmentDays),
              ),
            ),
            const SizedBox(height: 4),
            const Wrap(
              spacing: 10,
              children: [
                _Legend(color: Color(0xFF66BB6A), text: 'duyarlı'),
                _Legend(color: Color(0xFFE53935), text: 'dayanıklı'),
              ],
            ),
          ],
        );
    }
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      LabInsetCaption(text),
    ],
  );
}

/// Günlere göre bakteri sayısı (yığılmış sütunlar): yeşil duyarlı, kırmızı
/// dayanıklı; ilaç günleri mavi zeminli; [shownDay]'e kadar olanlar dolu.
class _CoursePainter extends CustomPainter {
  _CoursePainter(this.course, this.shownDay, this.treatmentDays);

  final List<Population> course;
  final double shownDay;
  final int treatmentDays;

  @override
  void paint(Canvas canvas, Size size) {
    final n = course.length;
    final w = size.width / n;
    for (var i = 0; i < n; i++) {
      final x = i * w;
      if (i >= 1 && i <= treatmentDays) {
        canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), Paint()..color = const Color(0x3342A5F5));
      }
      if (i > shownDay + 1e-9) continue;
      final p = course[i];
      final hs = p.sensitive / populationCap * size.height;
      final hr = p.resistant / populationCap * size.height;
      canvas.drawRect(Rect.fromLTWH(x + 1, size.height - hr, w - 2, hr),
          Paint()..color = const Color(0xFFE53935));
      canvas.drawRect(Rect.fromLTWH(x + 1, size.height - hr - hs, w - 2, hs),
          Paint()..color = const Color(0xFF66BB6A));
    }
  }

  @override
  bool shouldRepaint(_CoursePainter old) =>
      old.shownDay != shownDay || old.treatmentDays != treatmentDays;
}

/// 2B yedek: kapların ve mikroskop görüntüsünün şeması.
class _Fleming2DPainter extends CustomPainter {
  _Fleming2DPainter(this.scene, this.day, this.medDay, {required this.showLabels});

  final FlemingScene scene;
  final double day;
  final double medDay;

  /// Sahne etiketleri (A/B kapları, küf, mikroskop).
  final bool showLabels;

  void _tag(Canvas canvas, Size size, Offset tip, LabLabel label) {
    if (showLabels) paintLabLabel(canvas, tip, label, bounds: size);
  }

  void _dish(Canvas canvas, Offset c, double r, {required bool mold}) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFC98A2E));
    canvas.drawCircle(c, r, Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    if (mold && day >= 1) {
      final m = c + Offset(moldX, -moldY) * r;
      canvas.drawCircle(m, inhibitionRadius(day) * r, Paint()..color = const Color(0xFFE2B25A));
      canvas.drawCircle(m, moldRadius(day) * r, Paint()..color = const Color(0xFF26A69A));
    }
    for (final col in petriColonies) {
      if (colonyBlocked(col, day, mold: mold)) continue;
      final cr = colonyRadius(col, day) * r;
      if (cr <= 0) continue;
      canvas.drawCircle(c + Offset(col.x, -col.y) * r, cr, Paint()..color = const Color(0xFFFFFDF5));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE8E0D0));
    switch (scene.station) {
      case FlemingStation.petri:
        final r = min(size.width / 4.6, size.height / 2.4);
        final a = Offset(size.width * 0.28, size.height * 0.45);
        final b = Offset(size.width * 0.72, size.height * 0.45);
        _dish(canvas, a, r, mold: scene.mold);
        _dish(canvas, b, r, mold: false);
        _tag(canvas, size, a - Offset(r * 0.75, r * 0.72), const LabLabel.tag('A'));
        _tag(canvas, size, b - Offset(r * 0.75, r * 0.72), const LabLabel.tag('B'));
        _tag(canvas, size, b - Offset(0, r + 2), const LabLabel('Kontrol kabı'));
        if (scene.mold && day >= 1) {
          final m = a + Offset(moldX, -moldY) * r;
          _tag(canvas, size, m - Offset(0, moldRadius(day) * r),
              const LabLabel('Küf', color: Color(0xFF00897B)));
        }
      case FlemingStation.hygiene:
        final r = min(size.width, size.height) * 0.32;
        final c = Offset(size.width * 0.55, size.height * 0.42);
        canvas.drawCircle(c, r, Paint()..color = const Color(0xFFF2D38A));
        final count = scene.hygieneCount;
        final spots = hygieneColonySpots(count);
        for (var i = 0; i < spots.length; i++) {
          final (x, y) = spots[i];
          canvas.drawCircle(c + Offset(x, -y) * r, 5,
              Paint()..color = i < (scene.lidOpen ? openLidColonies : 0)
                  ? const Color(0xFFECEFF1)
                  : const Color(0xFFFFB74D));
        }
        _tag(canvas, size, c - Offset(0, r + 2), const LabLabel('Petri kabı'));
      case FlemingStation.medicine:
        final r = min(size.width, size.height) * 0.36;
        final c = Offset(size.width * 0.55, size.height * 0.42);
        canvas.drawCircle(c, r, Paint()..color = const Color(0xFF1B2A3A));
        final p = scene.course[medDay.round().clamp(0, observedDays)];
        final rng = Random(31);
        final res = p.resistant <= 0 ? 0 : max(1, (p.resistant / populationCap * 150).round());
        final sens = p.sensitive <= 0 ? 0 : max(1, (p.sensitive / populationCap * 150).round());
        for (var i = 0; i < res + sens; i++) {
          final a = rng.nextDouble() * 2 * pi;
          final d = sqrt(rng.nextDouble()) * r * 0.9;
          canvas.drawCircle(c + Offset(cos(a), sin(a)) * d, 3,
              Paint()..color = i < res ? const Color(0xFFE53935) : const Color(0xFF66BB6A));
        }
        _tag(canvas, size, c - Offset(0, r + 2),
            const LabLabel('Mikroskopta bakteriler', emoji: '🔬'));
    }
  }

  @override
  bool shouldRepaint(_Fleming2DPainter old) =>
      old.scene != scene ||
      old.day != day ||
      old.medDay != medDay ||
      old.showLabels != showLabels;
}
