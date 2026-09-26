import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../models/galileo/jupiter.dart';
import '../../models/galileo/solar.dart';
import '../../models/galileo/telescope.dart';
import '../../models/science/science_task.dart' show formatTr;

/// Göz merceğinden görülen: hedef büyütme kadar büyük, tüp yanlışsa
/// gerçekten bulanık (odak hatası kadar `ImageFilter.blur`).
class EyepieceView extends StatelessWidget {
  const EyepieceView({
    super.key,
    required this.target,
    required this.magnification,
    required this.focusError,
    this.size = 180,
  });

  final SkyTarget target;
  final double magnification;
  final double focusError;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sharp = focusError <= sharpToleranceCm;
    final sigma = sharp ? 0.0 : min(12.0, focusError * 0.7);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Container(
            key: const Key('galileoEyepiece'),
            width: size,
            height: size,
            color: const Color(0xFF05070F),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: CustomPaint(
                painter: _EyepiecePainter(target, magnification),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _Tag(
          '${formatTr(magnification, digits: 0)} kat büyütme · '
          '${sharp ? 'Net!' : 'Bulanık'}',
          color: sharp ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
        ),
      ],
    );
  }
}

class _EyepiecePainter extends CustomPainter {
  _EyepiecePainter(this.target, this.magnification);

  final SkyTarget target;
  final double magnification;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    // Birkaç sabit yıldız.
    final star = Paint()..color = Colors.white70;
    for (var i = 0; i < 14; i++) {
      final a = i * 2.4;
      final r = size.width * (0.2 + (i * 37 % 30) / 100);
      canvas.drawCircle(c + Offset(cos(a), sin(a)) * r, 1.1, star);
    }
    // 30 kat büyütmede hedef merceği neredeyse doldurur.
    final radius = size.width * 0.42 * (magnification / 40).clamp(0.08, 1.0);
    switch (target) {
      case SkyTarget.moon:
        canvas.drawCircle(c, radius, Paint()..color = const Color(0xFFE0E0E0));
        final crater = Paint()..color = const Color(0xFFB0B0B0);
        for (final (dx, dy, r) in const [
          (-0.3, -0.2, 0.18), (0.25, 0.1, 0.22), (-0.05, 0.4, 0.12), (0.35, -0.35, 0.1),
        ]) {
          canvas.drawCircle(c + Offset(dx, dy) * radius, r * radius, crater);
        }
      case SkyTarget.jupiter:
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: radius)));
        const bands = [0xFFE9D7B4, 0xFFC08B5C, 0xFFE9D7B4, 0xFF9C6B45, 0xFFE9D7B4, 0xFFC08B5C];
        for (var i = 0; i < bands.length; i++) {
          canvas.drawRect(
            Rect.fromLTWH(
              c.dx - radius,
              c.dy - radius + i * 2 * radius / bands.length,
              2 * radius,
              2 * radius / bands.length + 1,
            ),
            Paint()..color = Color(bands[i]),
          );
        }
        canvas.restore();
        // Uydular yanında, bir çizgi üzerinde (0. gece).
        for (final m in jupiterMoons) {
          if (m.hiddenAt(0)) continue;
          final x = c.dx + m.skyX(0) * radius * 0.35;
          if ((x - c.dx).abs() > size.width / 2) continue;
          canvas.drawCircle(Offset(x, c.dy), max(1.5, radius * 0.06),
              Paint()..color = Color(0xFF000000 | m.color));
        }
      case SkyTarget.venus:
        _paintPhase(canvas, c, radius * 0.7, 0.3);
    }
  }

  @override
  bool shouldRepaint(_EyepiecePainter old) =>
      old.target != target || old.magnification != magnification;
}

/// Aydınlık oranı [lit] olan gezegen diski: sağ taraf aydınlık, sonlandırıcı
/// (aydınlık-karanlık sınırı) bir elips.
void _paintPhase(Canvas canvas, Offset c, double r, double lit) {
  canvas.drawCircle(c, r, Paint()..color = const Color(0xFF2B2B35));
  final light = Paint()..color = const Color(0xFFFFF3C4);
  final k = (2 * lit - 1).clamp(-1.0, 1.0); // −1 yeni, +1 dolunay
  final path = Path()
    ..addArc(Rect.fromCircle(center: c, radius: r), -pi / 2, pi);
  // Sonlandırıcı: yarı eksen |k|·r olan elipsin yarısı.
  final ellipse = Rect.fromCenter(center: c, width: 2 * r * k.abs(), height: 2 * r);
  if (k >= 0) {
    path.addArc(ellipse, pi / 2, pi);
    canvas.drawPath(path, light);
  } else {
    final lune = Path()
      ..addArc(Rect.fromCircle(center: c, radius: r), -pi / 2, pi)
      ..arcTo(ellipse, pi / 2, -pi, false);
    canvas.drawPath(lune, light);
  }
}

/// Dünya'dan teleskopla görülen Venüs: evre ve görünen boy.
class VenusPhaseView extends StatelessWidget {
  const VenusPhaseView({super.key, required this.view, this.size = 150});

  final VenusView view;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const Key('galileoVenusView'),
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF05070F),
            shape: BoxShape.circle,
          ),
          child: CustomPaint(
            painter: _VenusPainter(view),
          ),
        ),
        const SizedBox(height: 4),
        _Tag('Dünya\'dan Venüs: ${view.phase.label.toLowerCase()}'),
      ],
    );
  }
}

class _VenusPainter extends CustomPainter {
  _VenusPainter(this.view);

  final VenusView view;

  @override
  void paint(Canvas canvas, Size size) {
    // Görünen boy uzaklıkla ters orantılı (en yakınken ~6 kat büyük).
    final r = (size.width * 0.08 * view.relativeSize).clamp(4.0, size.width * 0.44);
    _paintPhase(canvas, size.center(Offset.zero), r, view.litFraction);
  }

  @override
  bool shouldRepaint(_VenusPainter old) =>
      old.view.litFraction != view.litFraction ||
      old.view.relativeSize != view.relativeSize;
}

/// Teleskopta Jüpiter: yandan bakış, uydular bir çizgi üzerinde (Galileo'nun
/// defterindeki gibi).
class JupiterStrip extends StatelessWidget {
  const JupiterStrip({
    super.key,
    required this.nights,
    this.highlightId,
    this.width = 260,
  });

  final double nights;
  final String? highlightId;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const Key('galileoStrip'),
          width: width,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF05070F),
            borderRadius: BorderRadius.circular(27),
          ),
          child: CustomPaint(painter: _StripPainter(nights, highlightId)),
        ),
        const SizedBox(height: 4),
        _Tag('Teleskopta · ${formatTr(nights)}. gece'),
      ],
    );
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter(this.nights, this.highlightId);

  final double nights;
  final String? highlightId;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    // Kallisto (26,4) kenara sığsın: 1 Jüpiter yarıçapı = genişlik / 60.
    final unit = size.width / 60;
    canvas.drawCircle(c, unit * 1.6, Paint()..color = const Color(0xFFE0C9A0));
    for (final m in jupiterMoons) {
      if (m.hiddenAt(nights)) continue;
      final p = Offset(c.dx + m.skyX(nights) * unit, c.dy);
      final hl = m.id == highlightId;
      canvas.drawCircle(p, hl ? 4.5 : 3, Paint()..color = Color(0xFF000000 | m.color));
      if (hl) {
        canvas.drawCircle(
          p,
          8,
          Paint()
            ..color = const Color(0xFFFFEB3B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StripPainter old) =>
      old.nights != nights || old.highlightId != highlightId;
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.color = const Color(0xCC000000)});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
