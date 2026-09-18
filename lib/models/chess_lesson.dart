/// Satranç derslerinin veri modeli. Dersler saf veridir: her adım bir FEN
/// pozisyonu + metin (+ doğru cevap) taşır, mantığı `ChessLessonController`
/// çalıştırır. Kareler ham index yerine 'e4' gibi adlarla yazılır.
enum ChessLessonLevel {
  baslangic('Başlangıç'),
  orta('Orta'),
  ileri('İleri');

  const ChessLessonLevel(this.label);
  final String label;
}

sealed class ChessLessonStep {
  const ChessLessonStep();
}

/// Anlatım + (varsa) diyagram; "Devam" ile geçilir.
class LessonInfoStep extends ChessLessonStep {
  const LessonInfoStep({
    required this.text,
    this.fen,
    this.highlights = const [],
  });

  final String text;
  final String? fen;
  final List<String> highlights;
}

/// Tahtada tek bir hamle bulma görevi. Kabul edilen hamleler ya `accepted`
/// ('e2e4' biçiminde kalkış+varış) listesinde ya da [anyMate] ise mat eden
/// herhangi bir hamledir. Yasal ama kabul edilmeyen bir hamle [wrong]
/// gösterir ve pozisyonu sıfırlar; sınırsız deneme hakkı vardır.
class LessonMoveStep extends ChessLessonStep {
  const LessonMoveStep({
    required this.fen,
    required this.prompt,
    required this.success,
    required this.wrong,
    this.accepted = const [],
    this.anyMate = false,
    this.highlights = const [],
  });

  final String fen;
  final String prompt;
  final String success;
  final String wrong;
  final List<String> accepted;
  final bool anyMate;
  final List<String> highlights;
}

/// "Bu taşın gidebileceği tüm kareleri işaretle." Hedefler motorun yasal
/// hamlelerinden hesaplanır, elle yazılmaz.
class LessonMarkStep extends ChessLessonStep {
  const LessonMarkStep({
    required this.fen,
    required this.prompt,
    required this.pieceSquare,
    required this.success,
  });

  final String fen;
  final String prompt;
  final String pieceSquare;
  final String success;
}

/// Çoktan seçmeli soru; yanlış seçenekte tekrar denenir.
class LessonQuizStep extends ChessLessonStep {
  const LessonQuizStep({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.fen,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? fen;
}

class ChessLesson {
  const ChessLesson({
    required this.id,
    required this.level,
    required this.title,
    required this.summary,
    required this.steps,
  });

  final String id;
  final ChessLessonLevel level;
  final String title;
  final String summary;
  final List<ChessLessonStep> steps;
}
