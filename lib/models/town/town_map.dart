/// Karo türleri.
enum TileKind {
  grass,
  road,
  sand,
  water,
  tree,
  fountain,
  lamp,
  building,
  door,
  mud,
  goal,
  start,
}

/// Kasabadaki kapıların türü (kapıya girince açılan ekran).
enum DoorKind {
  wardrobe('Giyim Dükkânı', '👗'),
  market('Market', '🛋️'),
  home('Evim', '🏠'),
  arcade('Oyun Salonu', '🎮');

  const DoorKind(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Haritada büyük harflerle işaretli bir bina ve kapısı.
class TownBuilding {
  const TownBuilding({
    required this.kind,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.doorX,
    required this.doorY,
  });

  final DoorKind kind;

  /// Tabanın sol-üst karosu ve boyutu (kare cinsinden).
  final int x;
  final int y;
  final int w;
  final int h;

  /// Kapı karosu (binanın hemen güneyinde).
  final int doorX;
  final int doorY;
}

/// ASCII satırlardan kurulan kare haritası (kasaba, parkur pisti).
///
/// Karakterler: `.` çimen, `,` yol, `_` kum, `~` su, `T` ağaç, `F` çeşme,
/// `L` lamba, `m` çamur (yavaşlatır), `S` başlangıç, `G` bayrak (parkur
/// hedefi), `A B C E` bina tabanları (giyim, market, ev, oyun salonu) ve
/// küçük harfli `a b c e` o binaların kapı karoları.
class TownMap {
  TownMap._(
    this.width,
    this.height,
    this._tiles,
    this.buildings,
    this.startX,
    this.startY,
    this.goalX,
    this.goalY,
    this.waterIsHazard,
  );

  /// Satırları ayrıştırır. [waterIsHazard] true ise su geçilmez değil
  /// **tehlikelidir** (parkur: düşersen başa dönersin); false ise duvar gibidir.
  factory TownMap.parse(List<String> rows, {bool waterIsHazard = false}) {
    final height = rows.length;
    final width = rows.first.length;
    final tiles = List<TileKind>.filled(width * height, TileKind.grass);
    final rects = <String, List<int>>{}; // harf → [minX, minY, maxX, maxY]
    final doors = <String, List<int>>{}; // küçük harf → [x, y]
    var startX = 1.5;
    var startY = 1.5;
    var goalX = -1;
    var goalY = -1;

    for (var y = 0; y < height; y++) {
      assert(rows[y].length == width, 'Harita satırları aynı uzunlukta olmalı');
      for (var x = 0; x < width; x++) {
        final c = rows[y][x];
        final index = y * width + x;
        switch (c) {
          case 'T':
            tiles[index] = TileKind.tree;
          case ',':
            tiles[index] = TileKind.road;
          case '_':
            tiles[index] = TileKind.sand;
          case '~':
            tiles[index] = TileKind.water;
          case 'F':
            tiles[index] = TileKind.fountain;
          case 'L':
            tiles[index] = TileKind.lamp;
          case 'm':
            tiles[index] = TileKind.mud;
          case 'S':
            tiles[index] = TileKind.start;
            startX = x + 0.5;
            startY = y + 0.5;
          case 'G':
            tiles[index] = TileKind.goal;
            goalX = x;
            goalY = y;
          case 'A' || 'B' || 'C' || 'E':
            tiles[index] = TileKind.building;
            final rect = rects.putIfAbsent(c, () => [x, y, x, y]);
            if (x < rect[0]) rect[0] = x;
            if (y < rect[1]) rect[1] = y;
            if (x > rect[2]) rect[2] = x;
            if (y > rect[3]) rect[3] = y;
          case 'a' || 'b' || 'c' || 'e':
            tiles[index] = TileKind.door;
            doors[c.toUpperCase()] = [x, y];
          default:
            tiles[index] = TileKind.grass;
        }
      }
    }

    const kinds = {
      'A': DoorKind.wardrobe,
      'B': DoorKind.market,
      'C': DoorKind.home,
      'E': DoorKind.arcade,
    };
    final buildings = <TownBuilding>[];
    rects.forEach((letter, rect) {
      final door = doors[letter];
      buildings.add(
        TownBuilding(
          kind: kinds[letter]!,
          x: rect[0],
          y: rect[1],
          w: rect[2] - rect[0] + 1,
          h: rect[3] - rect[1] + 1,
          doorX: door?[0] ?? rect[0],
          doorY: door?[1] ?? rect[3] + 1,
        ),
      );
    });

    return TownMap._(
      width,
      height,
      tiles,
      buildings,
      startX,
      startY,
      goalX,
      goalY,
      waterIsHazard,
    );
  }

  final int width;
  final int height;
  final List<TileKind> _tiles;
  final List<TownBuilding> buildings;
  final double startX;
  final double startY;

  /// Bayrak karosu; yoksa -1.
  final int goalX;
  final int goalY;
  final bool waterIsHazard;

  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < width && y < height;

  TileKind kindAt(int x, int y) =>
      inBounds(x, y) ? _tiles[y * width + x] : TileKind.tree;

  /// Karakterin giremediği kare mi (ağaç, çeşme, lamba, bina, sınır dışı ve
  /// tehlikeli olmayan su).
  bool isBlocked(int x, int y) {
    switch (kindAt(x, y)) {
      case TileKind.tree:
      case TileKind.fountain:
      case TileKind.lamp:
      case TileKind.building:
        return true;
      case TileKind.water:
        return !waterIsHazard;
      default:
        return false;
    }
  }

  /// Girilebilir ama tehlikeli kare (parkurda su): düşersen başa dönersin.
  bool isHazard(int x, int y) =>
      waterIsHazard && kindAt(x, y) == TileKind.water;

  /// Yürüme hızı çarpanı (çamur yavaşlatır).
  double speedFactorAt(int x, int y) =>
      kindAt(x, y) == TileKind.mud ? 0.5 : 1.0;

  /// Yol bulmada ve rastgele hedef seçiminde kullanılan güvenli kare.
  bool isWalkable(int x, int y) => !isBlocked(x, y) && !isHazard(x, y);
}
