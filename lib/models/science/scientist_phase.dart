/// Bilim İnsanları oyunlarının ortak ekranları. [explore] puansız keşif
/// atölyesidir (Bitki Laboratuvarı'ndaki `freeLab` karşılığı).
enum ScientistPhase { setup, playing, turnTransition, finished, explore }

/// Görevlerde bir oyuncunun durumu. Kazanan, en çok doğru bilen.
class ScientistPlayerState {
  ScientistPlayerState({required this.name});

  final String name;
  int correctCount = 0;
  int roundsPlayed = 0;
}
