import 'simon_attribute_type.dart';
import 'simon_tile_id.dart';

/// Simon Diyor ki oyunundaki tek bir tur: [target] kutuyu [attributeType]
/// (renk veya şekil) üzerinden tanımlayan bir talimat gösterir. [obey]
/// true ise talimat "Simon dedi ki:" ile başlar ve oyuncu uygulamalıdır;
/// false ise talimat bu önek olmadan gösterilir ve doğru tepki dokunmamak
/// (Pas Geç) olur — klasik Simon Says kuralı. [boardOrder], o turda 4
/// kutunun ekrandaki (karıştırılmış) sırasını sabitler.
class SimonTrial {
  const SimonTrial({
    required this.obey,
    required this.attributeType,
    required this.target,
    required this.boardOrder,
  });

  final bool obey;
  final SimonAttributeType attributeType;
  final SimonTileId target;
  final List<SimonTileId> boardOrder;

  /// Talimat metni. Türkçe'de sonek uyumu sorunlarından kaçınmak için
  /// değişken kelimenin (renk/şekil adı) kendisine doğrudan ek
  /// getirilmiyor — "rengine"/"şekline" gibi sabit bir kelime, adın
  /// hemen ardından geliyor.
  String get instructionText {
    final action = attributeType == SimonAttributeType.color
        ? '${target.colorLabel} rengine dokun!'
        : '${target.shapeLabel} şekline dokun!';
    return obey ? 'Simon dedi ki: $action' : action;
  }
}
