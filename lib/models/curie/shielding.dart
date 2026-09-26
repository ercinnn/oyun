/// Işın türleri ve kalkanlar — saf model.
///
/// Radyoaktif maddeler üç tür ışın yayar:
/// - **Alfa**: ağır ve yavaş; bir kâğıt yaprağı bile durdurur.
/// - **Beta**: daha hafif ve hızlı; kâğıttan geçer, ince alüminyum durdurur.
/// - **Gama**: ışık gibi bir ışın; alüminyumdan da geçer, ancak kalın kurşun
///   büyük kısmını durdurur.
/// Kalkanın geçirdiği oran tabloda sadeleştirilmiştir.
library;

import 'geiger.dart';

enum RayType {
  alpha('Alfa', 0xFF7043),
  beta('Beta', 0x42A5F5),
  gamma('Gama', 0xAB47BC);

  const RayType(this.label, this.color);
  final String label;
  final int color;
}

enum Shield {
  none('Kalkan yok'),
  paper('Kâğıt'),
  aluminum('Alüminyum'),
  lead('Kurşun');

  const Shield(this.label);
  final String label;
}

/// Kaynağın kalkansız, sayaç önündeki hızı (tık/sn).
const double sourceCps = 60;

/// Kalkanın geçirdiği oran (0-1).
double transmission(RayType ray, Shield shield) => switch ((ray, shield)) {
  (_, Shield.none) => 1.0,
  (RayType.alpha, _) => 0.0,
  (RayType.beta, Shield.paper) => 0.9,
  (RayType.beta, _) => 0.0,
  (RayType.gamma, Shield.paper) => 1.0,
  (RayType.gamma, Shield.aluminum) => 0.9,
  (RayType.gamma, Shield.lead) => 0.08,
};

double shieldedCps(RayType ray, Shield shield) =>
    backgroundCps + sourceCps * transmission(ray, shield);

/// Işını (neredeyse tamamen) durduran en ince kalkan. Gama kurşunda bile
/// biraz geçer; "neredeyse" eşiği %10.
Shield thinnestStopper(RayType ray) {
  for (final s in [Shield.paper, Shield.aluminum, Shield.lead]) {
    if (transmission(ray, s) <= 0.1) return s;
  }
  return Shield.lead;
}
