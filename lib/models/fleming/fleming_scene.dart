import 'hygiene.dart';
import 'petri.dart';
import 'resistance.dart';

enum FlemingStation {
  petri('Petri Kabı'),
  hygiene('Temizlik'),
  medicine('Doğru İlaç');

  const FlemingStation(this.label);
  final String label;
}

/// 3B ve 2B görünümlerin çizdiği **saf veri**. Günler görünümde yumuşakça
/// ilerler (koloniler büyür, halka genişler, bakteri sayısı değişir).
class FlemingScene {
  const FlemingScene({
    required this.station,
    this.mold = true,
    this.day = 0,
    this.lidOpen = false,
    this.hand = HandTouch.none,
    this.incubated = false,
    this.treatmentDays = fullCourseDays,
    this.medicineDay = 0,
  });

  final FlemingStation station;

  /// Soldaki kapta küf var mı (sağdaki hep kontrol kabıdır, küfsüz).
  final bool mold;
  final double day;

  final bool lidOpen;
  final HandTouch hand;

  /// 3 gün bekletildi mi (koloniler görünür).
  final bool incubated;

  final int treatmentDays;

  /// Gösterilen gün (0-[observedDays]).
  final double medicineDay;

  int get livingWithMold => livingColonies(day, mold: mold);
  int get livingControl => livingColonies(day, mold: false);

  int get hygieneCount => incubated
      ? hygieneColonies(lidOpen: lidOpen, hand: hand)
      : 0;

  List<Population> get course => simulateTreatment(treatmentDays);
}
