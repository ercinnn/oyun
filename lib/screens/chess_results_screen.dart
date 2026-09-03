import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/chess_controller.dart';
import '../models/chess_mode.dart';
import '../models/chess_outcome.dart';
import '../models/chess_piece.dart';

class ChessResultsScreen extends StatelessWidget {
  const ChessResultsScreen({super.key});

  String _headline(ChessController c) {
    if (c.outcome == ChessOutcome.draw) return 'Berabere!';
    if (c.mode == ChessMode.vsAi) {
      final humanWon =
          (c.outcome == ChessOutcome.whiteWins &&
              c.humanColor == PieceColor.white) ||
          (c.outcome == ChessOutcome.blackWins &&
              c.humanColor == PieceColor.black);
      return humanWon ? 'Tebrikler, kazandın!' : 'Bilgisayar kazandı.';
    }
    final winnerName = c.outcome == ChessOutcome.whiteWins
        ? c.whiteName
        : c.blackName;
    return '$winnerName kazandı!';
  }

  String _reasonText(ChessOutcomeReason? reason) {
    return switch (reason) {
      ChessOutcomeReason.checkmate => 'Şah mat.',
      ChessOutcomeReason.stalemate => 'Pat.',
      ChessOutcomeReason.fiftyMoveRule => '50 hamle kuralı.',
      ChessOutcomeReason.repetition => 'Üç kez tekrar.',
      ChessOutcomeReason.insufficientMaterial => 'Yetersiz taş.',
      null => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChessController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sonuçlar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(height: 12),
                Text(
                  _headline(controller),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _reasonText(controller.outcomeReason),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: controller.restart,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Text('Tekrar Oyna'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
