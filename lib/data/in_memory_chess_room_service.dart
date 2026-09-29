import 'dart:async';

import '../models/chess_time_control.dart';
import 'chess_room_service.dart';

/// [ChessRoomService]'in bellek içi eşi — testler ve gerçek ağ olmadan iki
/// `ChessController`'ı birbirine bağlamak için. Aynı [InMemoryChessRoomService]
/// örneği her iki taraftan (host ve guest) paylaşılırsa, oda gerçekten
/// paylaşılan bir durum gibi davranır (bkz. `data/game_result_repository.dart`
/// `InMemoryGameResultRepository` ile aynı desen).
class InMemoryChessRoomService implements ChessRoomService {
  final Map<String, ChessRoomInfo> _rooms = {};
  final Map<String, List<void Function(ChessRoomInfo)>> _listeners = {};
  int _nextCode = 10000;

  void _notify(String code) {
    final info = _rooms[code];
    if (info == null) return;
    for (final listener in List.of(_listeners[code] ?? const [])) {
      listener(info);
    }
  }

  @override
  Future<ChessRoomInfo> createRoom({
    required String hostName,
    required ChessTimeControl timeControl,
  }) async {
    final code = (_nextCode++).toString();
    final info = ChessRoomInfo(
      code: code,
      hostName: hostName,
      timeControl: timeControl,
      moves: const [],
      status: ChessRoomStatus.waiting,
    );
    _rooms[code] = info;
    return info;
  }

  @override
  Future<ChessRoomInfo> joinRoom({
    required String code,
    required String guestName,
  }) async {
    final existing = _rooms[code];
    if (existing == null) {
      throw Exception('Oda bulunamadı: $code');
    }
    final updated = ChessRoomInfo(
      code: existing.code,
      hostName: existing.hostName,
      guestName: guestName,
      timeControl: existing.timeControl,
      moves: existing.moves,
      status: ChessRoomStatus.active,
    );
    _rooms[code] = updated;
    _notify(code);
    return updated;
  }

  @override
  Stream<ChessRoomInfo> watchRoom(String code) {
    late void Function(ChessRoomInfo) listener;
    // `sync: true`: hamleler zaten sırayla (yalnızca sırası gelen taraf
    // yazar) geldiği için olayı hemen, mikrotask beklemeden dinleyiciye
    // iletmek daha basit ve testlerde zamanlama kırılganlığı yaratmıyor.
    final controller = StreamController<ChessRoomInfo>(
      sync: true,
      onCancel: () => _listeners[code]?.remove(listener),
    );
    listener = controller.add;
    _listeners.putIfAbsent(code, () => []).add(listener);
    final current = _rooms[code];
    if (current != null) controller.add(current);
    return controller.stream;
  }

  @override
  Future<void> pushMove(String code, List<ChessRoomMove> moves) async {
    final existing = _rooms[code];
    if (existing == null) return;
    _rooms[code] = ChessRoomInfo(
      code: existing.code,
      hostName: existing.hostName,
      guestName: existing.guestName,
      timeControl: existing.timeControl,
      moves: moves,
      status: existing.status,
    );
    _notify(code);
  }
}
