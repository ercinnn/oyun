import 'package:flutter/material.dart';

/// Altın sayacı rozeti (kasaba, mağaza ve ev ekranlarında ortak).
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('townCoins'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC263238),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 20),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dünyanın üstüne konan yarı saydam bilgi kutusu.
class HudBadge extends StatelessWidget {
  const HudBadge({super.key, required this.text, this.textKey});

  final String text;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC263238),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        key: textKey,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
