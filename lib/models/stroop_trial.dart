import 'stroop_color.dart';

/// Tek bir Stroop turu: ekranda [word]'ün Türkçe adı, [ink] renginde
/// yazılır. Doğru cevap her zaman [ink]'tir. [options], o turda cevap
/// butonlarının gösterileceği (karışık) sırayı sabitler — oyuncunun konum
/// ezberiyle kelimeyi okumadan cevap vermesini önlemek için her tur
/// yeniden karıştırılır (bkz. [StroopController._generateTrial]).
class StroopTrial {
  const StroopTrial({
    required this.word,
    required this.ink,
    required this.options,
  });

  final StroopColor word;
  final StroopColor ink;
  final List<StroopColor> options;
}
