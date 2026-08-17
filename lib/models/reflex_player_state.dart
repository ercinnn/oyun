/// Tepki Süresi oyunundaki bir oyuncunun durumu. Kazanan, en düşük ortalama
/// tepki süresine sahip olandır.
class ReflexPlayerState {
  ReflexPlayerState({required this.name});

  final String name;

  /// Her turda kaydedilen tepki süresi (ms). Erken başlanan turlarda
  /// [falseStartPenaltyMs] (bkz. `controllers/reflex_controller.dart`) yer
  /// alır.
  List<int> reactionTimes = [];
  int roundsPlayed = 0;

  double get averageMs => reactionTimes.isEmpty
      ? 0
      : reactionTimes.reduce((a, b) => a + b) / reactionTimes.length;
}
