import 'package:flutter/material.dart';

import '../../config/scientists_3d.dart';
import '../../models/archimedes/archimedes_scene.dart';
import 'archimedes_lab_2d_view.dart';
import 'archimedes_lab_3d_view.dart';

/// Atölye sahnesi: 3B açıksa `ArchimedesLab3DView`, değilse 2B yedek. İkisi
/// aynı [ArchimedesScene] verisini çizer.
class ArchimedesSceneView extends StatelessWidget {
  const ArchimedesSceneView({super.key, required this.scene});

  final ArchimedesScene scene;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: scientistsUse3d
          ? ArchimedesLab3DView(scene: scene)
          : ArchimedesLab2DView(scene: scene),
    );
  }
}
