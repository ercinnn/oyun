import 'package:flutter/material.dart';

/// Kutu (aktif hücre), oyun alanı arka planı ve sayı (metin) renklerinden
/// oluşan bir görünüm kombinasyonu. Temizlenmiş/kilitli hücre renkleri bu
/// temadan bağımsız, sabit kalır (oyun durumu geri bildirimini korumak için).
class GameColorTheme {
  const GameColorTheme({
    required this.name,
    required this.boxColor,
    required this.backgroundColor,
    required this.numberColor,
  });

  final String name;
  final Color boxColor;
  final Color backgroundColor;
  final Color numberColor;
}

const List<GameColorTheme> standardThemes = [
  GameColorTheme(
    name: 'Klasik',
    boxColor: Colors.indigo,
    backgroundColor: Color(0xFFF5F5F5),
    numberColor: Colors.white,
  ),
  GameColorTheme(
    name: 'Okyanus',
    boxColor: Colors.teal,
    backgroundColor: Color(0xFFE0F7FA),
    numberColor: Colors.white,
  ),
  GameColorTheme(
    name: 'Gün Batımı',
    boxColor: Colors.deepOrange,
    backgroundColor: Color(0xFFFFF3E0),
    numberColor: Colors.white,
  ),
  GameColorTheme(
    name: 'Mor Rüya',
    boxColor: Colors.purple,
    backgroundColor: Color(0xFFF3E5F5),
    numberColor: Colors.white,
  ),
  GameColorTheme(
    name: 'Bahar',
    boxColor: Colors.pink,
    backgroundColor: Color(0xFFFCE4EC),
    numberColor: Colors.white,
  ),
];

/// Özel kombinasyon modunda kutu/arka plan/sayı renkleri için sunulan,
/// hepsi için ortak 8 renklik palet.
const List<Color> customColorPalette = [
  Colors.indigo,
  Colors.blue,
  Colors.teal,
  Colors.green,
  Color(0xFFFFA000),
  Colors.deepOrange,
  Colors.purple,
  Colors.pink,
];
