import 'dart:math';

const int rowCount = 10;
const int colCount = 5;
const int bombsPerRow = 2;

class PlayerState {
  PlayerState({required this.name, required this.bombLayout});

  final String name;

  /// Sabit bomba dizilimi: her satır için bomba olan sütun indeksleri (0..4).
  /// Oyuncunun turu boyunca değişmez.
  final List<Set<int>> bombLayout;

  /// Oyuncunun mevcut denemedeki (streak) aktif satırı.
  int currentRow = 0;

  /// Bombaya basma (baştan başlama) sayısı.
  int attempts = 0;

  /// Mevcut denemede her satırda seçilen (güvenli) sütun; henüz seçilmediyse null.
  final List<int?> streakClearedCols = List<int?>.filled(rowCount, null);

  bool finished = false;

  static List<Set<int>> generateBombLayout(Random rng) {
    return List.generate(rowCount, (_) {
      final cols = <int>{};
      while (cols.length < bombsPerRow) {
        cols.add(rng.nextInt(colCount));
      }
      return cols;
    });
  }

  bool isBomb(int row, int col) => bombLayout[row].contains(col);

  void registerBombHit() {
    attempts++;
    currentRow = 0;
    for (var i = 0; i < rowCount; i++) {
      streakClearedCols[i] = null;
    }
  }

  /// Güvenli hücre seçildiğinde çağrılır. Oyuncu 10. satırı da tamamladıysa true döner.
  bool registerSafeCell(int col) {
    streakClearedCols[currentRow] = col;
    currentRow++;
    if (currentRow >= rowCount) {
      finished = true;
      return true;
    }
    return false;
  }
}
