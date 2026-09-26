import 'generator.dart';
import 'transmission.dart';
import 'wireless.dart';

enum TeslaStation {
  generator('Jeneratör'),
  transmission('Şehre Elektrik'),
  wireless('Tesla Bobini');

  const TeslaStation(this.label);
  final String label;
}

/// 3B ve 2B görünümlerin çizdiği **saf veri**. Jeneratör 3B'de sürekli
/// döner (zamanı görünüm tutar); 2B ve iç pencereler durağan bir dalga
/// resmi çizer (testlerde `pumpAndSettle` bitsin diye).
class TeslaScene {
  const TeslaScene({
    required this.station,
    this.source = PowerSource.generator,
    this.turnsPerSecond = 1,
    this.distanceKm = 10,
    this.secondaryTurns = 10,
    this.coilOn = false,
    this.transmitterKHz = 200,
    this.receiverKHz = 200,
    this.lampDistanceM = 1,
  });

  final TeslaStation station;

  // Jeneratör.
  final PowerSource source;
  final double turnsPerSecond;

  // Şehre elektrik.
  final double distanceKm;
  final int secondaryTurns;

  // Tesla bobini.
  final bool coilOn;
  final double transmitterKHz;
  final double receiverKHz;
  final double lampDistanceM;

  double get lineV => lineVolts(secondaryTurns);
  int get houses => housesLit(lineV, distanceKm);

  double get lampLevel => lampBrightness(
    coilOn: coilOn,
    transmitterKHz: transmitterKHz,
    receiverKHz: receiverKHz,
    distanceM: lampDistanceM,
  );
}
