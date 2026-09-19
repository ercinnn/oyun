/// Bitki Laboratuvarı'nda deneyin değiştirilebilen üç etkeni. Her etkenin üç
/// kademesi vardır (0, 1, 2); kademe adları [levelLabels]'ta durur.
enum PlantFactor {
  light('Işık', 'ışık'),
  water('Su', 'su'),
  temperature('Sıcaklık', 'sıcaklık');

  const PlantFactor(this.label, this.lowerLabel);

  /// Cümle başında ya da başlıkta kullanılan ad.
  final String label;

  /// Cümle ortasında kullanılan ad. Dart'ın `toLowerCase()`'i Türkçe
  /// büyük/küçük harf kuralını (I → ı) bilmediği için ("Işık" → "işık"
  /// olurdu) küçük harfli hâl elle yazılır.
  final String lowerLabel;

  /// Kademe adları, 0'dan 2'ye.
  List<String> get levelLabels => switch (this) {
    PlantFactor.light => const ['Karanlık', 'Gölge', 'Güneş'],
    PlantFactor.water => const ['Az', 'Orta', 'Çok'],
    PlantFactor.temperature => const ['Soğuk (5°)', 'Ilık (20°)', 'Sıcak (35°)'],
  };
}

/// Her etkenin kademe sayısı.
const int plantLevelCount = 3;

/// Bir saksının koşulları: ışık, su ve sıcaklık kademeleri (0-2).
class PlantConditions {
  const PlantConditions({
    required this.light,
    required this.water,
    required this.temperature,
  });

  final int light;
  final int water;
  final int temperature;

  int levelOf(PlantFactor factor) => switch (factor) {
    PlantFactor.light => light,
    PlantFactor.water => water,
    PlantFactor.temperature => temperature,
  };

  /// [factor]'ün kademesi değiştirilmiş yeni koşullar.
  PlantConditions withLevel(PlantFactor factor, int level) => PlantConditions(
    light: factor == PlantFactor.light ? level : light,
    water: factor == PlantFactor.water ? level : water,
    temperature: factor == PlantFactor.temperature ? level : temperature,
  );

  /// [other]'dan farklı olan etkenler ("adil deney" kontrolü için).
  List<PlantFactor> differingFactors(PlantConditions other) => [
    for (final factor in PlantFactor.values)
      if (levelOf(factor) != other.levelOf(factor)) factor,
  ];

  /// "Güneş · Orta · Ilık (20°)" gibi tek satırlık özet.
  String get summary => [
    for (final factor in PlantFactor.values)
      factor.levelLabels[levelOf(factor)],
  ].join(' · ');

  @override
  bool operator ==(Object other) =>
      other is PlantConditions &&
      other.light == light &&
      other.water == water &&
      other.temperature == temperature;

  @override
  int get hashCode => Object.hash(light, water, temperature);
}
