/// Newton'un prizması — saf model.
///
/// Beyaz ışık aslında renklerin karışımıdır. Cam her rengi biraz farklı
/// büker (kırılma indisi renge göre değişir): kırmızı en az, mor en çok. Bu
/// yüzden prizmadan çıkan ışık yelpaze gibi açılır. Newton iki deneyle bunu
/// kanıtladı: tek bir rengi (örn. kırmızı) ikinci bir prizmadan geçirdi, renk
/// değişmedi — prizma renk *üretmiyor*, ayırıyor; renkleri ters bir prizmayla
/// birleştirince yeniden beyaz ışık elde etti.
library;

import 'dart:math';

/// Prizmanın tepe açısı (derece).
const double prismApexDeg = 60;

class SpectrumColor {
  const SpectrumColor(this.id, this.name, this.hex, this.refractiveIndex);

  final String id;
  final String name;
  final int hex;

  /// Camın bu renk için kırılma indisi. Gerçek camda fark çok küçüktür
  /// (1,51-1,53); yelpaze ekranda görülsün diye biraz abartıldı.
  final double refractiveIndex;
}

/// Newton'un adlandırdığı yedi renk, en az bükülenden en çok bükülene.
const List<SpectrumColor> spectrumColors = [
  SpectrumColor('red', 'Kırmızı', 0xE53935, 1.500),
  SpectrumColor('orange', 'Turuncu', 0xFB8C00, 1.508),
  SpectrumColor('yellow', 'Sarı', 0xFDD835, 1.517),
  SpectrumColor('green', 'Yeşil', 0x43A047, 1.527),
  SpectrumColor('blue', 'Mavi', 0x1E88E5, 1.538),
  SpectrumColor('indigo', 'Lacivert', 0x3949AB, 1.549),
  SpectrumColor('violet', 'Mor', 0x8E24AA, 1.560),
];

SpectrumColor spectrumColorById(String id) =>
    spectrumColors.firstWhere((c) => c.id == id);

/// Prizmadan en küçük sapmayla geçen ışının toplam bükülme açısı (derece):
/// D = 2·asin(n·sin(A/2)) − A.
double deviationDeg(SpectrumColor c) {
  final a = prismApexDeg * pi / 180;
  return (2 * asin(c.refractiveIndex * sin(a / 2)) - a) * 180 / pi;
}

/// Lambanın önüne konan renkli camlar (süzgeç). Beyaz ışık tüm renkleri
/// taşır; süzgeç yalnızca bir rengi geçirir.
enum LightSource {
  white('Beyaz ışık', null),
  red('Kırmızı süzgeç', 'red'),
  green('Yeşil süzgeç', 'green'),
  blue('Mavi süzgeç', 'blue');

  const LightSource(this.label, this.onlyColorId);

  final String label;
  final String? onlyColorId;

  List<SpectrumColor> get colors => onlyColorId == null
      ? spectrumColors
      : [spectrumColorById(onlyColorId!)];
}

/// Ekrana düşen ışık. [recombined] true ise renkler ikinci (ters) prizmada
/// yeniden birleşmiş ve ekranda tek bir ışık lekesi var.
class PrismOutcome {
  const PrismOutcome(this.colors, {required this.recombined});

  final List<SpectrumColor> colors;
  final bool recombined;

  /// Ekranda görülen: birden çok renk birleşmediyse "gökkuşağı".
  bool get isRainbow => colors.length > 1 && !recombined;

  /// Tüm renkler birleşince beyaz görünür.
  bool get isWhite => colors.length == spectrumColors.length && recombined;

  /// Ters prizmadan çıkan (birleşmiş) ışığın rengi: tüm renkler varsa beyaz,
  /// tek renk varsa o renk — tek renk birleşince beyaza dönmez.
  int get recombinedHex =>
      colors.length == spectrumColors.length ? 0xFFFFFF : colors.first.hex;
}

PrismOutcome prismOutcome(LightSource source, {required bool secondPrism}) =>
    PrismOutcome(source.colors, recombined: secondPrism);
