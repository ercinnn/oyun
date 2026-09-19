/// Devrenin boşluğuna takılabilen bir malzeme. [conductive] true ise elektriği
/// iletir (devre kapanır), false ise yalıtkandır (devre açık kalır).
class ElectricMaterial {
  const ElectricMaterial({
    required this.id,
    required this.name,
    required this.emoji,
    required this.conductive,
    required this.note,
  });

  final String id;
  final String name;
  final String emoji;
  final bool conductive;

  /// Elle yazılmış açıklama cümlesi (değişken kelimeye ek getirilmez).
  final String note;
}
