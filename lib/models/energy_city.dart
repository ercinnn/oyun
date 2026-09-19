/// Elektrik üretim kaynakları.
enum EnergySource {
  solar('Güneş enerjisi', '☀️', true),
  wind('Rüzgâr enerjisi', '🌬️', true),
  hydro('Su (baraj) enerjisi', '💧', true),
  coal('Kömür', '🪨', false),
  gas('Doğalgaz', '🔥', false);

  const EnergySource(this.name, this.emoji, this.clean);

  final String name;
  final String emoji;

  /// Havayı kirletmeyen (temiz) kaynak mı.
  final bool clean;

  /// Kaynağı anlatan elle yazılmış cümle.
  String get note => switch (this) {
    EnergySource.solar =>
      'Güneş panelleri güneş ışığından elektrik üretir; güneş yoksa üretim düşer.',
    EnergySource.wind =>
      'Rüzgâr türbinleri rüzgârla döner; rüzgâr güçlendikçe daha çok elektrik üretir.',
    EnergySource.hydro =>
      'Barajlarda akan su türbinleri çevirir; yağmurla su çoğalınca üretim artar.',
    EnergySource.coal =>
      'Kömür her havada yakılabilir ama havayı kirletir ve bir gün biter.',
    EnergySource.gas =>
      'Doğalgaz her havada yakılabilir ama havayı kirletir ve bir gün biter.',
  };
}

/// Hava durumu.
enum EnergyWeather {
  sunny('Güneşli hava', '☀️'),
  cloudy('Bulutlu hava', '☁️'),
  windy('Rüzgârlı hava', '🌬️'),
  rainy('Yağmurlu hava', '🌧️'),
  night('Gece', '🌙');

  const EnergyWeather(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// [source]'un [weather] altındaki üretimi (birim). Kömür ve doğalgaz hava
/// durumundan etkilenmez; temiz kaynaklar etkilenir.
int energyOutput(EnergySource source, EnergyWeather weather) {
  const table = <EnergySource, List<int>>{
    //                 güneşli, bulutlu, rüzgârlı, yağmurlu, gece
    EnergySource.solar: [90, 40, 30, 15, 0],
    EnergySource.wind: [20, 30, 95, 55, 35],
    EnergySource.hydro: [50, 50, 50, 85, 50],
    EnergySource.coal: [60, 60, 60, 60, 60],
    EnergySource.gas: [55, 55, 55, 55, 55],
  };
  return table[source]![weather.index];
}
