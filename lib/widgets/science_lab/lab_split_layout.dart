import 'package:flutter/material.dart';

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
    // düğmeleri olduğu için sağdan pay bırakılır). Yapı oyun boyunca aynı
    // kaldığı için 3B görünüm yeniden kurulmaz.
    final scene = scientist == null
        ? this.scene
        : Stack(
            children: [
              Positioned.fill(child: this.scene),
              Positioned(
                left: 8,
                top: 8,
                right: 56,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ScientistNameBadge(scientist: scientist),
                ),
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

/// Keşif panellerindeki bilgi kartı.
class LabInfoCard extends StatelessWidget {
  const LabInfoCard({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
    );
  }
}
