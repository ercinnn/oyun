import 'dart:ui';

/// Avatarın paletleri (kimlik = liste indeksi). Renkler ücretsizdir; biçimler
/// (saç, kıyafet, şapka, aksesuar) mağazadan alınır.
const List<Color> skinPalette = [
  Color(0xFFFFDBB4),
  Color(0xFFF1C27D),
  Color(0xFFE0AC69),
  Color(0xFFC68642),
  Color(0xFF8D5524),
  Color(0xFF5C3A1E),
];

const List<Color> hairPalette = [
  Color(0xFF2B1B10),
  Color(0xFF6A4B2A),
  Color(0xFFC9A227),
  Color(0xFFD9541E),
  Color(0xFF9E9E9E),
  Color(0xFF3F51B5),
  Color(0xFFE91E63),
  Color(0xFF4CAF50),
];

const List<Color> outfitPalette = [
  Color(0xFFE53935),
  Color(0xFFFB8C00),
  Color(0xFFFDD835),
  Color(0xFF43A047),
  Color(0xFF1E88E5),
  Color(0xFF8E24AA),
  Color(0xFFEC407A),
  Color(0xFF546E7A),
];

/// Avatarın görünümü. Biçimler mağaza kimlikleridir (`hair_short`, `outfit_tee`,
/// `hat_none`, `acc_none`…); renkler palet indeksleridir. JSON'a çevrilebilir,
/// böylece cihazda saklanır.
class AvatarSpec {
  const AvatarSpec({
    this.skin = 1,
    this.hairStyle = 'hair_short',
    this.hairColor = 0,
    this.outfit = 'outfit_tee',
    this.outfitColor = 4,
    this.hat = 'hat_none',
    this.accessory = 'acc_none',
  });

  final int skin;
  final String hairStyle;
  final int hairColor;
  final String outfit;
  final int outfitColor;
  final String hat;
  final String accessory;

  AvatarSpec copyWith({
    int? skin,
    String? hairStyle,
    int? hairColor,
    String? outfit,
    int? outfitColor,
    String? hat,
    String? accessory,
  }) => AvatarSpec(
    skin: skin ?? this.skin,
    hairStyle: hairStyle ?? this.hairStyle,
    hairColor: hairColor ?? this.hairColor,
    outfit: outfit ?? this.outfit,
    outfitColor: outfitColor ?? this.outfitColor,
    hat: hat ?? this.hat,
    accessory: accessory ?? this.accessory,
  );

  Map<String, Object> toJson() => {
    'skin': skin,
    'hairStyle': hairStyle,
    'hairColor': hairColor,
    'outfit': outfit,
    'outfitColor': outfitColor,
    'hat': hat,
    'accessory': accessory,
  };

  /// Bozuk/eksik alanlarda varsayılana düşer (eski kayıtlar oyunu bozmasın).
  factory AvatarSpec.fromJson(Map<String, dynamic> json) {
    int color(String key, int fallback, int length) {
      final value = json[key];
      return value is int && value >= 0 && value < length ? value : fallback;
    }

    String text(String key, String fallback) {
      final value = json[key];
      return value is String && value.isNotEmpty ? value : fallback;
    }

    const base = AvatarSpec();
    return AvatarSpec(
      skin: color('skin', base.skin, skinPalette.length),
      hairStyle: text('hairStyle', base.hairStyle),
      hairColor: color('hairColor', base.hairColor, hairPalette.length),
      outfit: text('outfit', base.outfit),
      outfitColor: color('outfitColor', base.outfitColor, outfitPalette.length),
      hat: text('hat', base.hat),
      accessory: text('accessory', base.accessory),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AvatarSpec &&
      other.skin == skin &&
      other.hairStyle == hairStyle &&
      other.hairColor == hairColor &&
      other.outfit == outfit &&
      other.outfitColor == outfitColor &&
      other.hat == hat &&
      other.accessory == accessory;

  @override
  int get hashCode => Object.hash(
    skin,
    hairStyle,
    hairColor,
    outfit,
    outfitColor,
    hat,
    accessory,
  );
}
