/// Sudoku'da ne kadar ipucu (dolu hücre) bırakılacağını belirleyen üç
/// zorluk seviyesi. `PatternDifficulty`/`MultiplicationDifficulty` ile aynı
/// şekil: `label` + her zaman görünen (tooltip değil) bir `hint`.
enum SudokuDifficulty {
  kolay(
    label: 'Kolay',
    hint: 'Çok sayıda ipucu bırakılır, çözmesi kolaydır.',
    targetClues: 40,
  ),
  orta(
    label: 'Orta',
    hint: 'Orta sayıda ipucu, dikkatli çıkarım ister.',
    targetClues: 32,
  ),
  zor(
    label: 'Zor',
    hint: 'Az ipucu bırakılır, ileri seviye mantık gerekir.',
    targetClues: 26,
  );

  const SudokuDifficulty({
    required this.label,
    required this.hint,
    required this.targetClues,
  });

  final String label;

  /// Kurulum ekranında seviyenin altında gösterilen açıklama.
  final String hint;

  /// Hedef ipucu sayısı — bir garanti değil: benzersizliği koruyan açgözlü
  /// hücre çıkarma süreci seyrek seviyelerde bu hedefin üstünde takılabilir
  /// (bkz. `generateSudokuPuzzle` içindeki not).
  final int targetClues;
}
