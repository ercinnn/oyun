class GameResult {
  GameResult({
    required this.playerName,
    required this.attempts,
    required this.finishedAt,
  });

  final String playerName;
  final int attempts;
  final DateTime finishedAt;
}
