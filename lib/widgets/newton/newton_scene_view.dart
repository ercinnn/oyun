import 'package:flutter/material.dart';

import '../../config/scientists_3d.dart';
import '../../models/newton/newton_scene.dart';
import 'newton_lab_2d_view.dart';
import 'newton_lab_3d_view.dart';

/// Newton laboratuvarı: 3B açıksa `NewtonLab3DView`, değilse 2B yedek.
class NewtonSceneView extends StatelessWidget {
  const NewtonSceneView({super.key, required this.scene});

  final NewtonScene scene;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: scientistsUse3d
          ? NewtonLab3DView(scene: scene)
          : NewtonLab2DView(scene: scene),
    );
  }
}
