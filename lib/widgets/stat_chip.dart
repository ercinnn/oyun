import 'package:flutter/material.dart';

import '../theme/home_palette.dart';

/// Koyu zeminde küçük bir künye rozeti ("9 oyun", "1-2 oyuncu" gibi). Giriş
/// ekranı ve ana menünün hero bölümü aynı rozet setini gösterir.
class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: HomePalette.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: HomePalette.accent),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: HomePalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
