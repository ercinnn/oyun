import 'dart:math';

/// Kablo karosunun türü.
enum WireKind { empty, straight, corner, tee, battery, bulb }

/// Yön bitleri: kuzey, doğu, güney, batı.
const int _north = 1;
const int _east = 2;
const int _south = 4;
const int _west = 8;

/// Bir karonun 0 derecelik (dönmemiş) bağlantı maskesi.
int _baseMask(WireKind kind) => switch (kind) {
  WireKind.empty => 0,
  WireKind.straight => _north | _south,
  WireKind.corner => _north | _east,
  WireKind.tee => _north | _east | _south,
  WireKind.battery => _east,
  WireKind.bulb => _west,
};

/// Maskeyi saat yönünde bir çeyrek çevirir (K→D→G→B→K).
int _rotateMask(int mask) => ((mask << 1) & 15) | (mask >> 3);

int _maskWithRotation(WireKind kind, int rotation) {
  var mask = _baseMask(kind);
  for (var i = 0; i < rotation; i++) {
    mask = _rotateMask(mask);
  }
  return mask;
}

class WireTile {
  WireTile(this.kind, [this.rotation = 0]);

  final WireKind kind;

  /// Saat yönünde çeyrek tur sayısı (0-3).
  int rotation;

  int get mask => _maskWithRotation(kind, rotation);

  /// Pil ve ampul karoları sabittir; boş karo döndürülemez.
  bool get rotatable =>
      kind == WireKind.straight ||
      kind == WireKind.corner ||
      kind == WireKind.tee;
}

/// Kablo yolu bulmacası: pil (sol kenar) ile ampulü (sağ kenar) kablo
/// karolarını döndürerek birleştir.
///
/// Üretim "çözülmüş halden karıştır" tekniğiyle yapılır (Kayan Yapboz gibi):
/// önce pil ile ampul arasında kendini kesmeyen bir yol çizilir, yol
/// karoları o yolu kuracak biçimde yerleştirilir, sonra karıştırılır. Bu
/// yüzden her bulmaca çözülebilirdir.
class WirePuzzle {
  WirePuzzle._({
    required this.size,
    required this.tiles,
    required this.batteryIndex,
    required this.bulbIndex,
    required this.parMoves,
    required this.solutionMasks,
  });

  final int size;
  final List<WireTile> tiles;
  final int batteryIndex;
  final int bulbIndex;

  /// Yol karolarını çözmek için gereken en az hamle (yalnızca saat yönünde
  /// dokunulabildiği için çeyrek turlar tek yönlüdür).
  final int parMoves;

  /// Üretimde kurulan yolun karo başına bağlantı maskesi (karo indeksi →
  /// maske). Bir yol karosu bu maskeye ulaşınca yerindedir; testler ve ipucu
  /// için kullanılır.
  final Map<int, int> solutionMasks;

  /// Şu ana kadarki hamle sayısı.
  int moves = 0;

  int _index(int row, int col) => row * size + col;

  /// [index] karosuna dokun: saat yönünde 90° döner. Döndürülemeyen karoda
  /// hiçbir şey olmaz; true dönerse hamle sayıldı.
  bool rotate(int index) {
    final tile = tiles[index];
    if (!tile.rotatable) return false;
    tile.rotation = (tile.rotation + 1) % 4;
    moves++;
    return true;
  }

  /// Pilden akımın ulaştığı karolar.
  Set<int> get poweredCells {
    final visited = <int>{batteryIndex};
    final queue = <int>[batteryIndex];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      final row = current ~/ size;
      final col = current % size;
      final mask = tiles[current].mask;
      void visit(int bit, int nr, int nc, int oppositeBit) {
        if (mask & bit == 0) return;
        if (nr < 0 || nc < 0 || nr >= size || nc >= size) return;
        final next = _index(nr, nc);
        if (tiles[next].mask & oppositeBit == 0) return;
        if (visited.add(next)) queue.add(next);
      }

      visit(_north, row - 1, col, _south);
      visit(_east, row, col + 1, _west);
      visit(_south, row + 1, col, _north);
      visit(_west, row, col - 1, _east);
    }
    return visited;
  }

  /// Pil ile ampul birleşti mi.
  bool get solved => poweredCells.contains(bulbIndex);

  /// Verilen [size] için bir bulmaca üretir ([size] 3-5 arası önerilir).
  static WirePuzzle generate(int size, Random rng) {
    for (var attempt = 0; attempt < 100; attempt++) {
      final puzzle = _tryGenerate(size, rng);
      if (puzzle != null) return puzzle;
    }
    // Buraya gelinmemesi beklenir; yine de her zaman çözülebilir sabit bir
    // düz yol döndür.
    return _straightFallback(size);
  }

  static WirePuzzle? _tryGenerate(int size, Random rng) {
    final startRow = rng.nextInt(size);
    final endRow = rng.nextInt(size);
    // Yol iç sütunlarda (1..size-2): başlangıç (startRow,1), bitiş (endRow,size-2).
    final path = _randomPath(size, startRow, endRow, rng);
    if (path == null) return null;

    final tiles = List<WireTile>.generate(size * size, (_) => WireTile(WireKind.empty));
    final batteryIndex = startRow * size;
    final bulbIndex = endRow * size + size - 1;
    tiles[batteryIndex] = WireTile(WireKind.battery);
    tiles[bulbIndex] = WireTile(WireKind.bulb);

    // Yol karoları: önceki ve sonraki hücreye göre tür + çözülmüş dönüş.
    var parMoves = 0;
    final solutionMasks = <int, int>{};
    for (var i = 0; i < path.length; i++) {
      final cell = path[i];
      final prev = i == 0 ? batteryIndex : path[i - 1];
      final next = i == path.length - 1 ? bulbIndex : path[i + 1];
      final mask = _bit(cell, prev, size) | _bit(cell, next, size);
      final kind = (mask == (_north | _south) || mask == (_east | _west))
          ? WireKind.straight
          : WireKind.corner;
      // Bu maskeyi veren dönüşler (düz karoda iki tane olabilir).
      final rotations = [
        for (var r = 0; r < 4; r++)
          if (_maskWithRotation(kind, r) == mask) r,
      ];
      tiles[cell] = WireTile(kind, rotations.first);
      solutionMasks[cell] = mask;
      // Karıştır: çözülmüş dönüşlerden farklı bir başlangıç seç.
      final wrong = [
        for (var r = 0; r < 4; r++)
          if (!rotations.contains(r)) r,
      ];
      final start = wrong[rng.nextInt(wrong.length)];
      tiles[cell].rotation = start;
      // Saat yönünde tek yönlü: en yakın çözüm dönüşüne kaç tur.
      final turns = rotations
          .map((target) => (target - start + 4) % 4)
          .reduce(min);
      parMoves += turns;
    }

    // Yol dışı karoları rastgele doldur (bazıları yanıltıcı kablo).
    final onPath = path.toSet();
    for (var i = 0; i < tiles.length; i++) {
      if (i == batteryIndex || i == bulbIndex || onPath.contains(i)) continue;
      final roll = rng.nextInt(10);
      final kind = roll < 3
          ? WireKind.empty
          : roll < 6
          ? WireKind.straight
          : roll < 9
          ? WireKind.corner
          : WireKind.tee;
      tiles[i] = WireTile(kind, rng.nextInt(4));
    }

    final puzzle = WirePuzzle._(
      size: size,
      tiles: tiles,
      batteryIndex: batteryIndex,
      bulbIndex: bulbIndex,
      parMoves: parMoves,
      solutionMasks: solutionMasks,
    );
    // Baştan çözülmüş olmamalı (rastgele yol karoları ya da yanıltıcı
    // karolar bir yol kurmuş olabilir).
    if (puzzle.solved || parMoves == 0) return null;
    return puzzle;
  }

  static WirePuzzle _straightFallback(int size) {
    final row = size ~/ 2;
    final tiles = List<WireTile>.generate(size * size, (_) => WireTile(WireKind.empty));
    final batteryIndex = row * size;
    final bulbIndex = row * size + size - 1;
    tiles[batteryIndex] = WireTile(WireKind.battery);
    tiles[bulbIndex] = WireTile(WireKind.bulb);
    final masks = <int, int>{};
    for (var c = 1; c < size - 1; c++) {
      tiles[row * size + c] = WireTile(WireKind.straight, 0);
      masks[row * size + c] = _east | _west;
    }
    return WirePuzzle._(
      size: size,
      tiles: tiles,
      batteryIndex: batteryIndex,
      bulbIndex: bulbIndex,
      parMoves: size - 2 < 1 ? 1 : size - 2,
      solutionMasks: masks,
    );
  }

  /// [from] hücresinden [to] komşusuna giden yön biti.
  static int _bit(int from, int to, int size) {
    final dr = to ~/ size - from ~/ size;
    final dc = to % size - from % size;
    if (dr == -1) return _north;
    if (dr == 1) return _south;
    if (dc == 1) return _east;
    return _west;
  }

  /// İç sütunlarda (1..size-2) (startRow,1)'den (endRow,size-2)'ye kendini
  /// kesmeyen rastgele bir yol; başarısızsa null.
  static List<int>? _randomPath(int size, int startRow, int endRow, Random rng) {
    final start = startRow * size + 1;
    final target = endRow * size + size - 2;
    final visited = <int>{start};
    final path = <int>[start];

    bool walk(int current) {
      if (current == target) return true;
      final row = current ~/ size;
      final col = current % size;
      final moves = <int>[
        if (row > 0) current - size,
        if (row < size - 1) current + size,
        if (col > 1) current - 1,
        if (col < size - 2) current + 1,
      ]..shuffle(rng);
      for (final next in moves) {
        if (visited.contains(next)) continue;
        visited.add(next);
        path.add(next);
        if (walk(next)) return true;
        path.removeLast();
        visited.remove(next);
      }
      return false;
    }

    return walk(start) ? path : null;
  }
}
