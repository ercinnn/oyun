import 'package:flutter/material.dart';

import '../models/sequence_tile_color.dart';

/// Dizi Hafızası oyunundaki tek bir renkli kutu. Rengi, ait olduğu
/// [SequenceTileColor]'a göre değişir; [isLit] otomatik oynatım sırasında
/// parlamasını, [isWrong] yanlış tıklamada kısa bir kırmızı geri bildirim
/// göstermesini sağlar.
class SequenceTileWidget extends StatelessWidget {
  const SequenceTileWidget({
    super.key,
    required this.color,
    required this.isLit,
    required this.isWrong,
    required this.enabled,
    required this.onTap,
  });

  final SequenceTileColor color;
  final bool isLit;
  final bool isWrong;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill = isWrong
        ? Colors.red.shade900
        : (isLit ? color.litColor : color.idleColor);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLit
              ? [
                  BoxShadow(
                    color: fill.withValues(alpha: 0.6),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
