/// Diziler oyunundaki tek bir tur: [sequence] dizideki bilinen ilk
/// dört terimi, [answer] gizli beşinci terimi, [options] ise cevap
/// butonlarının (karışık) sırasını tutar.
class PatternTrial {
  const PatternTrial({
    required this.sequence,
    required this.answer,
    required this.options,
  });

  final List<int> sequence;
  final int answer;
  final List<int> options;
}
