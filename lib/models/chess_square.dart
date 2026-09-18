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

/// [algebraic]'in tersi: 'e4' -> 28. Ders içeriği ve testler kareleri
/// ham index yerine bu okunaklı adlarla yazar.
int squareFromName(String name) {
  assert(name.length == 2, 'Kare adı 2 karakter olmalı: $name');
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = name.codeUnitAt(1) - '1'.codeUnitAt(0);
  assert(isOnBoard(file, rank), 'Tahta dışı kare: $name');
  return squareIndex(file, rank);
}
