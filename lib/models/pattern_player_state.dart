/// Diziler oyunundaki bir oyuncunun durumu. Kazanan, en çok doğru
/// cevap verendir.
class PatternPlayerState {
  PatternPlayerState({required this.name});

  final String name;
  int correctCount = 0;
  int roundsPlayed = 0;
}
