enum ElectricityPhase {
  setup,
  playing,
  turnTransition,
  finished,

  /// Serbest devre atölyesi (puansız).
  freeCircuit,

  /// Kablo yolu seviyeleri (puansız).
  wireLevels,
}
