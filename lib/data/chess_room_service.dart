import '../models/chess_piece.dart';
import '../models/chess_time_control.dart';

/// [ChessRoomService.pushMove]/[ChessRoomService.watchRoom] üzerinden taşınan
/// minimal hamle gösterimi. `ChessMove.movingPiece`/`capturedPiece`/`flag`
/// bilerek taşınmıyor — alıcı taraf, aynı `ChessBoard.initial()`'dan aynı
/// hamle sırasını uyguladığı için, `board.legalMovesFrom(from)` içinde
/// `to`/`promotionType` eşleşen hamleyi bulup tam `ChessMove`'u kendisi
/// üretebilir (bkz. `ChessOnlineSetupScreen`).
class ChessRoomMove {
  const ChessRoomMove({required this.from, required this.to, this.promotionType});

  final int from;
  final int to;
  final PieceType? promotionType;

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    if (promotionType != null) 'promotionType': promotionType!.name,
  };

  factory ChessRoomMove.fromJson(Map<String, dynamic> json) => ChessRoomMove(
    from: json['from'] as int,
    to: json['to'] as int,
    promotionType: json['promotionType'] == null
        ? null
        : PieceType.values.byName(json['promotionType'] as String),
  );
}

enum ChessRoomStatus { waiting, active, finished }

/// Bir online satranç odasının o anki durumu. `code` kullanıcıya gösterilen
/// paylaşılabilir kısa koddur (Supabase satırının `id`'si değil).
class ChessRoomInfo {
  const ChessRoomInfo({
    required this.code,
    required this.hostName,
    this.guestName,
    required this.timeControl,
    required this.moves,
    required this.status,
  });

  final String code;
  final String hostName;
  final String? guestName;
  final ChessTimeControl timeControl;
  final List<ChessRoomMove> moves;
  final ChessRoomStatus status;

  bool get hasGuest => guestName != null && guestName!.isNotEmpty;
}

/// Oda kodu ile eşleşen iki cihaz arasında satranç hamlelerini taşıyan servis.
/// [SupabaseChessRoomService] gerçek Supabase realtime akışını kullanır,
/// [InMemoryChessRoomService] testler/geliştirme için bellek içi bir eşi
/// sağlar — `data/game_result_repository.dart` ile aynı arayüz + gerçek +
/// sahte deseni.
abstract class ChessRoomService {
  /// Yeni bir oda kurar ve paylaşılabilir kısa kodu döner.
  Future<ChessRoomInfo> createRoom({
    required String hostName,
    required ChessTimeControl timeControl,
  });

  /// Var olan bir odaya ikinci oyuncu olarak katılır.
  Future<ChessRoomInfo> joinRoom({required String code, required String guestName});

  /// Odadaki değişiklikleri (misafirin katılması, yeni hamleler) canlı yayınlar.
  Stream<ChessRoomInfo> watchRoom(String code);

  /// Odanın güncel hamle listesini (yeni hamle dahil) sunucuya yazar.
  Future<void> pushMove(String code, List<ChessRoomMove> moves);
}
