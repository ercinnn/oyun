import 'package:flutter/foundation.dart' show kIsWeb;

/// Renkli Kasaba'nın **gerçek 3D görünümleri** (kasaba: `Town3DView`, oda:
/// `Room3DView`) açık mı.
///
/// Varsayılan: **yalnızca web'de** açık (three_js orada doğrulandı). VM
/// testlerinde (WebGL yok) ve doğrulanmamış platformlarda 2B `IsoWorldView` /
/// `IsoRoomView`'e düşülür. Android/masaüstünde denemek için
/// `--dart-define=USE_3D=true` ile derle; doğrulanınca varsayılan genişletilir.
///
/// Tek bayrak, iki görünüm: kasaba 3B iken odanın 2B kalması (ya da tersi)
/// aynı oyun içinde görsel dili bölerdi.
bool townUse3d = kIsWeb || const bool.fromEnvironment('USE_3D');
