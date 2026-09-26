import 'dart:math';

import 'jupiter.dart';
import 'solar.dart';
import 'telescope.dart';

enum GalileoStation {
  telescope('Teleskop'),
  jupiter('Jüpiter\'in Uyduları'),
  solar('Güneş Sistemi');

  const GalileoStation(this.label);
  final String label;
}

/// 3B ve 2B görünümlerin çizdiği **saf veri**. Görünüm bu değerlere doğru
/// yumuşakça ilerler (tüp kayar, geceler/günler akar); mantık animasyon
/// beklemez.
class GalileoScene {
  const GalileoScene({
    required this.station,
    this.target = SkyTarget.jupiter,
    this.objectiveCm = 90,
    this.eyepieceCm = 5,
    this.tubeCm = 85,
    this.nights = 0,
    this.highlightMoonId,
    this.day = 0,
    this.venusOffsetDeg,
    this.highlightPlanetIds = const [],
    this.showVenusView = true,
  });

  final GalileoStation station;

  // Teleskop.
  final SkyTarget target;
  final double objectiveCm;
  final double eyepieceCm;
  final double tubeCm;

  // Jüpiter.
  final double nights;
  final String? highlightMoonId;

  // Güneş sistemi.
  final double day;

  /// Verilirse Venüs, Dünya'nın açısına göre bu kadar ileride durur (evre
  /// soruları için); yoksa [day]'deki gerçek konumundadır.
  final double? venusOffsetDeg;
  final List<String> highlightPlanetIds;

  /// Dünya'dan görünen Venüs kutusu (evre sorusunda cevaptan önce gizli).
  final bool showVenusView;

  double get magnificationValue => magnification(objectiveCm, eyepieceCm);
  double get focusError => focusErrorCm(objectiveCm, eyepieceCm, tubeCm);

  /// Venüs'ün açısı (radyan) — [venusOffsetDeg] varsa ona göre.
  double venusAngleAt(double shownDay) {
    final offset = venusOffsetDeg;
    if (offset == null) return planetById('venus').angleAt(shownDay);
    return planetById('earth').angleAt(shownDay) + offset * pi / 180;
  }

  VenusView venusViewAt(double shownDay) => venusFromEarth(
    planetById('earth').angleAt(shownDay),
    venusAngleAt(shownDay),
  );

  JupiterMoon? get highlightMoon =>
      highlightMoonId == null ? null : jupiterMoonById(highlightMoonId!);
}
