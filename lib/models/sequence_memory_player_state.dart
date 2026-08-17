/// Dizi Hafızası oyunundaki bir oyuncunun durumu. Her oyuncu tek bir koşu
/// oynar; kazanan, en uzun diziyi tamamlayandır.
class SequenceMemoryPlayerState {
  SequenceMemoryPlayerState({required this.name});

  final String name;
  int bestLength = 0;
  bool finished = false;
}
