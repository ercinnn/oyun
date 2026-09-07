/// Sudoku'da bir oyuncunun durumu. Her oyuncu, aynı zorluk seviyesinden
/// kendi bağımsız üretilmiş bulmacasını çözer (Kayan Yapboz'daki "her
/// oyuncunun kendi karıştırılmış tahtası" deseniyle aynı: rakibin panosunu
/// ezberlemek mümkün olmasın).
class SudokuPlayerState {
  SudokuPlayerState({
    required this.name,
    required this.solution,
    required this.given,
  }) : values = [
         for (var i = 0; i < given.length; i++) given[i] ? solution[i] : 0,
       ];

  final String name;

  /// 81 elemanlı, 1-9 dolu, benzersiz çözüm.
  final List<int> solution;

  /// 81 elemanlı; true ise o hücre baştan doludur ve değiştirilemez.
  final List<bool> given;

  /// Oyuncunun o an tahtaya girdiği değerler (given hücrelerde başlangıç
  /// değeriyle önceden doldurulur); 0 boş hücre demektir.
  final List<int> values;

  int mistakeCount = 0;
  bool finished = false;

  /// Tahta tamamen ve doğru şekilde dolduruldu mu (her hücre çözümle
  /// eşleşiyor mu).
  bool get isSolved {
    for (var i = 0; i < values.length; i++) {
      if (values[i] != solution[i]) return false;
    }
    return true;
  }
}
