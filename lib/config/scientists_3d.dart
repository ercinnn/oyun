import 'package:flutter/foundation.dart' show kIsWeb;

/// Bilim İnsanları oyunlarının **gerçek 3D görünümü** açık mı.
///
/// Renkli Kasaba'nın `townUse3d`'siyle aynı kural ve aynı `USE_3D` anahtarı:
/// varsayılan olarak yalnızca web'de açık; Android/masaüstünde
/// `--dart-define=USE_3D=true` ile açılır. VM testlerinde (WebGL yok) ve
/// anahtarsız derlemelerde 2B yedek görünüm kullanılır.
bool scientistsUse3d = kIsWeb || const bool.fromEnvironment('USE_3D');
