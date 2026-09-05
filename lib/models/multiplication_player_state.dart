/// Çarpım Bahçesi oyunundaki bir oyuncunun durumu. Kazanan, en çok doğru
/// cevap verendir.
class MultiplicationPlayerState {
  MultiplicationPlayerState({required this.name});

  final String name;
  int correctCount = 0;
  int roundsPlayed = 0;
}
