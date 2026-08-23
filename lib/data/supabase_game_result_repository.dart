import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game_result.dart';
import 'game_result_repository.dart';

/// [GameResultRepository]'nin Supabase `game_results` tablosuna yazan
/// implementasyonu. Tablo şeması ve RLS politikaları için bkz.
/// `supabase/schema.sql`.
class SupabaseGameResultRepository implements GameResultRepository {
  SupabaseGameResultRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const _table = 'game_results';

  final SupabaseClient _client;

  @override
  Future<void> saveResult(GameResult result) async {
    await _client.from(_table).insert({
      'player_name': result.playerName,
      'attempts': result.attempts,
      'finished_at': result.finishedAt.toIso8601String(),
    });
  }

  @override
  Future<List<GameResult>> fetchResults() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('finished_at', ascending: false);
    return rows
        .map(
          (row) => GameResult(
            playerName: row['player_name'] as String,
            attempts: row['attempts'] as int,
            finishedAt: DateTime.parse(row['finished_at'] as String),
          ),
        )
        .toList();
  }
}
