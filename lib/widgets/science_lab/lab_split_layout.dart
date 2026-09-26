import 'package:flutter/material.dart';

import 'lab_labels.dart';
import 'lab_style.dart';
import 'scientist_name_badge.dart';

/// Bilim İnsanları ekranlarının ortak düzeni: geniş ekranda sahne solda,
/// panel sağda; telefonda sahne üstte (yüksekliğin ~%42'si), panel altta
/// kaydırılır. Sahne widget'ı aynı konumda kaldığı sürece 3B görünüm yeniden
/// kurulmaz.
class LabSplitLayout extends StatelessWidget {
  const LabSplitLayout({super.key, required this.scene, required this.panel});

  final Widget scene;
  final Widget panel;

  static const sideBySideWidth = 760.0;

  @override
  Widget build(BuildContext context) {
    final scientist = ScientistIdentity.maybeOf(context);
    // Bilim insanının adı sahnenin sol üstünde (sağ üstte yakınlaştırma
    // düğmeleri olduğu için sağdan pay bırakılır), etiket düğmesi sağ altta
    // (sol altta göstergeler var). Yapı oyun boyunca aynı kaldığı için 3B
    // görünüm yeniden kurulmaz.
    final scene = Stack(
      children: [
        Positioned.fill(child: this.scene),
        if (scientist != null)
          Positioned(
            left: 8,
            top: 8,
            right: 56,
            child: Align(
              alignment: Alignment.topLeft,
              child: ScientistNameBadge(scientist: scientist),
            ),
          ),
        Positioned(
          right: 8,
          bottom: 8,
          child: const LabLabelsToggle(),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= sideBySideWidth) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: scene),
                const SizedBox(width: 12),
                SizedBox(
                  width: 380,
                  child: SingleChildScrollView(child: panel),
                ),
              ],
            ),
          );
        }
        final sceneHeight = (constraints.maxHeight * 0.42).clamp(180.0, 380.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SizedBox(height: sceneHeight, child: scene),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: panel,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Keşif panellerindeki bilgi kartı: renkli sol kenar + ikon + okunaklı
/// metin. [title] verilirse metnin üstünde kalın bir başlık olur.
class LabInfoCard extends StatelessWidget {
  const LabInfoCard({
    super.key,
    required this.text,
    this.color,
    this.icon,
    this.title,
  });

  final String text;
  final Color? color;
  final IconData? icon;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final background = color ?? const Color(0xFFF1F4F8);
    final strong = labStrongColor(background);
    return Card(
      color: background,
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: strong, width: 5)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? Icons.lightbulb_outline, color: strong, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: TextStyle(
                        fontSize: LabText.body,
                        fontWeight: FontWeight.bold,
                        color: strong,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: LabText.body - 1,
                      height: LabText.bodyHeight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
