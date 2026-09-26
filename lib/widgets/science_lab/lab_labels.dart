import 'dart:math';

import 'package:flutter/material.dart';

/// Sahne etiketlerinin türü: [tag] büyük harfli daire (A/B), [name] nesne
/// adı hapı, [value] ölçüm (ör. "12 cm") — açık zeminli, koyu yazılı.
enum LabLabelKind { tag, name, value }

/// Deney sahnesindeki bir nesnenin üstünde duran etiket. Hem 3B görünüm
/// (`Lab3DState.labels`, dünya koordinatından izdüşürülür) hem 2B painter'lar
/// ([paintLabLabel]) aynı görünümle çizer; böylece soru metnindeki "A kabı",
/// "Prizma" gibi adlar sahnede bulunabilir.
class LabLabel {
  const LabLabel(
    this.text, {
    this.kind = LabLabelKind.name,
    this.color,
    this.emoji,
  });

  /// Görev A/B etiketi: soru metinlerindeki harflerle aynı renk.
  const LabLabel.tag(this.text, {this.color})
    : kind = LabLabelKind.tag,
      emoji = null;

  const LabLabel.value(this.text, {this.color})
    : kind = LabLabelKind.value,
      emoji = null;

  final String text;
  final LabLabelKind kind;
  final Color? color;
  final String? emoji;

  Color get resolvedColor =>
      color ??
      switch (kind) {
        LabLabelKind.tag => labTagColor(text),
        LabLabelKind.name => const Color(0xFF37474F),
        LabLabelKind.value => const Color(0xFF01579B),
      };
}

/// A/B/C harflerinin sabit renkleri: sahnedeki etiket ile görev panelindeki
/// seçenek dairesi aynı rengi taşır ("A kabı" = mavi, "B kabı" = turuncu).
Color labTagColor(String tag) => switch (tag.isEmpty ? '' : tag[0]) {
  'A' => const Color(0xFF1E88E5),
  'B' => const Color(0xFFF4511E),
  'C' => const Color(0xFF8E24AA),
  'D' => const Color(0xFF00897B),
  _ => const Color(0xFF546E7A),
};

/// Etiketlerin açık/kapalı tercihi (tüm bilim insanları için, oturum boyu).
/// Sahnenin sağ altındaki düğme değiştirir.
final ValueNotifier<bool> labLabelsOn = ValueNotifier(true);

/// Ekrana yerleşmiş etiket: [tip] etiketin gösterdiği nokta (etiket onun
/// hemen üstünde durur).
typedef PlacedLabLabel = ({LabLabel label, Offset tip});

/// Etiketi [tip] noktasının üstüne çizer (küçük bir sivri uçla). Etiket
/// sahnenin dışına taşmasın diye yatayda [bounds] içine kaydırılır.
///
/// TextPainter her çağrıda yeniden kurulur: emoji içeren metin önbelleğe
/// alınırsa CanvasKit'te ilk karedeki boş kutu kalıcı olabilir (CLAUDE.md,
/// "Emoji tuzağı").
void paintLabLabel(
  Canvas canvas,
  Offset tip,
  LabLabel label, {
  Size? bounds,
  double scale = 1,
}) {
  final color = label.resolvedColor;
  if (label.kind == LabLabelKind.tag) {
    final r = 15.0 * scale;
    final center = tip - Offset(0, r + 6 * scale);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 6 * scale, center.dy + r * 0.6)
      ..lineTo(tip.dx + 6 * scale, center.dy + r * 0.6)
      ..close();
    canvas.drawCircle(
      center + const Offset(0, 1.5),
      r + 1,
      Paint()..color = const Color(0x40000000),
    );
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(center, r, Paint()..color = color);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: label.text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 17 * scale,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    return;
  }

  final isValue = label.kind == LabLabelKind.value;
  final text = label.emoji == null ? label.text : '${label.emoji} ${label.text}';
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: isValue ? color : Colors.white,
        fontSize: 14 * scale,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: 220 * scale);
  final padH = 9 * scale, padV = 5 * scale, arrow = 6 * scale;
  final w = tp.width + padH * 2;
  final h = tp.height + padV * 2;
  var left = tip.dx - w / 2;
  if (bounds != null) {
    left = left.clamp(4.0, max(4.0, bounds.width - w - 4)).toDouble();
  }
  final top = tip.dy - arrow - h;
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(left, top, w, h),
    Radius.circular(h / 2),
  );
  final fill = isValue ? const Color(0xF2FFFFFF) : color.withValues(alpha: 0.93);
  canvas.drawRRect(
    rect.shift(const Offset(0, 1.5)),
    Paint()..color = const Color(0x33000000),
  );
  final arrowX = tip.dx.clamp(left + h / 2, left + w - h / 2).toDouble();
  canvas.drawPath(
    Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(arrowX - arrow, top + h - 1)
      ..lineTo(arrowX + arrow, top + h - 1)
      ..close(),
    Paint()..color = fill,
  );
  canvas.drawRRect(rect, Paint()..color = fill);
  if (isValue) {
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale,
    );
  }
  tp.paint(canvas, Offset(left + padH, top + padV));
}

/// Yerleşmiş etiketlerin katmanı (3B görünümün üstünde). [placed] değiştikçe
/// yalnızca bu katman yeniden çizilir; widget ağacı yeniden kurulmaz.
class LabLabelLayer extends StatelessWidget {
  const LabLabelLayer({super.key, required this.placed});

  final ValueNotifier<List<PlacedLabLabel>> placed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _LabLabelPainter(placed),
      ),
    );
  }
}

class _LabLabelPainter extends CustomPainter {
  _LabLabelPainter(this.placed) : super(repaint: placed);

  final ValueNotifier<List<PlacedLabLabel>> placed;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in placed.value) {
      paintLabLabel(canvas, p.tip, p.label, bounds: size);
    }
  }

  @override
  bool shouldRepaint(_LabLabelPainter old) => old.placed != placed;
}

/// Etiketleri aç/kapa düğmesi (sahnenin sağ altı). Dar ekranda yalnızca
/// ikon kalır ki sol alttaki göstergeyle çakışmasın.
class LabLabelsToggle extends StatelessWidget {
  const LabLabelsToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return ValueListenableBuilder<bool>(
      valueListenable: labLabelsOn,
      builder: (context, on, _) => Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const StadiumBorder(),
        elevation: 2,
        child: InkWell(
          key: const Key('labLabelsToggle'),
          customBorder: const StadiumBorder(),
          onTap: () => labLabelsOn.value = !on,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: on ? 'Etiketleri gizle' : 'Etiketleri göster',
                  child: Icon(
                    on ? Icons.label : Icons.label_off_outlined,
                    size: 18,
                    color: const Color(0xFF37474F),
                  ),
                ),
                if (!compact) ...[
                const SizedBox(width: 4),
                Text(
                  on ? 'Etiketler açık' : 'Etiketler kapalı',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF37474F),
                  ),
                ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
