/// Simon Diyor ki oyunundaki bir oyuncunun durumu. Kazanan, en çok doğru
/// cevap verendir.
class SimonPlayerState {
  SimonPlayerState({required this.name});

  final String name;
  int correctCount = 0;
  int roundsPlayed = 0;
}
