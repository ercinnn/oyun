import 'package:flutter/material.dart';

/// Tur başına bir nokta: yeşil = doğru, turuncu = yanlış, gri = kalan;
/// [current] turun noktası halkayla vurgulanır.
class RoundDots extends StatelessWidget {
  const RoundDots({
    super.key,
    required this.total,
    required this.results,
    this.current,
    this.size = 20,
  });

  final int total;
  final List<bool> results;
  final int? current;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < total; i++)
          _Dot(
            size: size,
            result: i < results.length ? results[i] : null,
            current: i == current,
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.result, required this.current});

  final double size;
  final bool? result;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final color = switch (result) {
      true => Colors.green.shade500,
      false => Colors.deepOrange.shade400,
      null => Colors.grey.shade300,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: current
            ? Border.all(color: Colors.blueGrey.shade700, width: 2.5)
            : null,
      ),
      child: result == null
          ? null
          : Icon(
              result! ? Icons.check : Icons.close,
              size: size * 0.7,
              color: Colors.white,
            ),
    );
  }
}

/// Doğru sayısı rozeti ("⭐ 3 doğru").
class ScoreChip extends StatelessWidget {
  const ScoreChip({super.key, required this.correct});

  final int correct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 18, color: Colors.amber.shade800),
          const SizedBox(width: 4),
          Text(
            '$correct doğru',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
