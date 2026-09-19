/// Elektrik Atölyesi'nde bir oyuncunun durumu. Kazanan, en çok doğru cevap
/// verendir.
class ElectricityPlayerState {
  ElectricityPlayerState({required this.name});

  final String name;
  int correctCount = 0;
  int roundsPlayed = 0;
}
