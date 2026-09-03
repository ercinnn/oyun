import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/chess_controller.dart';
import '../models/chess_piece.dart';
import '../models/chess_square.dart';
import '../widgets/chess_square_widget.dart';

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
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: _ChessBoardView(controller: controller),
          ),
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
                IconButton(
                  iconSize: 36,
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    controller.resolvePromotion(type);
                  },
                  icon: Text(ChessPiece(type, color).glyph),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ChessBoardView extends StatelessWidget {
  const _ChessBoardView({required this.controller});

  final ChessController controller;

  @override
  Widget build(BuildContext context) {
    final flipped = controller.boardFlipped;
    final ranks = flipped
        ? List<int>.generate(8, (r) => r)
        : List<int>.generate(8, (r) => 7 - r);
    final files = flipped
        ? List<int>.generate(8, (f) => 7 - f)
        : List<int>.generate(8, (f) => f);
    final displayOrder = [
      for (final r in ranks)
        for (final f in files) squareIndex(f, r),
    ];

    final legalTargets = {
      for (final m in controller.selectedSquareLegalMoves) m.to,
    };

    return GridView.count(
      crossAxisCount: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final square in displayOrder)
          ChessSquareWidget(
            key: ValueKey('sq_$square'),
            piece: controller.board.squares[square],
            // a1 (file 0, rank 0) koyu kare olmalı — gerçek satranç
            // diziliminin tersine dönmemesi için toplam tek olduğunda açık.
            isLight: (fileOf(square) + rankOf(square)).isOdd,
            isSelected: controller.selectedSquare == square,
            isLegalDestination: legalTargets.contains(square),
            onTap: () => controller.selectSquare(square),
          ),
      ],
    );
  }
}
