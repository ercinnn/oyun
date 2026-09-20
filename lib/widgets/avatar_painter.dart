import 'dart:math';

import 'package:flutter/material.dart';

import '../models/town/avatar_spec.dart';
import '../models/town/town_world.dart';

/// Avatarı [feet] noktasına (ayak ucu) çizer. [scale] 1 iken boy yaklaşık 44
/// px'tir. Yalnızca batı yönlerinde ([Facing.sw], [Facing.nw]) yatay olarak
/// aynalanır; yüz ancak kameraya dönükken ([Facing.se], [Facing.sw]) görünür.
///
/// Dünya, düzenleyici önizlemesi, NPC ve oda aynı fonksiyonu kullanır; tek
/// görünüm tanımı ([AvatarSpec]) her yerde aynı karakteri verir.
void paintAvatar(
  Canvas canvas,
  Offset feet,
  double scale,
  AvatarSpec spec, {
  Facing facing = Facing.se,
  bool moving = false,
  double time = 0,
}) {
  final s = scale;
  final front = facing == Facing.se || facing == Facing.sw;
  final mirror = facing == Facing.sw || facing == Facing.nw;

  final skin = skinPalette[spec.skin.clamp(0, skinPalette.length - 1)];
  final hair = hairPalette[spec.hairColor.clamp(0, hairPalette.length - 1)];
  final outfit = outfitPalette[spec.outfitColor.clamp(0, outfitPalette.length - 1)];

  final swing = moving ? sin(time * 14) : 0.0;
  final bob = moving ? (sin(time * 14) * sin(time * 14)).abs() * 2.0 * s : 0.0;

  // Yumuşak yer gölgesi (aynalamadan önce; simetrik).
  canvas.drawOval(
    Rect.fromCenter(center: feet, width: 22 * s, height: 9 * s),
    Paint()..color = const Color(0x40000000),
  );

  canvas.save();
  canvas.translate(feet.dx, feet.dy - bob);
  if (mirror) canvas.scale(-1, 1);

  final paint = Paint();
  final isDress = spec.outfit == 'outfit_dress';
  final pantsColor = spec.outfit == 'outfit_suit'
      ? const Color(0xFF37474F)
      : const Color(0xFF455A64);

  // Kanatlar arkada.
  if (spec.accessory == 'acc_wings') {
    paint.color = const Color(0xFFFFFFFF);
    canvas.drawOval(Rect.fromLTWH(-19 * s, -30 * s, 12 * s, 22 * s), paint);
    canvas.drawOval(Rect.fromLTWH(7 * s, -30 * s, 12 * s, 22 * s), paint);
    paint
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawOval(Rect.fromLTWH(-19 * s, -30 * s, 12 * s, 22 * s), paint);
    canvas.drawOval(Rect.fromLTWH(7 * s, -30 * s, 12 * s, 22 * s), paint);
    paint.style = PaintingStyle.fill;
  }

  // Bacaklar.
  if (!isDress) {
    paint.color = pantsColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-5 * s, -10 * s + swing * 2 * s, 4.5 * s, 10 * s),
        Radius.circular(2 * s),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.5 * s, -10 * s - swing * 2 * s, 4.5 * s, 10 * s),
        Radius.circular(2 * s),
      ),
      paint,
    );
  } else {
    paint.color = skin;
    canvas.drawRect(Rect.fromLTWH(-4.5 * s, -8 * s + swing * s, 3 * s, 8 * s), paint);
    canvas.drawRect(Rect.fromLTWH(1.5 * s, -8 * s - swing * s, 3 * s, 8 * s), paint);
  }

  // Gövde ve kol.
  _paintOutfit(canvas, s, spec, outfit, skin, swing);

  // Kolye.
  if (spec.accessory == 'acc_necklace') {
    paint.color = const Color(0xFFFFD54F);
    for (var i = -2; i <= 2; i++) {
      canvas.drawCircle(Offset(i * 2.4 * s, -24.5 * s + (i * i) * 0.35 * s), 1.2 * s, paint);
    }
  }

  // Baş.
  final head = Offset(0, -31 * s);
  paint.color = skin;
  canvas.drawCircle(head, 9 * s, paint);

  // Arkadan bakınca saç kafayı tamamen sarar.
  if (!front) {
    paint.color = hair;
    canvas.drawCircle(head, 9.2 * s, paint);
  }
  _paintHair(canvas, s, spec.hairStyle, hair, head, front);

  // Yüz.
  if (front) {
    paint.color = const Color(0xFF263238);
    canvas.drawCircle(head + Offset(-3 * s, 0.5 * s), 1.1 * s, paint);
    canvas.drawCircle(head + Offset(3 * s, 0.5 * s), 1.1 * s, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: head + Offset(0, 3.2 * s), width: 5 * s, height: 3.5 * s),
      0.2,
      pi - 0.4,
      false,
      paint,
    );
    paint.style = PaintingStyle.fill;
    // Yanaklar.
    paint.color = const Color(0x33FF5252);
    canvas.drawCircle(head + Offset(-5.5 * s, 3 * s), 1.6 * s, paint);
    canvas.drawCircle(head + Offset(5.5 * s, 3 * s), 1.6 * s, paint);

    if (spec.accessory == 'acc_glasses') {
      paint
        ..color = const Color(0xFF37474F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * s;
      canvas.drawCircle(head + Offset(-3.2 * s, 0.5 * s), 2.6 * s, paint);
      canvas.drawCircle(head + Offset(3.2 * s, 0.5 * s), 2.6 * s, paint);
      canvas.drawLine(
        head + Offset(-0.6 * s, 0.5 * s),
        head + Offset(0.6 * s, 0.5 * s),
        paint,
      );
      paint.style = PaintingStyle.fill;
    }
  }

  // Kulaklık.
  if (spec.accessory == 'acc_headphones') {
    paint
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s;
    canvas.drawArc(
      Rect.fromCenter(center: head, width: 21 * s, height: 21 * s),
      pi,
      pi,
      false,
      paint,
    );
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE53935);
    canvas.drawCircle(head + Offset(-10.5 * s, 1 * s), 3 * s, paint);
    canvas.drawCircle(head + Offset(10.5 * s, 1 * s), 3 * s, paint);
  }

  _paintHat(canvas, s, spec.hat, head);
  canvas.restore();
}

void _paintOutfit(
  Canvas canvas,
  double s,
  AvatarSpec spec,
  Color outfit,
  Color skin,
  double swing,
) {
  final paint = Paint();

  // Kollar (gövdeden önce; kollar gövdenin arkasında başlar).
  paint.color = spec.outfit == 'outfit_tee' || spec.outfit == 'outfit_dress'
      ? skin
      : outfit;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-11.5 * s, -22 * s + swing * s, 4 * s, 11 * s),
      Radius.circular(2 * s),
    ),
    paint,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(7.5 * s, -22 * s - swing * s, 4 * s, 11 * s),
      Radius.circular(2 * s),
    ),
    paint,
  );

  switch (spec.outfit) {
    case 'outfit_dress':
      paint.color = outfit;
      final path = Path()
        ..moveTo(-7 * s, -23 * s)
        ..lineTo(7 * s, -23 * s)
        ..lineTo(11 * s, -6 * s)
        ..lineTo(-11 * s, -6 * s)
        ..close();
      canvas.drawPath(path, paint);
    case 'outfit_hoodie':
      paint.color = outfit;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-8 * s, -23 * s, 16 * s, 14 * s), Radius.circular(3 * s)),
        paint,
      );
      // Kapüşon ve cep.
      paint.color = Color.lerp(outfit, const Color(0xFF000000), 0.18)!;
      canvas.drawOval(Rect.fromLTWH(-6 * s, -25 * s, 12 * s, 5 * s), paint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-4.5 * s, -15 * s, 9 * s, 4 * s), Radius.circular(1.5 * s)),
        paint,
      );
    case 'outfit_suit':
      paint.color = const Color(0xFF455A64);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-8 * s, -23 * s, 16 * s, 14 * s), Radius.circular(3 * s)),
        paint,
      );
      paint.color = const Color(0xFFFFFFFF);
      final shirt = Path()
        ..moveTo(-3 * s, -23 * s)
        ..lineTo(3 * s, -23 * s)
        ..lineTo(0, -14 * s)
        ..close();
      canvas.drawPath(shirt, paint);
      paint.color = outfit;
      canvas.drawRect(Rect.fromLTWH(-1 * s, -21.5 * s, 2 * s, 6 * s), paint);
    case 'outfit_space':
      paint.color = const Color(0xFFECEFF1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-8.5 * s, -23 * s, 17 * s, 14 * s), Radius.circular(4 * s)),
        paint,
      );
      paint.color = outfit;
      canvas.drawRect(Rect.fromLTWH(-8.5 * s, -17 * s, 17 * s, 2.5 * s), paint);
      paint.color = const Color(0xFFB0BEC5);
      canvas.drawCircle(Offset(0, -22 * s), 3 * s, paint);
    default: // tişört
      paint.color = outfit;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-8 * s, -23 * s, 16 * s, 14 * s), Radius.circular(3 * s)),
        paint,
      );
      paint.color = const Color(0x22000000);
      canvas.drawRect(Rect.fromLTWH(-8 * s, -12 * s, 16 * s, 3 * s), paint);
  }
}

void _paintHair(Canvas canvas, double s, String style, Color hair, Offset head, bool front) {
  final paint = Paint()..color = hair;
  // Alın/üst kısım: yarım daire.
  canvas.drawArc(
    Rect.fromCenter(center: head, width: 19.5 * s, height: 19.5 * s),
    pi,
    pi,
    true,
    paint,
  );
  switch (style) {
    case 'hair_long':
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(head.dx - 9.5 * s, head.dy - 2 * s, 4 * s, 14 * s),
          Radius.circular(2 * s),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(head.dx + 5.5 * s, head.dy - 2 * s, 4 * s, 14 * s),
          Radius.circular(2 * s),
        ),
        paint,
      );
    case 'hair_bun':
      canvas.drawCircle(head + Offset(0, -10 * s), 4.5 * s, paint);
    case 'hair_spiky':
      for (var i = -2; i <= 2; i++) {
        final x = head.dx + i * 3.6 * s;
        final path = Path()
          ..moveTo(x - 2 * s, head.dy - 8 * s)
          ..lineTo(x, head.dy - 14 * s)
          ..lineTo(x + 2 * s, head.dy - 8 * s)
          ..close();
        canvas.drawPath(path, paint);
      }
    case 'hair_curly':
      for (var i = -3; i <= 3; i++) {
        canvas.drawCircle(
          Offset(head.dx + i * 2.9 * s, head.dy - (7.5 - (i.abs() * 0.7)) * s),
          3.2 * s,
          paint,
        );
      }
    default: // kısa
      break;
  }
}

void _paintHat(Canvas canvas, double s, String hat, Offset head) {
  final paint = Paint();
  switch (hat) {
    case 'hat_cap':
      paint.color = const Color(0xFFE53935);
      canvas.drawArc(
        Rect.fromCenter(center: head + Offset(0, -1 * s), width: 20 * s, height: 20 * s),
        pi,
        pi,
        true,
        paint,
      );
      canvas.drawOval(Rect.fromLTWH(head.dx - 1 * s, head.dy - 3 * s, 13 * s, 4 * s), paint);
    case 'hat_party':
      paint.color = const Color(0xFFAB47BC);
      final cone = Path()
        ..moveTo(head.dx - 7 * s, head.dy - 7 * s)
        ..lineTo(head.dx + 7 * s, head.dy - 7 * s)
        ..lineTo(head.dx, head.dy - 21 * s)
        ..close();
      canvas.drawPath(cone, paint);
      paint.color = const Color(0xFFFFEB3B);
      canvas.drawCircle(Offset(head.dx, head.dy - 21 * s), 2.2 * s, paint);
    case 'hat_cowboy':
      paint.color = const Color(0xFF8D6E63);
      canvas.drawOval(
        Rect.fromCenter(center: head + Offset(0, -6 * s), width: 27 * s, height: 6 * s),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(head.dx - 6 * s, head.dy - 15 * s, 12 * s, 10 * s),
          Radius.circular(3 * s),
        ),
        paint,
      );
    case 'hat_crown':
      paint.color = const Color(0xFFFFC107);
      final crown = Path()
        ..moveTo(head.dx - 7 * s, head.dy - 7 * s)
        ..lineTo(head.dx - 7 * s, head.dy - 15 * s)
        ..lineTo(head.dx - 3.5 * s, head.dy - 11 * s)
        ..lineTo(head.dx, head.dy - 16 * s)
        ..lineTo(head.dx + 3.5 * s, head.dy - 11 * s)
        ..lineTo(head.dx + 7 * s, head.dy - 15 * s)
        ..lineTo(head.dx + 7 * s, head.dy - 7 * s)
        ..close();
      canvas.drawPath(crown, paint);
      paint.color = const Color(0xFFE53935);
      canvas.drawCircle(Offset(head.dx, head.dy - 9 * s), 1.4 * s, paint);
  }
}

/// Avatar önizlemesi (düzenleyici, mağaza, sonuç ekranları için).
class AvatarPreview extends StatelessWidget {
  const AvatarPreview({
    super.key,
    required this.spec,
    this.size = 120,
    this.facing = Facing.se,
  });

  final AvatarSpec spec;
  final double size;
  final Facing facing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PreviewPainter(spec, facing),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.spec, this.facing);

  final AvatarSpec spec;
  final Facing facing;

  @override
  void paint(Canvas canvas, Size size) {
    // Boy yaklaşık 44 * scale piksel; önizleme alanının %85'ini doldursun.
    final scale = size.height * 0.85 / 44;
    paintAvatar(
      canvas,
      Offset(size.width / 2, size.height * 0.95),
      scale,
      spec,
      facing: facing,
    );
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) =>
      oldDelegate.spec != spec || oldDelegate.facing != facing;
}
