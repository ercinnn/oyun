/// Kart eşleştirme oyunundaki bir oyuncunun durumu. Puan, o oyuncunun
/// bulduğu eşleşmiş çift sayısıdır; kazanan en çok çifti bulandır.
class MemoryPlayerState {
  MemoryPlayerState({required this.name});

  final String name;
  int matchedPairs = 0;
}
