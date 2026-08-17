import 'package:flutter/material.dart';

/// 0-5 arası bir puanı, [rating] kadar dolu geri kalanı boş yıldız olacak
/// şekilde çizer.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 14});

  static const int max = 5;

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Icon(
            i < rating ? Icons.star : Icons.star_border,
            size: size,
            color: Colors.amber.shade700,
          ),
      ],
    );
  }
}
