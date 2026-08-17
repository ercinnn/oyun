/// Renk mi Kelime mi? oyunundaki bir oyuncunun durumu. Kazanan, en çok
/// doğru cevap verendir.
class StroopPlayerState {
  StroopPlayerState({required this.name});

  final String name;
  int correctCount = 0;
  int roundsPlayed = 0;
}
