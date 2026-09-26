/// Newton'un hareket yasaları — itilen araba, saf model.
///
/// Araba her seferinde **aynı yayla** itilir (aynı itme = aynı "impuls").
/// İlk hız = itme / kütle: yük eklendikçe araba daha yavaş başlar
/// (2. yasa: aynı kuvvet, daha büyük kütle → daha az hızlanma). Sonra
/// sürtünme onu yavaşlatır: buzda neredeyse hiç sürtünme olmadığı için araba
/// çok uzağa gider (1. yasa, eylemsizlik: bir şey durdurmazsa hareket sürer).
library;

import 'dart:math';

const double cartMassKg = 2;
const double boxMassKg = 2;
const int maxBoxes = 3;
const double _g = 9.8;

/// Pistin uzunluğu (m); daha uzağa giden araba sondaki tampona çarpar.
const double trackLengthM = 12;

enum CartSurface {
  ice('Buz', 0.03),
  wood('Tahta', 0.12),
  carpet('Halı', 0.35);

  const CartSurface(this.label, this.friction);

  final String label;

  /// Sürtünme katsayısı.
  final double friction;
}

enum PushStrength {
  soft('Hafif', 3),
  medium('Orta', 5),
  strong('Güçlü', 7);

  const PushStrength(this.label, this.impulse);

  final String label;

  /// Yayın verdiği itme (N·s).
  final double impulse;
}

class CartLane {
  const CartLane({this.boxes = 0, this.surface = CartSurface.wood});

  final int boxes;
  final CartSurface surface;

  double get massKg => cartMassKg + boxes * boxMassKg;

  CartLane copyWith({int? boxes, CartSurface? surface}) =>
      CartLane(boxes: boxes ?? this.boxes, surface: surface ?? this.surface);
}

/// Yaydan çıkış hızı (m/s).
double cartStartSpeed(CartLane lane, PushStrength push) =>
    push.impulse / lane.massKg;

/// Sürtünme olmasa (pist sonsuz olsa) gideceği yol (m).
double cartStopDistance(CartLane lane, PushStrength push) {
  final v = cartStartSpeed(lane, push);
  return v * v / (2 * lane.surface.friction * _g);
}

/// Pistte aldığı yol (m); pist sonundaki tampon sınırlar.
double cartDistance(CartLane lane, PushStrength push) =>
    min(cartStopDistance(lane, push), trackLengthM);

/// Durana (ya da tampona çarpana) kadar geçen süre (s).
double cartTravelTime(CartLane lane, PushStrength push) {
  final v = cartStartSpeed(lane, push);
  final a = lane.surface.friction * _g;
  final stop = v / a;
  if (cartStopDistance(lane, push) <= trackLengthM) return stop;
  // v·t − ½·a·t² = L denkleminin küçük kökü.
  return (v - sqrt(v * v - 2 * a * trackLengthM)) / a;
}

/// [t] saniyedeki konum (m).
double cartPositionAt(CartLane lane, PushStrength push, double t) {
  final v = cartStartSpeed(lane, push);
  final a = lane.surface.friction * _g;
  final tt = t.clamp(0.0, cartTravelTime(lane, push));
  return min(v * tt - 0.5 * a * tt * tt, trackLengthM);
}
