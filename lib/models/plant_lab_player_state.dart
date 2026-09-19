/// Bitki Laboratuvarı'nda bir oyuncunun durumu. Kazanan, en çok doğru cevap
/// verendir.
class PlantLabPlayerState {
  PlantLabPlayerState({required this.name});

  final String name;
  int correctCount = 0;
  int roundsPlayed = 0;
}
