import 'shop_catalog.dart';

/// Odada yerleştirilmiş bir eşya: sol-üst karosu ve yönü (0-3, saat yönünde
/// çeyrek tur). Yön tek sayıysa genişlik ile derinlik yer değiştirir.
class PlacedItem {
  const PlacedItem({
    required this.itemId,
    required this.x,
    required this.y,
    this.rotation = 0,
  });

  final String itemId;
  final int x;
  final int y;
  final int rotation;

  PlacedItem copyWith({int? x, int? y, int? rotation}) => PlacedItem(
    itemId: itemId,
    x: x ?? this.x,
    y: y ?? this.y,
    rotation: rotation ?? this.rotation,
  );

  Map<String, Object> toJson() => {
    'id': itemId,
    'x': x,
    'y': y,
    'rot': rotation,
  };

  static PlacedItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final x = json['x'];
    final y = json['y'];
    final rot = json['rot'];
    if (id is! String || x is! int || y is! int) return null;
    return PlacedItem(
      itemId: id,
      x: x,
      y: y,
      rotation: rot is int ? rot % 4 : 0,
    );
  }
}

/// Odanın boyutu (karo).
const int roomSize = 8;

const List<int> roomFloorColors = [
  0xFFE0C9A6,
  0xFFB0BEC5,
  0xFFC8E6C9,
  0xFFF8BBD0,
  0xFFBBDEFB,
];

const List<int> roomWallColors = [
  0xFFFFF3E0,
  0xFFE1F5FE,
  0xFFF3E5F5,
  0xFFE8F5E9,
  0xFFFFEBEE,
];

/// Oda düzeni: zemin/duvar rengi ve eşyalar. Eşyalar oda sınırları içinde
/// kalmalı ve çakışmamalıdır ([canPlace]); halı gibi zemin eşyaları (yükseklik
/// ≈ 0) başka eşyaların altına girebilir.
class RoomLayout {
  const RoomLayout({
    this.floorColor = 0,
    this.wallColor = 0,
    this.items = const [],
  });

  final int floorColor;
  final int wallColor;
  final List<PlacedItem> items;

  RoomLayout copyWith({
    int? floorColor,
    int? wallColor,
    List<PlacedItem>? items,
  }) => RoomLayout(
    floorColor: floorColor ?? this.floorColor,
    wallColor: wallColor ?? this.wallColor,
    items: items ?? this.items,
  );

  /// [item]'ın [rotation] yönündeki karo genişliği/derinliği.
  static (int, int) footprint(ShopItem item, int rotation) =>
      rotation.isOdd ? (item.depth, item.width) : (item.width, item.depth);

  /// Zemin eşyası mı (halı): üstüne basılabilir, çakışma sayılmaz.
  static bool isFlat(ShopItem item) => item.height < 0.1;

  /// [item] bu konumda ve yönde yerleştirilebilir mi? [ignoreIndex] bir
  /// eşyayı taşırken kendisiyle çakışmasın diye yok sayılan indekstir.
  bool canPlace(ShopItem item, int x, int y, int rotation, {int? ignoreIndex}) {
    final (w, d) = footprint(item, rotation);
    if (x < 0 || y < 0 || x + w > roomSize || y + d > roomSize) return false;
    if (isFlat(item)) return true;

    for (var i = 0; i < items.length; i++) {
      if (i == ignoreIndex) continue;
      final other = shopItemById(items[i].itemId);
      if (other == null || isFlat(other)) continue;
      final (ow, od) = footprint(other, items[i].rotation);
      final overlapX = x < items[i].x + ow && items[i].x < x + w;
      final overlapY = y < items[i].y + od && items[i].y < y + d;
      if (overlapX && overlapY) return false;
    }
    return true;
  }

  /// [x], [y] karosunu kaplayan eşyanın indeksi; yoksa -1. Zemin eşyaları
  /// başka eşya yoksa seçilebilir.
  int itemIndexAt(int x, int y) {
    var flatHit = -1;
    for (var i = 0; i < items.length; i++) {
      final item = shopItemById(items[i].itemId);
      if (item == null) continue;
      final (w, d) = footprint(item, items[i].rotation);
      final hit =
          x >= items[i].x && x < items[i].x + w && y >= items[i].y && y < items[i].y + d;
      if (!hit) continue;
      if (isFlat(item)) {
        flatHit = i;
      } else {
        return i;
      }
    }
    return flatHit;
  }

  Map<String, Object> toJson() => {
    'floor': floorColor,
    'wall': wallColor,
    'items': [for (final item in items) item.toJson()],
  };

  factory RoomLayout.fromJson(Object? json) {
    if (json is! Map) return const RoomLayout();
    final floor = json['floor'];
    final wall = json['wall'];
    final rawItems = json['items'];
    return RoomLayout(
      floorColor: floor is int && floor >= 0 && floor < roomFloorColors.length
          ? floor
          : 0,
      wallColor: wall is int && wall >= 0 && wall < roomWallColors.length
          ? wall
          : 0,
      items: [
        if (rawItems is List)
          for (final raw in rawItems) ?PlacedItem.fromJson(raw),
      ],
    );
  }
}
