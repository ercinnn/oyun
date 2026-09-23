import 'avatar_spec.dart';
import 'room_layout.dart';
import 'shop_catalog.dart';

/// Cihazda saklanan kasaba ilerlemesi: avatar, altın, sahip olunan eşyalar
/// (mobilyada adetle), oda düzeni ve ses tercihleri.
class TownProfile {
  TownProfile({
    this.avatar = const AvatarSpec(),
    this.coins = 50,
    Map<String, int>? owned,
    this.room = const RoomLayout(),
    this.soundOn = true,
    this.musicOn = true,
  }) : owned = owned ?? _starterItems();

  AvatarSpec avatar;
  int coins;

  /// Ses efektleri ve müzik açık mı (ayrı ayrı kapatılabilir).
  bool soundOn;
  bool musicOn;

  /// Eşya kimliği → adet (avatar eşyaları 1, mobilya birden fazla olabilir).
  Map<String, int> owned;
  RoomLayout room;

  /// Başlangıçta ücretsiz eşyalar (fiyat 0) ve odayı boş bırakmayan mobilya.
  static Map<String, int> _starterItems() => {
    for (final item in shopCatalog)
      if (item.price == 0) item.id: 1,
  };

  bool owns(String id) => (owned[id] ?? 0) > 0;

  /// Mobilyadan odaya yerleştirilmemiş adet.
  int availableCount(String id) {
    final placed = room.items.where((item) => item.itemId == id).length;
    return (owned[id] ?? 0) - placed;
  }

  /// [item]'ı satın almaya çalışır: yetersiz altında false. Avatar eşyası
  /// zaten varsa tekrar alınmaz; mobilya birden çok alınabilir.
  bool buy(ShopItem item) {
    final isFurniture = item.category == ShopCategory.furniture;
    if (!isFurniture && owns(item.id)) return false;
    if (coins < item.price) return false;
    coins -= item.price;
    owned[item.id] = (owned[item.id] ?? 0) + 1;
    return true;
  }

  Map<String, Object> toJson() => {
    'avatar': avatar.toJson(),
    'coins': coins,
    'owned': owned,
    'room': room.toJson(),
    'soundOn': soundOn,
    'musicOn': musicOn,
  };

  /// Bozuk/eksik kayıtta güvenli varsayılana düşer.
  factory TownProfile.fromJson(Object? json) {
    if (json is! Map) return TownProfile();
    final avatar = json['avatar'];
    final coins = json['coins'];
    final owned = json['owned'];

    final ownedItems = _starterItems();
    if (owned is Map) {
      owned.forEach((key, value) {
        if (key is String && value is int && value > 0) {
          ownedItems[key] = value;
        }
      });
    }
    return TownProfile(
      avatar: avatar is Map<String, dynamic>
          ? AvatarSpec.fromJson(avatar)
          : const AvatarSpec(),
      coins: coins is int && coins >= 0 ? coins : 50,
      owned: ownedItems,
      room: RoomLayout.fromJson(json['room']),
      // Ses tercihleri sonradan eklendi: eski kayıtta alan yok, açık kalır.
      soundOn: json['soundOn'] is bool ? json['soundOn'] as bool : true,
      musicOn: json['musicOn'] is bool ? json['musicOn'] as bool : true,
    );
  }
}
