import 'dart:math';

import 'sudoku_difficulty.dart';

const int sudokuSize = 9;
const int sudokuBoxSize = 3;

const int _fillNodeBudget = 200000;
const int _uniquenessNodeBudget = 20000;

int sudokuRowOf(int index) => index ~/ sudokuSize;
int sudokuColOf(int index) => index % sudokuSize;
int sudokuBoxOf(int index) =>
    (sudokuRowOf(index) ~/ sudokuBoxSize) * sudokuBoxSize +
    sudokuColOf(index) ~/ sudokuBoxSize;

/// Çözülmüş tahta + hangi hücrelerin ipucu (given) olduğu. `given` false
/// olan hücreler oyuncu tarafından doldurulur.
class SudokuPuzzle {
  const SudokuPuzzle({required this.solution, required this.given});

  /// 81 elemanlı (satır*9+sütun), 1-9 dolu, benzersiz çözüm.
  final List<int> solution;

  /// 81 elemanlı; true ise o hücre baştan doludur ve değiştirilemez.
  final List<bool> given;
}

/// En az adaylı hücreyi önce deneyen (MRV) bütçeli backtracking arayıcı.
/// Hem tam tahta tamamlamak (`fillComplete`, limit 1) hem de benzersizlik
/// kontrolü (`countSolutions`, limit 2 ile erken çıkış) için kullanılır.
/// Düğüm bütçesi aşılırsa arama iptal edilir — `ChessAI`'nin süre bütçesi
/// felsefesiyle aynı, burada senkron/deterministik olduğu için süre yerine
/// düğüm sayısı sınırlanıyor.
class _SudokuSolver {
  _SudokuSolver(this.grid, {required this.nodeBudget});

  final List<int> grid;
  final int nodeBudget;
  int _nodes = 0;
  bool _budgetExceeded = false;

  bool get budgetExceeded => _budgetExceeded;

  bool fillComplete(Random random) =>
      _backtrack(random: random, limit: 1) == 1 && !_budgetExceeded;

  int countSolutions({required int limit}) =>
      _backtrack(random: null, limit: limit);

  int _backtrack({required Random? random, required int limit}) {
    if (_budgetExceeded) return 0;
    if (++_nodes > nodeBudget) {
      _budgetExceeded = true;
      return 0;
    }

    var bestIndex = -1;
    var bestCandidates = const <int>[];
    for (var i = 0; i < grid.length; i++) {
      if (grid[i] != 0) continue;
      final candidates = _candidatesFor(i);
      if (candidates.isEmpty) return 0; // çıkmaz sokak
      if (bestIndex == -1 || candidates.length < bestCandidates.length) {
        bestIndex = i;
        bestCandidates = candidates;
        if (candidates.length == 1) break;
      }
    }
    if (bestIndex == -1) return 1; // tahta dolu: bir çözüm bulundu

    final order = random == null
        ? bestCandidates
        : (List<int>.from(bestCandidates)..shuffle(random));
    var found = 0;
    for (final value in order) {
      grid[bestIndex] = value;
      found += _backtrack(random: random, limit: limit);
      // Limit'e (ya da bütçeye) ulaşıldıysa hücreyi SIFIRLAMADAN dön —
      // aksi hâlde bu son başarılı atamayı da geri alıp `fillComplete`'in
      // döndürdüğü tahtayı bozardık (limit'e ulaşmayan ara denemelerde ise
      // bir sonraki adaya geçmeden önce geri alınması gerekir).
      if (_budgetExceeded || found >= limit) return found;
      grid[bestIndex] = 0;
    }
    return found;
  }

  List<int> _candidatesFor(int index) {
    final row = sudokuRowOf(index);
    final col = sudokuColOf(index);
    final boxRow = (row ~/ sudokuBoxSize) * sudokuBoxSize;
    final boxCol = (col ~/ sudokuBoxSize) * sudokuBoxSize;
    final used = List<bool>.filled(sudokuSize + 1, false);
    for (var c = 0; c < sudokuSize; c++) {
      final v = grid[row * sudokuSize + c];
      if (v != 0) used[v] = true;
    }
    for (var r = 0; r < sudokuSize; r++) {
      final v = grid[r * sudokuSize + col];
      if (v != 0) used[v] = true;
    }
    for (var r = boxRow; r < boxRow + sudokuBoxSize; r++) {
      for (var c = boxCol; c < boxCol + sudokuBoxSize; c++) {
        final v = grid[r * sudokuSize + c];
        if (v != 0) used[v] = true;
      }
    }
    return [for (var d = 1; d <= sudokuSize; d++) if (!used[d]) d];
  }
}

/// Tam, geçerli, rastgele bir 9×9 Sudoku çözümü üretir. Önce birbirinden
/// bağımsız (satır/sütun paylaşmayan, dolayısıyla çakışma kontrolü
/// gerektirmeyen) 3 köşegen 3×3 kutuyu karıştırılmış 1-9 permütasyonlarıyla
/// doldurur, sonra gerisini MRV + karıştırılmış aday sırasıyla tamamlar —
/// bu, boş bir tahtadan doğrudan backtracking yapmaktan çok daha hızlıdır.
List<int> generateSolvedSudokuGrid(Random random) {
  final grid = List<int>.filled(sudokuSize * sudokuSize, 0);
  for (final boxStart in [0, 3, 6]) {
    final values = List<int>.generate(sudokuSize, (i) => i + 1)
      ..shuffle(random);
    var k = 0;
    for (var r = 0; r < sudokuBoxSize; r++) {
      for (var c = 0; c < sudokuBoxSize; c++) {
        grid[(boxStart + r) * sudokuSize + (boxStart + c)] = values[k++];
      }
    }
  }
  final solved = _SudokuSolver(
    grid,
    nodeBudget: _fillNodeBudget,
  ).fillComplete(random);
  if (!solved) {
    // Köşegen kutulardan başlayan bir tahta matematiksel olarak her zaman
    // tamamlanabilir; bu yalnızca düğüm bütçesi aşırı düşük ayarlanmışsa
    // tetiklenir.
    throw StateError('Sudoku tahtası üretilemedi (düğüm bütçesi aşıldı)');
  }
  return grid;
}

/// [difficulty]'ye göre bir Sudoku bulmacası üretir: çözülmüş tahtadan
/// başlayıp hücreleri karıştırılmış sırayla tek tek çıkarır; bir çıkarma
/// yalnızca tahta hâlâ **benzersiz** çözümlüyse kalıcıdır (limit 2 ile
/// sayım — ikinci bir çözüm bulunur bulunmaz erken çıkar). `targetClues`'a
/// ulaşınca ya da çıkarılabilecek başka hücre kalmayınca durur.
///
/// Tek geçişlik açgözlü çıkarma bilerek yeterli görüldü: `targetClues`
/// değerleri (40/32/26) tek geçişte rahatça ulaşılabilir aralıkta —
/// çoklu deneme yapıp en seyrek sonucu tutmak (bir sonraki optimizasyon
/// adımı olabilir) burada gereksiz karmaşıklık/çalışma süresi eklerdi.
SudokuPuzzle generateSudokuPuzzle(SudokuDifficulty difficulty, Random random) {
  final solution = generateSolvedSudokuGrid(random);
  final given = List<bool>.filled(sudokuSize * sudokuSize, true);
  var cluesRemaining = sudokuSize * sudokuSize;
  final order = List<int>.generate(sudokuSize * sudokuSize, (i) => i)
    ..shuffle(random);

  for (final index in order) {
    if (cluesRemaining <= difficulty.targetClues) break;
    given[index] = false;
    final probe = List<int>.generate(
      sudokuSize * sudokuSize,
      (i) => given[i] ? solution[i] : 0,
    );
    final solver = _SudokuSolver(probe, nodeBudget: _uniquenessNodeBudget);
    final solutionCount = solver.countSolutions(limit: 2);
    final isUnique = solutionCount == 1 && !solver.budgetExceeded;
    if (isUnique) {
      cluesRemaining--;
    } else {
      // Benzersizlik bozuldu ya da bütçe içinde kanıtlanamadı: temkinli
      // davranıp hücreyi geri koy.
      given[index] = true;
    }
  }

  return SudokuPuzzle(solution: solution, given: given);
}
