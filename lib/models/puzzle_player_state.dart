import 'dart:math';

const int puzzleGridSize = 4;

/// Çözülmüş tahttan başlayıp bu kadar rastgele geçerli hamle geriye doğru
/// oynanarak karıştırılır. Rastgele bir permütasyon üretmek yerine (15'lik
/// bulmacada her permütasyon çözülebilir değildir — permütasyon parity
/// kısıtı var) her adım gerçek bir hamlenin tersi olduğundan sonuç her
/// zaman çözülebilir; parity matematiğiyle uğraşmaya gerek kalmaz.
const int _shuffleMoves = 150;

/// Kayan Yapboz oyunundaki bir oyuncunun durumu. Kazanan, en az hamlede
/// tahtasını çözendir.
class PuzzlePlayerState {
  PuzzlePlayerState({required this.name, required this.tiles});

  final String name;

  /// `puzzleGridSize * puzzleGridSize` uzunluğunda; `1..15` kutu
  /// numaraları, `0` boş kareyi temsil eder.
  final List<int> tiles;
  int moveCount = 0;
  bool finished = false;

  static List<int> generateShuffledTiles(Random rng) {
    final size = puzzleGridSize * puzzleGridSize;
    final tiles = List<int>.generate(size, (i) => i == size - 1 ? 0 : i + 1);
    var emptyIndex = size - 1;
    for (var i = 0; i < _shuffleMoves; i++) {
      final neighbors = adjacentIndices(emptyIndex);
      final swapWith = neighbors[rng.nextInt(neighbors.length)];
      tiles[emptyIndex] = tiles[swapWith];
      tiles[swapWith] = 0;
      emptyIndex = swapWith;
    }
    return tiles;
  }
}

/// [index]'e (satır*puzzleGridSize + sütun) dikey/yatay komşu olan
/// pozisyonlar. Hem karıştırma hem de `PuzzleController.moveTile`
/// tarafından paylaşılıyor.
List<int> adjacentIndices(int index) {
  final row = index ~/ puzzleGridSize;
  final col = index % puzzleGridSize;
  final result = <int>[];
  if (row > 0) result.add(index - puzzleGridSize);
  if (row < puzzleGridSize - 1) result.add(index + puzzleGridSize);
  if (col > 0) result.add(index - 1);
  if (col < puzzleGridSize - 1) result.add(index + 1);
  return result;
}

bool isPuzzleSolved(List<int> tiles) {
  for (var i = 0; i < tiles.length - 1; i++) {
    if (tiles[i] != i + 1) return false;
  }
  return tiles.last == 0;
}
