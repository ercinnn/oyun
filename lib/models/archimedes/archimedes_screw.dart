/// Arşimet vidası: eğik bir borunun içinde dönen sarmal. Her turda sarmalın
/// alt ağzına giren su, bir "cep"te tutularak yukarı taşınır.
///
/// Model iki basit kuralla çalışır:
/// 1. **Vida tarlaya yetişmeli**: vidanın boyu sabittir, çok yatık kurulursa
///    üst ucu tarlanın yüksekliğine çıkamaz, su tarlaya dökülmez.
/// 2. **Çok dik olursa su geri kayar**: vida dikleştikçe ceplere daha az su
///    sığar; [screwSpillAngle] derecede ceplerde hiç su kalmaz.
/// Bu yüzden en iyi açı, tarlaya yetişen **en yatık** açıdır.
library;

import 'dart:math';

const double screwLengthM = 3.0;
const double fieldHeightM = 1.2;

/// Bu açıda ve üstünde ceplerde su kalmaz.
const double screwSpillAngle = 60;

/// Cebin düz (yatık) vidada taşıdığı su (litre / tur).
const double screwLitresPerTurnFlat = 2.0;

/// Tarlanın sulanması için gereken su (litre).
const double fieldNeedLitres = 20;

/// Kaydırıcının sınırları (derece).
const double screwMinAngle = 15;
const double screwMaxAngle = 75;

/// Vidanın üst ucunun yerden yüksekliği (m).
double screwTopHeightM(double angleDeg) =>
    screwLengthM * sin(angleDeg * pi / 180);

bool screwReachesField(double angleDeg) =>
    screwTopHeightM(angleDeg) >= fieldHeightM;

/// 0-1: ceplerin ne kadar dolu kalabildiği.
double screwPocketFill(double angleDeg) =>
    ((screwSpillAngle - angleDeg) / 40).clamp(0.0, 1.0);

/// Bir turda tarlaya dökülen su (litre).
double screwLitresPerTurn(double angleDeg) => screwReachesField(angleDeg)
    ? screwLitresPerTurnFlat * screwPocketFill(angleDeg)
    : 0;

/// Tarlayı sulamak için gereken tur sayısı; hiç su çıkmıyorsa null.
int? screwTurnsToFill(double angleDeg) {
  final perTurn = screwLitresPerTurn(angleDeg);
  if (perTurn <= 0) return null;
  return (fieldNeedLitres / perTurn).ceil();
}

/// Açının neden iyi ya da kötü olduğunu anlatan, elle yazılmış cümle.
String screwVerdict(double angleDeg) {
  if (!screwReachesField(angleDeg)) {
    return 'Vida çok yatık: üst ucu tarlanın yüksekliğine yetişmiyor, su '
        'tarlaya dökülemiyor.';
  }
  if (screwPocketFill(angleDeg) <= 0) {
    return 'Vida çok dik: su ceplerde duramıyor, aşağı geri kayıyor.';
  }
  if (screwPocketFill(angleDeg) < 0.5) {
    return 'Vida biraz dik: ceplerin yarısından azı dolu kalıyor.';
  }
  return 'Güzel açı: vida tarlaya yetişiyor ve ceplerdeki su dökülmüyor.';
}
