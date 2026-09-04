import 'package:flutter/material.dart';

import '../theme/home_palette.dart';

/// Platformun logo işareti: gradyanlı yuvarlatılmış kare içinde bir oyun kolu
/// ikonu. Giriş ekranı ve ana menünün üst barı aynı işareti kullanır (tek fark
/// [size]), böylece giriş → ana sayfa geçişinde marka aynı kalır.
class PlatformLogoMark extends StatelessWidget {
  const PlatformLogoMark({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomePalette.accent, Color(0xFF9C6CFF)],
        ),
        borderRadius: BorderRadius.circular(size * 0.29),
        boxShadow: [
          BoxShadow(
            color: HomePalette.accent.withValues(alpha: 0.40),
            blurRadius: size * 0.42,
            offset: Offset(0, size * 0.11),
          ),
        ],
      ),
      child: Icon(
        Icons.videogame_asset_rounded,
        size: size * 0.53,
        color: Colors.white,
      ),
    );
  }
}
