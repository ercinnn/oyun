import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chess_time_control.dart';
import 'chess_room_service.dart';

/// [ChessRoomService]'in Supabase `chess_rooms` tablosuna yazan/dinleyen
/// implementasyonu. Tablo şeması ve RLS politikaları için bkz.
/// `supabase/schema.sql`.
class SupabaseChessRoomService implements ChessRoomService {
  SupabaseChessRoomService({SupabaseClient? client, Random? random})
    : _client = client ?? Supabase.instance.client,
      _random = random ?? Random();

  static const _table = 'chess_rooms';
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _codeLength = 5;
  static const _uniqueViolation = '23505';

  final SupabaseClient _client;
  final Random _random;

  String _newCode() =>
      String.fromCharCodes([
        for (var i = 0; i < _codeLength; i++)
          _codeChars.codeUnitAt(_random.nextInt(_codeChars.length)),
      ]);

  ChessRoomInfo _fromRow(Map<String, dynamic> row) {
    final rawMoves = row['moves'] as List<dynamic>? ?? const [];
    return ChessRoomInfo(
      code: row['code'] as String,
      hostName: row['host_name'] as String,
      guestName: row['guest_name'] as String?,
      timeControl: ChessTimeControl.values.byName(row['time_control'] as String),
      moves: [
        for (final entry in rawMoves)
          ChessRoomMove.fromJson(entry as Map<String, dynamic>),
      ],
      status: ChessRoomStatus.values.byName(row['status'] as String),
    );
  }

  @override
  Future<ChessRoomInfo> createRoom({
    required String hostName,
    required ChessTimeControl timeControl,
  }) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _newCode();
      try {
        final row = await _client
            .from(_table)
            .insert({
              'code': code,
              'host_name': hostName,
              'time_control': timeControl.name,
            })
            .select()
            .single();
        return _fromRow(row);
      } on PostgrestException catch (e) {
        if (e.code != _uniqueViolation) rethrow;
      }
    }
    throw Exception('Oda kodu üretilemedi, lütfen tekrar deneyin.');
  }

  @override
  Future<ChessRoomInfo> joinRoom({
    required String code,
    required String guestName,
  }) async {
    final row = await _client
        .from(_table)
        .update({'guest_name': guestName, 'status': ChessRoomStatus.active.name})
        .eq('code', code)
        .select()
        .single();
    return _fromRow(row);
  }

  @override
  Stream<ChessRoomInfo> watchRoom(String code) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('code', code)
        .map((rows) => rows.isEmpty ? null : _fromRow(rows.single))
        .where((info) => info != null)
        .cast<ChessRoomInfo>();
  }

  @override
  Future<void> pushMove(String code, List<ChessRoomMove> moves) async {
    await _client
        .from(_table)
        .update({
          'moves': [for (final m in moves) m.toJson()],
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('code', code);
  }
}
