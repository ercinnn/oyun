import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'avatar_spec.dart';
import 'iso_projection.dart';
import 'town_map.dart';

/// Karakterin baktığı yön (ekranda). Yüzü kameraya dönük olan [se] ve [sw]'dir.
enum Facing { se, sw, ne, nw }

/// Ekran uzayındaki hareket girdisi: joystick, ok tuşları ya da sıfır.
/// Birim çember içindedir (uzunluğu 1'i geçmez).
class WorldInput {
  const WorldInput(this.dx, this.dy);

  static const none = WorldInput(0, 0);

  final double dx;
  final double dy;

  bool get isZero => dx == 0 && dy == 0;
}

/// Toplanabilir altın ya da yıldız.
class WorldCoin {
  WorldCoin({
    required this.x,
    required this.y,
    required this.value,
    required this.isStar,
  });

  final double x;
  final double y;

  /// Toplayınca kazanılan altın.
  final int value;
  final bool isStar;

  /// Toplandıysa yeniden doğacağı dünya zamanı; null ise sahnede.
  double? respawnAt;

  bool get active => respawnAt == null;
}

/// Gezen yardımcı karakter (NPC). Yalnızca süs: rastgele yürür, durur, döner.
class WorldNpc {
  WorldNpc({
    required this.x,
    required this.y,
    required this.avatar,
  }) : targetX = x,
       targetY = y;

  double x;
  double y;
  double targetX;
  double targetY;
  double pauseLeft = 0;
  Facing facing = Facing.se;
  bool moving = false;
  final AvatarSpec avatar;
}

/// Sahneye eklenen ekstra nesne (parkurda varil, hazine avında sandık,
/// parkurda bayrak). Çizimi `IsoWorldPainter` yapar.
class WorldProp {
  WorldProp({required this.kind, required this.x, required this.y, this.data = 0});

  final String kind;
  double x;
  double y;

  /// Türe özel değer (sandığın bulunmuş olması gibi).
  double data;
}

/// Kare tabanlı dünya simülasyonu: karakter hareketi, çarpışma, yol bulma,
/// altın toplama, NPC'ler. **Saf ve deterministiktir**: widget zamanı
/// kullanmaz, `step(dt)` ile sabit adımlarla ilerler; rastgelelik yalnızca
/// enjekte edilen [random]'dan gelir. Bu yüzden birim testlenebilir.
class TownWorld {
  TownWorld({
    required this.map,
    required this.random,
    double? startX,
    double? startY,
    List<(int, int)> coinSpots = const [],
    int npcCount = 0,
    int starEvery = 6,
    this.coinRespawnSeconds = 25,
    this.starRespawnSeconds = 25,
  }) : x = startX ?? map.startX,
       y = startY ?? map.startY,
       spawnX = startX ?? map.startX,
       spawnY = startY ?? map.startY {
    for (var i = 0; i < coinSpots.length; i++) {
      final isStar = starEvery > 0 && i % starEvery == starEvery - 1;
      coins.add(
        WorldCoin(
          x: coinSpots[i].$1 + 0.5,
          y: coinSpots[i].$2 + 0.5,
          value: isStar ? 5 : 1,
          isStar: isStar,
        ),
      );
    }
    for (var i = 0; i < npcCount; i++) {
      final spot = _randomWalkable(near: null);
      npcs.add(
        WorldNpc(x: spot.dx, y: spot.dy, avatar: _npcAvatar(i)),
      );
    }
  }

  final TownMap map;
  final Random random;

  /// Karakter hızı (kare/saniye) ve çarpışma yarıçapı (kare).
  static const double speed = 3.4;
  static const double radius = 0.28;
  static const double npcSpeed = 1.3;

  /// Bir adımda simüle edilen en uzun süre (saniye); sekme arka plandan
  /// dönünce dev bir `dt` gelirse karakter duvarlardan geçmesin diye kırpılır.
  static const double maxStep = 0.05;

  final double coinRespawnSeconds;
  final double starRespawnSeconds;

  double x;
  double y;
  final double spawnX;
  final double spawnY;

  Facing facing = Facing.se;
  bool moving = false;

  /// Simülasyon süresi (saniye).
  double time = 0;

  final List<WorldCoin> coins = [];
  final List<WorldNpc> npcs = [];
  final List<WorldProp> props = [];

  /// Toplanan altın/yıldız sayaçları (kümülatif) ve henüz alınmamış altın.
  int coinsCollectedTotal = 0;
  int starsCollectedTotal = 0;
  int _pendingValue = 0;

  List<Offset> _path = [];

  /// Yürüme yolu var mı (dokun-yürü).
  bool get hasPath => _path.isNotEmpty;

  /// Toplanan altın değerini verir ve sıfırlar.
  int takeCollectedValue() {
    final value = _pendingValue;
    _pendingValue = 0;
    return value;
  }

  /// Karakteri [px], [py]'ye ışınlar ve yolu iptal eder.
  void teleport(double px, double py) {
    x = px;
    y = py;
    _path = [];
  }

  /// [dt] saniye ilerlet. Uzun [dt]'ler [maxStep] parçalarına bölünür.
  void step(double dt, WorldInput input) {
    var left = dt;
    while (left > 0) {
      final slice = min(left, maxStep);
      _stepOnce(slice, input);
      left -= slice;
    }
  }

  void _stepOnce(double dt, WorldInput input) {
    time += dt;

    var dirX = 0.0;
    var dirY = 0.0;
    if (!input.isZero) {
      _path = [];
      final dir = IsoProjection.screenDirToTile(input.dx, input.dy);
      // Girdinin şiddeti (joystick yarı eğik) hızı ölçeklesin, 1'i geçmesin.
      final strength = min(1.0, sqrt(input.dx * input.dx + input.dy * input.dy));
      dirX = dir.dx * strength;
      dirY = dir.dy * strength;
    } else if (_path.isNotEmpty) {
      final target = _path.first;
      final dx = target.dx - x;
      final dy = target.dy - y;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance < 0.12) {
        _path.removeAt(0);
      } else {
        dirX = dx / distance;
        dirY = dy / distance;
      }
    }

    moving = dirX != 0 || dirY != 0;
    if (moving) {
      final factor = speed * map.speedFactorAt(x.floor(), y.floor());
      final nx = x + dirX * factor * dt;
      final ny = y + dirY * factor * dt;
      final beforeX = x;
      final beforeY = y;
      // Eksenlere ayrı dene: duvara sürtünerek kay.
      if (canStand(nx, y)) x = nx;
      if (canStand(x, ny)) y = ny;
      if (x == beforeX && y == beforeY) {
        _path = []; // sıkıştı, yolu bırak
        moving = false;
      } else {
        facing = _facingOf(dirX, dirY);
      }
    }

    _collect();
    _stepNpcs(dt);
  }

  /// Bir karenin yönünü (kare uzayı) ekrandaki yöne çevirir.
  static Facing _facingOf(double tileDx, double tileDy) {
    final screen = IsoProjection.toScreen(tileDx, tileDy);
    final right = screen.dx >= 0;
    final down = screen.dy >= 0;
    if (down) return right ? Facing.se : Facing.sw;
    return right ? Facing.ne : Facing.nw;
  }

  /// Karakter [px], [py] noktasında durabilir mi (4 köşe kontrolü).
  bool canStand(double px, double py) {
    for (final corner in const [
      Offset(-radius, -radius),
      Offset(radius, -radius),
      Offset(-radius, radius),
      Offset(radius, radius),
    ]) {
      if (map.isBlocked((px + corner.dx).floor(), (py + corner.dy).floor())) {
        return false;
      }
    }
    return true;
  }

  void _collect() {
    for (final coin in coins) {
      if (!coin.active) {
        if (time >= coin.respawnAt!) coin.respawnAt = null;
        continue;
      }
      final dx = coin.x - x;
      final dy = coin.y - y;
      if (dx * dx + dy * dy < 0.55 * 0.55) {
        _pendingValue += coin.value;
        coinsCollectedTotal++;
        if (coin.isStar) starsCollectedTotal++;
        coin.respawnAt =
            time + (coin.isStar ? starRespawnSeconds : coinRespawnSeconds);
      }
    }
  }

  // ─────────────────────────── Yol bulma ───────────────────────────

  /// [tx], [ty] karosuna yürümek için yol bulur (4 yönlü BFS). Ulaşılamıyorsa
  /// hiçbir şey yapmaz ve false döner.
  bool walkTo(int tx, int ty) {
    final path = findPath(x.floor(), y.floor(), tx, ty);
    if (path == null) return false;
    _path = [for (final cell in path) Offset(cell.$1 + 0.5, cell.$2 + 0.5)];
    return true;
  }

  /// Başlangıç karosu hariç, hedef karo dahil kare listesi; yol yoksa null.
  List<(int, int)>? findPath(int sx, int sy, int tx, int ty) {
    if (!map.isWalkable(tx, ty)) return null;
    if (sx == tx && sy == ty) return const [];
    final cameFrom = <int, int>{};
    final queue = Queue<int>()..add(sy * map.width + sx);
    cameFrom[sy * map.width + sx] = -1;
    const steps = [(1, 0), (-1, 0), (0, 1), (0, -1)];

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final cx = current % map.width;
      final cy = current ~/ map.width;
      if (cx == tx && cy == ty) {
        final result = <(int, int)>[];
        var walker = current;
        while (walker != -1 && walker != sy * map.width + sx) {
          result.add((walker % map.width, walker ~/ map.width));
          walker = cameFrom[walker]!;
        }
        return result.reversed.toList();
      }
      for (final (dx, dy) in steps) {
        final nx = cx + dx;
        final ny = cy + dy;
        if (!map.inBounds(nx, ny) || !map.isWalkable(nx, ny)) continue;
        final index = ny * map.width + nx;
        if (cameFrom.containsKey(index)) continue;
        cameFrom[index] = current;
        queue.add(index);
      }
    }
    return null;
  }

  // ─────────────────────────── Kapılar ───────────────────────────

  /// Karakterin yanındaki (0,9 kare içindeki) bina kapısı; yoksa null.
  TownBuilding? get nearbyDoor {
    for (final building in map.buildings) {
      final dx = building.doorX + 0.5 - x;
      final dy = building.doorY + 0.5 - y;
      if (dx * dx + dy * dy < 0.9 * 0.9) return building;
    }
    return null;
  }

  // ─────────────────────────── NPC'ler ───────────────────────────

  void _stepNpcs(double dt) {
    for (final npc in npcs) {
      if (npc.pauseLeft > 0) {
        npc.pauseLeft -= dt;
        npc.moving = false;
        continue;
      }
      final dx = npc.targetX - npc.x;
      final dy = npc.targetY - npc.y;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance < 0.1) {
        npc.pauseLeft = 0.5 + random.nextDouble() * 2.5;
        final next = _randomWalkable(near: Offset(npc.x, npc.y));
        npc.targetX = next.dx;
        npc.targetY = next.dy;
        npc.moving = false;
        continue;
      }
      final stepX = dx / distance * npcSpeed * dt;
      final stepY = dy / distance * npcSpeed * dt;
      final nx = npc.x + stepX;
      final ny = npc.y + stepY;
      if (canStand(nx, ny)) {
        npc.x = nx;
        npc.y = ny;
        npc.moving = true;
        npc.facing = _facingOf(stepX, stepY);
      } else {
        // Engele çarptı: yeni hedef seç.
        final next = _randomWalkable(near: Offset(npc.x, npc.y));
        npc.targetX = next.dx;
        npc.targetY = next.dy;
        npc.moving = false;
      }
    }
  }

  /// Yürünebilir rastgele bir karo merkezi; [near] verilirse 5 kare içinde
  /// aranır. Bulunamazsa başlangıç noktası döner.
  Offset _randomWalkable({Offset? near}) {
    for (var attempt = 0; attempt < 30; attempt++) {
      final int tx;
      final int ty;
      if (near == null) {
        tx = 1 + random.nextInt(max(1, map.width - 2));
        ty = 1 + random.nextInt(max(1, map.height - 2));
      } else {
        tx = (near.dx + random.nextInt(11) - 5).floor();
        ty = (near.dy + random.nextInt(11) - 5).floor();
      }
      if (map.inBounds(tx, ty) && map.isWalkable(tx, ty)) {
        return Offset(tx + 0.5, ty + 0.5);
      }
    }
    return Offset(spawnX, spawnY);
  }

  static AvatarSpec _npcAvatar(int index) => AvatarSpec(
    skin: (index * 2 + 1) % skinPalette.length,
    hairStyle: const ['hair_long', 'hair_spiky', 'hair_bun', 'hair_curly'][index % 4],
    hairColor: (index * 3) % hairPalette.length,
    outfit: const ['outfit_hoodie', 'outfit_dress', 'outfit_tee', 'outfit_suit'][index % 4],
    outfitColor: (index * 2 + 1) % outfitPalette.length,
    hat: index % 3 == 0 ? 'hat_cap' : 'hat_none',
  );
}
