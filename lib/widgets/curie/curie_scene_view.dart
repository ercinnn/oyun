import 'dart:math';

import 'package:flutter/material.dart';

import '../../config/scientists_3d.dart';
import '../../data/curie_samples.dart';
import '../../models/curie/curie_scene.dart';
import '../../models/curie/geiger.dart';
import '../../models/curie/shielding.dart';
import '../../models/curie/therapy.dart';
import '../../models/science/science_task.dart' show formatTr;
import '../science_lab/lab_labels.dart';
import '../science_lab/lab_style.dart';
import 'curie_lab_3d_view.dart';

/// Curie laboratuvarı: 3B açıksa `CurieLab3DView`, değilse 2B yedek; ikisinin
/// de üstünde istasyona göre bir gösterge (sayaç, kalkan sayımı, doz
/// haritası). 2B ve göstergeler durağandır (`pumpAndSettle` biter).
class CurieSceneView extends StatelessWidget {
  const CurieSceneView({super.key, required this.scene});

  final CurieScene scene;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: scientistsUse3d
                ? CurieLab3DView(scene: scene)
                : ValueListenableBuilder<bool>(
                    valueListenable: labLabelsOn,
                    builder: (context, showLabels, _) => CustomPaint(
                      painter: _Curie2DPainter(scene, showLabels: showLabels),
                    ),
                  ),
          ),
          Positioned(left: 8, bottom: 8, child: _inset()),
        ],
      ),
    );
  }

  Widget _inset() => switch (scene.station) {
    CurieStation.geiger => LabInset.reading(
      key: const Key('curieGeigerMeter'),
      value: '${formatCps(scene.geigerCps)} tık/sn',
      valueColor: const Color(0xFFFF8A80),
      caption: scene.sample == null
          ? 'Sayaç boşta · yalnızca arka plan'
          : '${scene.sample!.name} · ${formatTr(scene.distanceCm)} cm',
    ),
    CurieStation.shield => LabInset.reading(
      key: const Key('curieShieldMeter'),
      value: '${formatCps(scene.shieldCps)} tık/sn',
      valueColor: Color(0xFF000000 | scene.ray.color),
      caption: '${scene.ray.label} ışını · ${scene.shield.label} · geçen %'
          '${(transmission(scene.ray, scene.shield) * 100).round()}',
    ),
    CurieStation.therapy => DoseMapView(dose: scene.dose, beamsOn: scene.beamsOn),
  };
}

/// Vücut kesitindeki doz haritası: beyaz → sarı → kırmızı; tümör ve güvenlik
/// payı çemberleri.
class DoseMapView extends StatelessWidget {
  const DoseMapView({super.key, required this.dose, required this.beamsOn});

  final DoseMap dose;
  final bool beamsOn;

  @override
  Widget build(BuildContext context) {
    return LabInset(
      key: const Key('curieDoseMap'),
      children: [
        const LabInsetCaption('Doz haritası'),
        const SizedBox(height: 4),
        SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(painter: _DosePainter(dose)),
        ),
        const SizedBox(height: 6),
        if (beamsOn) ...[
          LabInsetValue(
            dose.safe ? 'Güvenli plan' : 'Fazla ışın!',
            color: dose.safe ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80),
          ),
          LabInsetCaption(
            'Tümör ${formatTr(dose.tumorDose)} · sağlıklı doku en çok '
            '${formatTr(dose.maxHealthyDose)}',
          ),
        ] else
          const LabInsetCaption('Işınlar kapalı'),
      ],
    );
  }
}

class _DosePainter extends CustomPainter {
  _DosePainter(this.dose);

  final DoseMap dose;

  static Color _colorFor(double v) {
    if (v <= 0) return const Color(0xFFF8E1E1);
    final t = (v / targetDose).clamp(0.0, 1.0);
    return t < 0.5
        ? Color.lerp(const Color(0xFFFFF59D), const Color(0xFFFFA726), t * 2)!
        : Color.lerp(const Color(0xFFFFA726), const Color(0xFFD50000), (t - 0.5) * 2)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / therapyGrid;
    for (var y = 0; y < therapyGrid; y++) {
      for (var x = 0; x < therapyGrid; x++) {
        final v = dose.values[y][x];
        if (v == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          Paint()..color = _colorFor(v),
        );
      }
    }
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      (tumorRadius + 0.5) * cell,
      Paint()
        ..color = const Color(0xFF6A1B9A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      c,
      safetyMarginRadius * cell,
      Paint()
        ..color = const Color(0x886A1B9A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_DosePainter old) => old.dose != dose;
}

/// 2B yedek: istasyonun durağan şeması.
class _Curie2DPainter extends CustomPainter {
  _Curie2DPainter(this.scene, {required this.showLabels});

  final CurieScene scene;

  /// Sahne etiketleri (numune adları, sonda, kalkan, tümör).
  final bool showLabels;

  void _tag(Canvas canvas, Size size, Offset tip, LabLabel label) {
    if (showLabels) paintLabLabel(canvas, tip, label, bounds: size, scale: 0.9);
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (scene.station) {
      case CurieStation.geiger:
        _geiger(canvas, size);
      case CurieStation.shield:
        _shield(canvas, size);
      case CurieStation.therapy:
        _therapy(canvas, size);
    }
  }

  void _text(Canvas canvas, String t, Offset at, double size, {Color color = Colors.black87}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: size, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, 0));
  }

  void _geiger(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF2F3437));
    final benchY = size.height * 0.45;
    canvas.drawRect(Rect.fromLTWH(0, benchY, size.width, 10),
        Paint()..color = const Color(0xFF8D6E63));
    final step = size.width / (curieSamples.length + 1);
    for (var i = 0; i < curieSamples.length; i++) {
      final s = curieSamples[i];
      final x = step * (i + 1);
      _text(canvas, s.emoji, Offset(x, benchY - 30), 22);
      if (s.id == scene.sample?.id) {
        _tag(canvas, size, Offset(x, benchY - 32),
            LabLabel(s.name, color: const Color(0xFFC62828)));
        // Sonda: numunenin altından, uzaklık kadar aşağıda.
        final d = scene.distanceCm / counterMaxCm * size.height * 0.4;
        canvas.drawLine(
          Offset(x, benchY + 14 + d),
          Offset(x, benchY + 60 + d),
          Paint()
            ..color = const Color(0xFF90A4AE)
            ..strokeWidth = 6,
        );
        _tag(canvas, size, Offset(x + 34, benchY + 60 + d),
            LabLabel.value('Sonda ${formatTr(scene.distanceCm)} cm'));
      }
    }
  }

  void _shield(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFCFD8DC));
    final y = size.height * 0.4;
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width * 0.15, y), width: 50, height: 50),
        Paint()..color = const Color(0xFF546E7A));
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width * 0.85, y), width: 44, height: 36),
        Paint()..color = const Color(0xFF455A64));
    final pass = transmission(scene.ray, scene.shield);
    final ray = Paint()
      ..color = Color(0xFF000000 | scene.ray.color)
      ..strokeWidth = 3;
    final mid = size.width * 0.5;
    canvas.drawLine(Offset(size.width * 0.15 + 25, y), Offset(mid, y), ray);
    if (pass > 0) {
      canvas.drawLine(Offset(mid, y), Offset(size.width * 0.85 - 22, y),
          ray..color = ray.color.withValues(alpha: max(0.15, pass)));
    }
    if (scene.shield != Shield.none) {
      final w = switch (scene.shield) {
        Shield.paper => 2.0,
        Shield.aluminum => 6.0,
        _ => 16.0,
      };
      canvas.drawRect(Rect.fromCenter(center: Offset(mid, y), width: w, height: 70),
          Paint()..color = const Color(0xFF37474F));
      _tag(canvas, size, Offset(mid, y - 36), LabLabel(scene.shield.label));
    }
    _tag(canvas, size, Offset(size.width * 0.15, y - 26),
        LabLabel('${scene.ray.label} kaynağı', color: Color(0xFF000000 | scene.ray.color)));
    _tag(canvas, size, Offset(size.width * 0.85, y - 20), const LabLabel('Sayaç'));
  }

  void _therapy(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE0F2F1));
    final c = Offset(size.width * 0.62, size.height * 0.45);
    final r = min(size.width, size.height) * 0.3;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFCCBC));
    canvas.drawCircle(c, r * tumorRadius / bodyRadius, Paint()..color = const Color(0xFF8E24AA));
    _tag(canvas, size, c - Offset(0, r * tumorRadius / bodyRadius + 2),
        const LabLabel('Tümör', color: Color(0xFF6A1B9A)));
    _tag(canvas, size, c - Offset(r * 0.7, r * 0.72), const LabLabel('Sağlıklı doku'));
    if (!scene.beamsOn) return;
    for (final b in scene.beams) {
      final a = b.angleDeg * pi / 180;
      final d = Offset(cos(a), sin(a)) * r * 1.2;
      canvas.drawLine(c - d, c + d, Paint()
        ..color = const Color(0x99FFA000)
        ..strokeWidth = 2 + b.strength * 2);
    }
  }

  @override
  bool shouldRepaint(_Curie2DPainter old) =>
      old.scene != scene || old.showLabels != showLabels;
}
