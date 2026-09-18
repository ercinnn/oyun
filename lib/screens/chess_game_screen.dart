import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/chess_controller.dart';
import '../models/chess_piece.dart';
import '../widgets/chess_board_view.dart';
import '../widgets/chess_captured_pieces.dart';
import '../widgets/chess_clock_panel.dart';
import '../widgets/chess_evaluation_bar.dart';
import '../widgets/chess_move_history.dart';
import '../widgets/chess_piece_glyph.dart';

class ChessGameScreen extends StatefulWidget {
  const ChessGameScreen({super.key});

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  bool _promotionDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChessController>();

    if (controller.pendingPromotionMoves.isNotEmpty && !_promotionDialogShown) {
      _promotionDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showPromotionDialog(context, controller);
      });
    } else if (controller.pendingPromotionMoves.isEmpty) {
      _promotionDialogShown = false;
    }

    final sideName = controller.currentColor == PieceColor.white
        ? controller.whiteName
        : controller.blackName;
    final title = controller.aiThinking
        ? '$sideName (Bilgisayar düşünüyor...)'
        : sideName;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (controller.isCheck)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  'Şah!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (controller.hasClock) ...[
              _ClockRow(controller: controller),
              const SizedBox(height: 12),
            ],
            Expanded(child: _BoardArea(controller: controller)),
          ],
        ),
      ),
    );
  }

  void _showPromotionDialog(BuildContext context, ChessController controller) {
    final color = controller.pendingPromotionMoves.first.movingPiece.color;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Terfi'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final type in const [
                PieceType.queen,
                PieceType.rook,
                PieceType.bishop,
                PieceType.knight,
              ])
                // Seçenekler tahtadaki taşla aynı çizimi kullanır; testler
                // sembol metni yerine bu anahtarlara dokunur.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    key: ValueKey('promote_${type.name}'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      controller.resolvePromotion(type);
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0D9B5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: ChessPieceGlyph(
                          piece: ChessPiece(type, color),
                          size: 52,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// İki oyuncunun dijital saatleri. Yalnızca süreli oyunda gösterilir; sırası
/// gelen tarafınki vurgulanır.
class _ClockRow extends StatelessWidget {
  const _ClockRow({required this.controller});

  final ChessController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: ChessClockPanel(
            key: const Key('chessClockWhite'),
            name: controller.whiteName,
            remaining: controller.whiteRemaining,
            isActive: controller.currentColor == PieceColor.white,
            isWhite: true,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: ChessClockPanel(
            key: const Key('chessClockBlack'),
            name: controller.blackName,
            remaining: controller.blackRemaining,
            isActive: controller.currentColor == PieceColor.black,
            isWhite: false,
          ),
        ),
      ],
    );
  }
}

/// Değerlendirme çubuğu + tahta + hamle geçmişi. Tahtanın kenar uzunluğu
/// burada bir kez hesaplanıp hepsine veriliyor: çubuk ve panel tam tahta
/// boyunda olsun ve tahta kare kalsın diye (`AspectRatio` tek başına
/// yanındakilerin yüksekliğini bilemezdi).
///
/// Hamle geçmişi geniş ekranda tahtanın sağında dikey panel, dar ekranda
/// tahtanın altında yatay şerit olarak çizilir — telefonda dikey bir panel
/// için yeterli genişlik yok, tahtayı küçültmek de oynanabilirliği bozardı.
class _BoardArea extends StatelessWidget {
  const _BoardArea({required this.controller});

  static const _barWidth = 22.5;
  static const _gap = 12.0;

  /// Değerlendirme çubuğu ile tahta arasındaki boşluk (eskisinin 1/10'u).
  static const _barGap = 1.2;
  static const _historyPanelWidth = 190.0;
  static const _historyStripHeight = 44.0;

  /// Ele geçirilen taş şeritlerinin (tahtanın üstünde ve altında birer tane)
  /// sabit yüksekliği ve tahta çerçevesiyle arasındaki boşluk.
  static const _capturedRowHeight = 26.0;
  static const _capturedRowGap = 4.0;

  /// Bu genişliğin altında geçmiş, tahtanın sağına değil altına konur.
  static const _sidePanelBreakpoint = 640.0;

  final ChessController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sidePanel = constraints.maxWidth >= _sidePanelBreakpoint;
        final widthForBoard =
            constraints.maxWidth -
            _barWidth -
            _barGap -
            (sidePanel ? _historyPanelWidth + _gap : 0);
        // Ele geçirilen taş şeritleri tahta çerçevesinin üstüne/altına
        // eklendiği için (bkz. aşağıdaki sütun), tahtanın kendi kare kenar
        // uzunluğu bu iki şeridin yüksekliği düşülerek hesaplanır — tıpkı
        // dar ekranda yatay geçmiş şeridinin zaten aynı şekilde
        // düşülmesi gibi.
        final capturedOverhead = 2 * (_capturedRowHeight + _capturedRowGap);
        final heightForBoard =
            (sidePanel
                ? constraints.maxHeight
                : constraints.maxHeight - _historyStripHeight - _gap) -
            capturedOverhead;
        final boardSize = widthForBoard < heightForBoard
            ? widthForBoard
            : heightForBoard;
        // Değerlendirme çubuğu ve hamle geçmişi paneli artık sadece tahtayla
        // değil, tahta + iki taş şeridiyle birlikte aynı boyda olmalı.
        final columnHeight = boardSize + capturedOverhead;

        final bottomColor = controller.viewpointColor;
        final topColor = bottomColor == PieceColor.white
            ? PieceColor.black
            : PieceColor.white;

        final row = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _barWidth,
              height: columnHeight,
              child: ChessEvaluationBar(
                whiteWinChance: controller.whiteWinChance,
                flipped: controller.boardFlipped,
              ),
            ),
            const SizedBox(width: _barGap),
            SizedBox(
              width: boardSize,
              height: columnHeight,
              child: Column(
                children: [
                  SizedBox(
                    height: _capturedRowHeight,
                    child: _capturedRowFor(topColor),
                  ),
                  const SizedBox(height: _capturedRowGap),
                  SizedBox.square(
                    dimension: boardSize,
                    child: ChessBoardFrame(
                      child: _ChessBoardView(controller: controller),
                    ),
                  ),
                  const SizedBox(height: _capturedRowGap),
                  SizedBox(
                    height: _capturedRowHeight,
                    child: _capturedRowFor(bottomColor),
                  ),
                ],
              ),
            ),
            if (sidePanel) ...[
              const SizedBox(width: _gap),
              SizedBox(
                width: _historyPanelWidth,
                height: columnHeight,
                child: ChessMoveHistory(notations: controller.moveNotations),
              ),
            ],
          ],
        );

        if (sidePanel) return Center(child: row);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            row,
            const SizedBox(height: _gap),
            SizedBox(
              width: boardSize + _barWidth + _barGap,
              height: _historyStripHeight,
              child: ChessMoveHistory(
                notations: controller.moveNotations,
                axis: Axis.horizontal,
              ),
            ),
          ],
        );
      },
    );
  }

  /// [color] tarafının ele geçirdiği taşları ve (öndeyse) taş puanı farkını
  /// gösteren şerit. Alttaki taraf her zaman `controller.viewpointColor`,
  /// üstteki onun tersi — tahta döndüğünde (2 kişilik modda) şeritler de
  /// `_ChessBoardView`'ın kendisiyle aynı mantıkla birlikte döner.
  Widget _capturedRowFor(PieceColor color) {
    final pieces = color == PieceColor.white
        ? controller.capturedByWhite
        : controller.capturedByBlack;
    final diff = controller.materialDifference;
    final advantage = switch (color) {
      PieceColor.white when diff > 0 => diff,
      PieceColor.black when diff < 0 => -diff,
      _ => null,
    };
    return ChessCapturedPieces(
      key: Key(
        color == PieceColor.white
            ? 'chessCapturedByWhite'
            : 'chessCapturedByBlack',
      ),
      pieces: pieces,
      advantage: advantage,
    );
  }
}

/// Oyun ekranının tahtası: [ChessController] durumunu ortak
/// [ChessBoardView]'a düz parametrelere çevirir.
class _ChessBoardView extends StatelessWidget {
  const _ChessBoardView({required this.controller});

  final ChessController controller;

  @override
  Widget build(BuildContext context) {
    final history = controller.board.moveHistory;
    final lastMove = history.isEmpty ? null : history.last;
    return ChessBoardView(
      squares: controller.board.squares,
      flipped: controller.boardFlipped,
      selectedSquare: controller.selectedSquare,
      legalTargets: {for (final m in controller.selectedSquareLegalMoves) m.to},
      lastMoveSquares: lastMove == null ? const {} : {lastMove.from, lastMove.to},
      // Şah çekilen tarafın kralı; tam bir tane vardır ama test kurulumları
      // kralsız konum kurabildiği için null'a karşı korunur.
      checkedKingSquare: controller.isCheck
          ? controller.board.kingSquare(controller.currentColor)
          : null,
      onSquareTap: controller.selectSquare,
    );
  }
}
