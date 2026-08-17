import '../models/game_result.dart';
import 'game_result_repository.dart';

/// v1 için basit oturum-içi (kalıcı olmayan) depolama.
/// Supabase bağlanınca bu sınıfın yerine [GameResultRepository] arayüzünü
/// uygulayan bir SupabaseGameResultRepository geçirilecek.
class InMemoryGameResultRepository implements GameResultRepository {
  final List<GameResult> _results = [];

  @override
  Future<void> saveResult(GameResult result) async {
    _results.add(result);
  }

  @override
  Future<List<GameResult>> fetchResults() async {
    return List.unmodifiable(_results);
  }
}
