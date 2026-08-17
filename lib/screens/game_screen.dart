import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/player_state.dart';
import '../widgets/number_grid.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int? _explodingRow;
  int? _explodingCol;
  Timer? _explodeTimer;

  @override
  void dispose() {
    _explodeTimer?.cancel();
    super.dispose();
  }

  void _handleSelect(BuildContext context, int col) {
    final controller = context.read<GameController>();
    final player = controller.currentPlayer;
    final hitRow = player.currentRow;
    final result = controller.selectCell(col);
    if (result == CellSelectionResult.bomb) {
      setState(() {
        _explodingRow = hitRow;
        _explodingCol = col;
      });
      // Patlama efekti 2 saniye ekranda kaldıktan sonra işareti temizle ki
      // hücre normal (kilitli/aktif) görünümüne dönebilsin.
      _explodeTimer?.cancel();
      _explodeTimer = Timer(const Duration(milliseconds: 2000), () {
        setState(() {
          _explodingRow = null;
          _explodingCol = null;
        });
      });

      final attempts = player.attempts;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💥 Bomba! Deneme: $attempts — 1. satırdan tekrar.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final player = controller.currentPlayer;
    final theme = context.watch<AppThemeController>().current;

    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name} oynuyor'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('Deneme: ${player.attempts}')),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Satır ${player.currentRow + 1} / $rowCount',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: NumberGrid(
                  player: player,
                  onSelect: (col) => _handleSelect(context, col),
                  explodingRow: _explodingRow,
                  explodingCol: _explodingCol,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
