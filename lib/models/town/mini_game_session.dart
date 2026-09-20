import 'dart:math';

import '../../data/town_map_data.dart';
import 'town_map.dart';
import 'town_world.dart';

/// Kasabadaki mini oyunlar.
enum MiniGameKind {
  parkour('Engelli Parkur', '🏃', 'Su ve varillerden kaçarak bayrağa ulaş! Çamur seni yavaşlatır.'),
  treasure('Hazine Avı', '🗺️', 'Kasabada 3 sandık saklı. Sıcak-soğuk ipucunu izleyip hepsini bul!'),
  stars('Yıldız Yağmuru', '⭐', 'Süre bitmeden olabildiğince çok yıldız topla!');

  const MiniGameKind(this.title, this.emoji, this.description);

  final String title;
  final String emoji;
  final String description;
}

/// Bir mini oyun turu. Kendi [world]'ünü ve süresini taşır; `step(dt)` dünyayı
/// ilerletir, kuralları işletir. Saf ve deterministiktir (rastgelelik yalnızca
/// enjekte edilen [Random]'dan), bu yüzden birim testlenebilir.
abstract class MiniGameSession {
  MiniGameSession(this.kind, this.world, this.duration) : timeLeft = duration;

  final MiniGameKind kind;
  final TownWorld world;
  final double duration;

  double timeLeft;
  bool finished = false;

  /// Kazanılan puan (oyun bitince kesinleşir; süre içinde canlı olabilir).
  int score = 0;

  /// Ekranda gösterilen kısa durum/ipucu metni.
  String get statusText;

  /// Oyun bitince kazanılan oyun içi altın (serbest modda cüzdana eklenir).
  int get rewardCoins => score ~/ 5;

  /// Kurallara özgü adım (dünya ilerledikten sonra).
  void onStep(double dt);

  void step(double dt, WorldInput input) {
    if (finished) return;
    world.step(dt, input);
    timeLeft -= dt;
    onStep(dt);
    if (timeLeft <= 0) {
      timeLeft = 0;
      finish();
    }
  }

  /// Oyunu bitirir; alt sınıflar puanı kesinleştirir.
  void finish() {
    if (finished) return;
    finished = true;
    onFinish();
  }

  void onFinish();

  /// [kind] için taze bir oturum kurar.
  static MiniGameSession create(MiniGameKind kind, Random random) =>
      switch (kind) {
        MiniGameKind.parkour => ParkourSession(),
        MiniGameKind.treasure => TreasureSession(random),
        MiniGameKind.stars => StarRushSession(random),
      };
}

/// Engelli parkur: su karesi ya da varil değerse başa dönersin; bayrağa
/// ulaşınca oyun biter. Puan = 100 + kalan süre × 3 − çarpma × 5 (en az 20);
/// süre bitip bayrağa ulaşılmadıysa 0.
class ParkourSession extends MiniGameSession {
  ParkourSession()
    : super(
        MiniGameKind.parkour,
        TownWorld(map: buildParkourMap(), random: Random(1)),
        60,
      ) {
    for (final barrel in barrels) {
      world.props.add(WorldProp(kind: 'barrel', x: barrel.x, y: barrel.yAt(0)));
    }
  }

  /// Koridoru dikine geçen varillerin tanımı (sabit, deterministik desen).
  static const List<Barrel> barrels = [
    Barrel(x: 4.5, y0: 2.5, y1: 4.5, period: 2.4, phase: 0),
    Barrel(x: 8.5, y0: 2.5, y1: 4.5, period: 2.0, phase: 0.5),
    Barrel(x: 11.5, y0: 2.5, y1: 4.5, period: 1.6, phase: 0.25),
  ];

  /// Varile veya suya çarpma sayısı.
  int hits = 0;
  bool reachedGoal = false;

  @override
  String get statusText => 'Çarpma: $hits';

  @override
  void onStep(double dt) {
    for (var i = 0; i < barrels.length; i++) {
      final barrel = barrels[i];
      final y = barrel.yAt(world.time);
      world.props[i]
        ..x = barrel.x
        ..y = y;
      final dx = barrel.x - world.x;
      final dy = y - world.y;
      if (dx * dx + dy * dy < 0.5 * 0.5) {
        _respawn();
        return;
      }
    }
    if (world.map.isHazard(world.x.floor(), world.y.floor())) {
      _respawn();
      return;
    }
    if (world.x.floor() == world.map.goalX && world.y.floor() == world.map.goalY) {
      reachedGoal = true;
      finish();
    }
  }

  void _respawn() {
    hits++;
    world.teleport(world.spawnX, world.spawnY);
  }

  @override
  void onFinish() {
    score = reachedGoal ? max(20, 100 + (timeLeft * 3).round() - hits * 5) : 0;
  }
}

/// Varil: [x] sütununda [y0]-[y1] arasında gidip gelir; [period] saniyede bir
/// tam tur, [phase] (0-1) başlangıç kaydırması.
class Barrel {
  const Barrel({
    required this.x,
    required this.y0,
    required this.y1,
    required this.period,
    required this.phase,
  });

  final double x;
  final double y0;
  final double y1;
  final double period;
  final double phase;

  /// [time] anındaki y konumu (üçgen dalga: gidip gelir).
  double yAt(double time) {
    final u = ((time / period) + phase) % 1.0;
    final tri = u < 0.5 ? u * 2 : (1 - u) * 2;
    return y0 + (y1 - y0) * tri;
  }
}

/// Hazine avı: kasabada 3 gizli sandık; yaklaşınca açılır. Hepsi bulunursa
/// puan = 300 + kalan süre × 2; süre bitince bulunan × 100.
class TreasureSession extends MiniGameSession {
  TreasureSession(Random random)
    : super(
        MiniGameKind.treasure,
        TownWorld(
          map: buildTownMap(),
          random: random,
          startX: townStartX,
          startY: townStartY,
        ),
        90,
      ) {
    _placeChests(random);
  }

  static const int chestCount = 3;

  int found = 0;

  /// Sandıklar arasında ve başlangıçtan en az bu kadar uzaklık (kare).
  static const double _minSeparation = 6;

  void _placeChests(Random random) {
    final candidates = <(int, int)>[
      for (var y = 1; y < world.map.height - 1; y++)
        for (var x = 1; x < world.map.width - 1; x++)
          if (world.map.isWalkable(x, y) &&
              world.map.kindAt(x, y) != TileKind.door)
            (x, y),
    ]..shuffle(random);

    final chosen = <(int, int)>[];
    for (final c in candidates) {
      if (chosen.length == chestCount) break;
      bool far((int, int) a, double bx, double by) {
        final dx = a.$1 + 0.5 - bx;
        final dy = a.$2 + 0.5 - by;
        return dx * dx + dy * dy >= _minSeparation * _minSeparation;
      }

      final farFromStart = far(c, world.spawnX, world.spawnY);
      final farFromOthers = chosen.every((o) => far(c, o.$1 + 0.5, o.$2 + 0.5));
      if (farFromStart && farFromOthers) chosen.add(c);
    }
    // Aday bulunamazsa (çok küçük harita) uzaklık şartı olmadan doldur.
    for (final c in candidates) {
      if (chosen.length == chestCount) break;
      if (!chosen.contains(c)) chosen.add(c);
    }
    for (final c in chosen) {
      world.props.add(WorldProp(kind: 'chest', x: c.$1 + 0.5, y: c.$2 + 0.5));
    }
  }

  /// En yakın bulunmamış sandığa uzaklık (kare); hepsi bulunduysa 0.
  double get nearestDistance {
    var best = double.infinity;
    for (final prop in world.props) {
      if (prop.kind != 'chest' || prop.data == 1) continue;
      final dx = prop.x - world.x;
      final dy = prop.y - world.y;
      best = min(best, sqrt(dx * dx + dy * dy));
    }
    return best.isFinite ? best : 0;
  }

  /// Uzaklığa göre sıcak-soğuk ipucu.
  static String hintFor(double distance) {
    if (distance < 2) return 'Yanıyorsun! 🔥';
    if (distance < 5) return 'Sıcak ☀️';
    if (distance < 9) return 'Ilık 🌤️';
    return 'Soğuk ❄️';
  }

  @override
  String get statusText => 'Sandık: $found / $chestCount · ${hintFor(nearestDistance)}';

  @override
  void onStep(double dt) {
    for (final prop in world.props) {
      if (prop.kind != 'chest' || prop.data == 1) continue;
      final dx = prop.x - world.x;
      final dy = prop.y - world.y;
      if (dx * dx + dy * dy < 0.8 * 0.8) {
        prop.data = 1;
        found++;
      }
    }
    if (found >= chestCount) finish();
  }

  @override
  void onFinish() {
    score = found >= chestCount ? 300 + (timeLeft * 2).round() : found * 100;
  }
}

/// Yıldız yağmuru: 60 saniyede toplanan her yıldız 10 puan. Yıldızlar toplanınca
/// kısa sürede yeniden doğar.
class StarRushSession extends MiniGameSession {
  StarRushSession(Random random)
    : super(
        MiniGameKind.stars,
        TownWorld(
          map: buildTownMap(),
          random: random,
          startX: townStartX,
          startY: townStartY,
          coinSpots: townCoinSpots,
          starEvery: 1, // hepsi yıldız
          starRespawnSeconds: 3,
        ),
        60,
      );

  @override
  String get statusText => 'Yıldız: ${world.starsCollectedTotal}';

  @override
  void onStep(double dt) {
    score = world.starsCollectedTotal * 10;
  }

  @override
  void onFinish() {
    score = world.starsCollectedTotal * 10;
  }
}
