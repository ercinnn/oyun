import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/player_state.dart';
import 'grid_cell.dart';

const double _spacing = 6;
const double _minCellSize = 28;
const double _maxCellSize = 72;

class NumberGrid extends StatelessWidget {
  const NumberGrid({
    super.key,
    required this.player,
    required this.onSelect,
    this.explodingRow,
    this.explodingCol,
  });

  final PlayerState player;
  final void Function(int col) onSelect;

  /// Az önce bombaya basılan hücrenin konumu (varsa); yalnızca bu hücre
  /// patlama animasyonunu oynatır.
  final int? explodingRow;
  final int? explodingCol;

  CellVisualState _stateFor(int row, int col) {
    if (row < player.currentRow) {
      final wasClearedHere = player.streakClearedCols[row] == col;
      return wasClearedHere ? CellVisualState.cleared : CellVisualState.locked;
    }
    if (row == player.currentRow) return CellVisualState.active;
    return CellVisualState.locked;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 10 satırın tamamı ekrana sığacak şekilde hücre boyutunu yükseklikten,
        // taşmayı önlemek için genişlikten de sınırlandırarak hesapla.
        final cellSizeFromHeight =
            (constraints.maxHeight - (rowCount - 1) * _spacing) / rowCount;
        final cellSizeFromWidth =
            (constraints.maxWidth - (colCount - 1) * _spacing) / colCount;
        final cellSize = math
            .min(cellSizeFromHeight, cellSizeFromWidth)
            .clamp(_minCellSize, _maxCellSize)
            .toDouble();

        final gridWidth = cellSize * colCount + _spacing * (colCount - 1);
        final gridHeight = cellSize * rowCount + _spacing * (rowCount - 1);

        return Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: gridWidth,
              height: gridHeight,
              child: Column(
                children: [
                  for (var row = 0; row < rowCount; row++) ...[
                    if (row > 0) SizedBox(height: _spacing),
                    SizedBox(
                      height: cellSize,
                      child: Row(
                        children: [
                          for (var col = 0; col < colCount; col++) ...[
                            if (col > 0) SizedBox(width: _spacing),
                            SizedBox(
                              width: cellSize,
                              height: cellSize,
                              child: GridCell(
                                number: row * colCount + col + 1,
                                state: _stateFor(row, col),
                                onTap: row == player.currentRow
                                    ? () => onSelect(col)
                                    : null,
                                exploding:
                                    row == explodingRow &&
                                    col == explodingCol,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
