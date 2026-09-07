import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/sudoku_controller.dart';
import '../models/sudoku_board.dart';
import '../models/sudoku_player_state.dart';

class SudokuGameScreen extends StatelessWidget {
  const SudokuGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SudokuController>();
    final player = controller.currentPlayer;

    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name} oynuyor'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text('Hata: ${player.mistakeCount}/$sudokuMaxMistakes'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.count(
                    crossAxisCount: sudokuSize,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < player.values.length; i++)
                        _SudokuCellView(
                          index: i,
                          player: player,
                          selected: controller.selectedIndex == i,
                          onTap: player.given[i]
                              ? null
                              : () => controller.selectCell(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DigitPad(controller: controller),
          ],
        ),
      ),
    );
  }
}

/// Tek bir Sudoku hücresi. Kalın kenarlar yalnızca üst/sol taraftan
/// (hücrenin `row`/`col`'u 3'ün katıysa) ve ızgaranın en sağ/alt dış
/// kenarında çizilir — bu tek kural, ızgaranın hem dış çerçevesini hem her
/// 3×3 kutu sınırını çift çizgi olmadan üretir.
class _SudokuCellView extends StatelessWidget {
  const _SudokuCellView({
    required this.index,
    required this.player,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final SudokuPlayerState player;
  final bool selected;
  final VoidCallback? onTap;

  static const _thinSide = BorderSide(width: 0.5, color: Color(0xFFBDBDBD));
  static const _thickSide = BorderSide(width: 2, color: Colors.black87);
  static const _noSide = BorderSide.none;

  @override
  Widget build(BuildContext context) {
    final row = sudokuRowOf(index);
    final col = sudokuColOf(index);
    final value = player.values[index];
    final given = player.given[index];
    final wrong = value != 0 && value != player.solution[index];

    final Color background;
    if (selected) {
      background = Colors.blue.shade100;
    } else if (given) {
      background = Colors.grey.shade200;
    } else {
      background = Colors.white;
    }

    return GestureDetector(
      key: ValueKey('sudokuCell_$index'),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          border: Border(
            top: row % sudokuBoxSize == 0 ? _thickSide : _thinSide,
            left: col % sudokuBoxSize == 0 ? _thickSide : _thinSide,
            right: col == sudokuSize - 1 ? _thickSide : _noSide,
            bottom: row == sudokuSize - 1 ? _thickSide : _noSide,
          ),
        ),
        child: value == 0
            ? null
            : Text(
                '$value',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: given ? FontWeight.bold : FontWeight.w500,
                  color: wrong
                      ? Colors.red.shade700
                      : (given ? Colors.black87 : Colors.blueGrey.shade900),
                ),
              ),
      ),
    );
  }
}

class _DigitPad extends StatelessWidget {
  const _DigitPad({required this.controller});

  final SudokuController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var digit = 1; digit <= sudokuSize; digit++)
          SizedBox(
            width: 40,
            height: 40,
            child: OutlinedButton(
              key: ValueKey(digit),
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => controller.enterDigit(digit),
              child: Text('$digit'),
            ),
          ),
        SizedBox(
          width: 40,
          height: 40,
          child: OutlinedButton(
            key: const Key('sudokuEraseButton'),
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: controller.clearSelectedCell,
            child: const Icon(Icons.backspace_outlined, size: 18),
          ),
        ),
      ],
    );
  }
}
