import 'electric_material.dart';

/// Ampullerin devreye bağlanışı.
enum LampLayout {
  series('Seri'),
  parallel('Paralel');

  const LampLayout(this.label);
  final String label;
}

const int maxBatteries = 3;
const int maxLamps = 3;

/// Basit bir pil-ampul devresinin tarifi. Devre tek bir halkadır: pil(ler),
/// anahtar, ampuller ve bir "boşluk" (boşlukta bir malzeme takılı olabilir).
class CircuitSpec {
  const CircuitSpec({
    this.batteries = 2,
    this.switchClosed = true,
    this.layout = LampLayout.series,
    this.lampCount = 1,
    this.material,
    this.burntLamp,
  });

  /// Pil sayısı (1-[maxBatteries]); her pil 1,5 V.
  final int batteries;
  final bool switchClosed;
  final LampLayout layout;

  /// Ampul sayısı (1-[maxLamps]).
  final int lampCount;

  /// Boşluğa takılı malzeme; null ise boşluk düz telle kapalıdır.
  final ElectricMaterial? material;

  /// Patlamış (yanık) ampulün indeksi; null ise hepsi sağlam.
  final int? burntLamp;

  CircuitSpec copyWith({
    int? batteries,
    bool? switchClosed,
    LampLayout? layout,
    int? lampCount,
    ElectricMaterial? material,
    bool clearMaterial = false,
    int? burntLamp,
    bool clearBurnt = false,
  }) {
    final newCount = lampCount ?? this.lampCount;
    var newBurnt = clearBurnt ? null : (burntLamp ?? this.burntLamp);
    if (newBurnt != null && newBurnt >= newCount) newBurnt = null;
    return CircuitSpec(
      batteries: batteries ?? this.batteries,
      switchClosed: switchClosed ?? this.switchClosed,
      layout: layout ?? this.layout,
      lampCount: newCount,
      material: clearMaterial ? null : (material ?? this.material),
      burntLamp: newBurnt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CircuitSpec &&
      other.batteries == batteries &&
      other.switchClosed == switchClosed &&
      other.layout == layout &&
      other.lampCount == lampCount &&
      other.material?.id == material?.id &&
      other.burntLamp == burntLamp;

  @override
  int get hashCode => Object.hash(
    batteries,
    switchClosed,
    layout,
    lampCount,
    material?.id,
    burntLamp,
  );
}
