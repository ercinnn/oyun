import 'package:flutter/material.dart';

/// 0-5 arası bir puanı, [rating] kadar dolu geri kalanı boş yıldız olacak
/// şekilde çizer. Boş yıldızlar bilerek dolu olanlardan çok daha soluk bir
/// renkte: ana menünün koyu zemininde `star_border` da amber çizildiğinde
/// dolu/boş ayrımı bir bakışta okunmuyordu.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 14});

  static const int max = 5;

  static const _filledColor = Color(0xFFFFC145);
  static const _emptyColor = Color(0x33FFFFFF);

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Icon(
            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < rating ? _filledColor : _emptyColor,
          ),
      ],
    );
  }
}
