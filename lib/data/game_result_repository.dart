import '../models/game_result.dart';

/// İleride bir Supabase implementasyonuyla değiştirilebilecek soyutlama.
abstract class GameResultRepository {
  Future<void> saveResult(GameResult result);
  Future<List<GameResult>> fetchResults();
}
