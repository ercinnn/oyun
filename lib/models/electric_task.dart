import 'circuit_spec.dart';
import 'wire_puzzle.dart';

/// Görevler modundaki tur türleri; tur `round % 5` ile bu sırayla döner.
enum ElectricTaskKind {
  circuit('Devre tahmini'),
  conductor('İletken mi, yalıtkan mı?'),
  wire('Kablo yolu'),
  city('Enerji şehri'),
  safety('Güvenlik dedektifi');

  const ElectricTaskKind(this.title);
  final String title;
}

/// Sonuç panelinde çizilen etiketli bir devre.
class LabeledCircuit {
  const LabeledCircuit(this.label, this.spec);

  final String label;
  final CircuitSpec spec;
}

sealed class ElectricTask {
  const ElectricTask();

  ElectricTaskKind get kind;
}

/// Çoktan seçmeli görev: devre tahmini, iletken/yalıtkan, enerji şehri ve
/// güvenlik soruları aynı yapıyı paylaşır.
class ChoiceTask extends ElectricTask {
  const ChoiceTask({
    required this.kind,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.subject,
    this.circuits = const [],
  });

  @override
  final ElectricTaskKind kind;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  /// Cevaptan sonra gösterilen açıklama.
  final String explanation;

  /// Sorunun konusu (malzeme adı + emoji, sahne metni, hava durumu…).
  final String? subject;

  /// Soruda ve sonuç panelinde çizilen devreler (boş olabilir).
  final List<LabeledCircuit> circuits;
}

/// Kablo yolu bulmacası görevi.
class WireTask extends ElectricTask {
  WireTask(this.puzzle);

  final WirePuzzle puzzle;

  @override
  ElectricTaskKind get kind => ElectricTaskKind.wire;

  /// Hamle sayısı ideal + bu kadarı içindeyse tur "doğru" sayılır.
  static const int moveSlack = 4;

  bool get solvedWell => puzzle.solved && puzzle.moves <= puzzle.parMoves + moveSlack;

  String get explanation =>
      'Pilden ampule kesintisiz bir yol kurdun; akım artık dolaşabiliyor. '
      'Hamle sayın: ${puzzle.moves}. En az gereken hamle: ${puzzle.parMoves}. '
      '${puzzle.moves <= puzzle.parMoves + moveSlack ? 'Çok iyi, kısa yoldan buldun!' : 'Bir dahaki sefere daha az hamleyle deneyebilirsin.'}';
}
