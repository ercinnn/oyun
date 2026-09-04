enum ChessOutcome { whiteWins, blackWins, draw }

enum ChessOutcomeReason {
  checkmate,
  stalemate,
  fiftyMoveRule,
  repetition,
  insufficientMaterial,

  /// Oyuncunun süresi bitti (bkz. ChessController._onClockTick).
  timeout,
}
