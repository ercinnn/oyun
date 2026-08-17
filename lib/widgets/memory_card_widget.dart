import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/memory_card.dart';

/// Tek bir hafıza kartı: kapalıyken düz bir arka yüz, açıkken sembolü
/// gösteren bir ön yüz arasında Y ekseninde 3D dönerek geçiş yapar.
class MemoryCardWidget extends StatelessWidget {
  const MemoryCardWidget({super.key, required this.card, this.onTap});

  final MemoryCard card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool showFront = card.isFaceUp || card.isMatched;

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: showFront ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          final double angle = t * math.pi;
          final bool showingFrontFace = angle > math.pi / 2;

          final Widget face = showingFrontFace
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _CardFace(front: true, card: card),
                )
              : _CardFace(front: false, card: card);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..rotateY(angle),
            child: face,
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.front, required this.card});

  final bool front;
  final MemoryCard card;

  @override
  Widget build(BuildContext context) {
    if (!front) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: const Center(
          child: Icon(Icons.help_outline, color: Colors.white70, size: 22),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: card.isMatched ? Colors.green.shade100 : Colors.white,
        border: Border.all(
          color: card.isMatched ? Colors.green.shade400 : Colors.grey.shade300,
          width: card.isMatched ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Stack'in varsayılan hizalaması sol-üsttir; içeriği eski (tek
          // başına DecoratedBox'ın çocuğu olduğu) haline, yani hücrenin
          // tamamını kaplayıp ortalanmış konuma geri getirmek için
          // Positioned.fill ile eski sıkı (tight) kısıtlamalar geri verilir.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sembol: 28 taban * 1.2 * 1.25 = 42. Kart (hücre) boyutu
                  // değişmiyor, sadece içerik büyüyor.
                  Text(
                    card.symbol,
                    style: const TextStyle(fontSize: 28 * 1.2 * 1.25),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10 * 1.25,
                      fontWeight: FontWeight.w600,
                      color: card.isMatched
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bulunan kartın seslendirme için tıklanabilir olduğunu belirten
          // küçük hoparlör ipucu.
          if (card.isMatched)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(
                Icons.volume_up,
                size: 12,
                color: Colors.green.shade700,
              ),
            ),
        ],
      ),
    );
  }
}
