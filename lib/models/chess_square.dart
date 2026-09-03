/// Tahta 8x8, düz bir liste olarak tutulur: `index = rank * 8 + file`.
/// `file` 0='a'..7='h', `rank` 0='1'..7='8'. Bu dosyadaki yardımcılar tüm
/// hamle üretiminin ortak, tek bir koordinat dönüşüm noktasından geçmesini
/// sağlar — ham index aritmetiği (`index + 1` gibi) satır kenarlarını
/// sarabileceği için hiçbir hamle üretici doğrudan index üzerinde toplama
/// çıkarma yapmamalı, her zaman file/rank'e çevirip sınır kontrolü
/// (`0..7`) yaptıktan sonra tekrar index'e dönmelidir.
int fileOf(int square) => square % 8;

int rankOf(int square) => square ~/ 8;

bool isOnBoard(int file, int rank) => file >= 0 && file < 8 && rank >= 0 && rank < 8;

int squareIndex(int file, int rank) => rank * 8 + file;

/// Standart cebirsel gösterim ('e4' gibi), test/debug okunabilirliği için.
String algebraic(int square) {
  final file = fileOf(square);
  final rank = rankOf(square);
  return '${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}';
}
