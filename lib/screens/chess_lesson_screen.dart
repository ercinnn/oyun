import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/chess_lesson_controller.dart';
import '../models/chess_lesson.dart';
import '../models/chess_square.dart';
import '../widgets/chess_board_view.dart';

/// Tek bir dersin ekranı: üstte adım çubuğu, ortada tahta, altta anlatım /
/// görev metni, geri bildirim ve düğmeler.
class ChessLessonScreen extends StatelessWidget {
  const ChessLessonScreen({
    super.key,
    required this.lesson,
    required this.progress,
  });

  final ChessLesson lesson;
  final ChessLessonProgress progress;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChessLessonController(lesson),
      child: _LessonBody(lesson: lesson, progress: progress),
    );
  }
}

class _LessonBody extends StatelessWidget {
  const _LessonBody({required this.lesson, required this.progress});

  final ChessLesson lesson;
  final ChessLessonProgress progress;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ChessLessonController>();
    final total = lesson.steps.length;
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (c.stepIndex + (c.solved ? 1 : 0)) / total,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardSize = [
                    constraints.maxWidth - 32,
                    constraints.maxHeight * 0.55,
                    460.0,
                  ].reduce((a, b) => a < b ? a : b);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Adım ${c.stepIndex + 1} / $total',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        if (c.hasBoard) ...[
                          SizedBox.square(
                            dimension: boardSize,
                            child: ChessBoardFrame(
                              child: _LessonBoard(controller: c),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _StepText(controller: c),
                        if (c.feedback != null) ...[
                          const SizedBox(height: 12),
                          _FeedbackCard(
                            text: c.feedback!,
                            positive: c.feedbackPositive,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _StepButtons(
                          controller: c,
                          onFinish: () async {
                            await progress.markCompleted(lesson.id);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonBoard extends StatelessWidget {
  const _LessonBoard({required this.controller});

  final ChessLessonController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final last = c.lastMove;
    final markStep = c.step is LessonMarkStep ? c.step as LessonMarkStep : null;
    return ChessBoardView(
      squares: c.board.squares,
      flipped: c.flipped,
      selectedSquare: c.selectedSquare,
      legalTargets: {for (final m in c.selectedLegalMoves) m.to},
      lastMoveSquares: last == null ? const {} : {last.from, last.to},
      checkedKingSquare: c.board.isInCheck
          ? c.board.kingSquare(c.board.sideToMove)
          : null,
      hintSquares: {
        ...c.hintSquares,
        ...c.markedSquares,
        if (markStep != null) squareFromName(markStep.pieceSquare),
      },
      onSquareTap: c.tapSquare,
    );
  }
}

class _StepText extends StatelessWidget {
  const _StepText({required this.controller});

  final ChessLessonController controller;

  @override
  Widget build(BuildContext context) {
    final step = controller.step;
    final style = Theme.of(context).textTheme.titleMedium;
    switch (step) {
      case LessonInfoStep():
        return Text(step.text, style: style);
      case LessonMoveStep():
        return Text(step.prompt, style: style);
      case LessonMarkStep():
        return Text(step.prompt, style: style);
      case LessonQuizStep():
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(step.question, style: style),
            const SizedBox(height: 8),
            for (var i = 0; i < step.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: OutlinedButton(
                  key: ValueKey('lessonOption_$i'),
                  onPressed: controller.solved
                      ? null
                      : () => controller.answerQuiz(i),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(14),
                    backgroundColor:
                        controller.solved && i == step.correctIndex
                        ? Colors.green.withValues(alpha: 0.15)
                        : controller.wrongOption == i
                        ? Colors.red.withValues(alpha: 0.12)
                        : null,
                  ),
                  child: Text(step.options[i]),
                ),
              ),
          ],
        );
    }
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.text, required this.positive});

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.green : Colors.deepOrange;
    return Container(
      key: const Key('lessonFeedback'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(positive ? Icons.check_circle : Icons.info, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StepButtons extends StatelessWidget {
  const _StepButtons({required this.controller, required this.onFinish});

  final ChessLessonController controller;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final step = c.step;
    final continueButton = FilledButton(
      key: const Key('lessonContinue'),
      onPressed: !c.solved ? null : (c.isLastStep ? onFinish : c.next),
      child: Text(c.isLastStep ? 'Dersi Bitir' : 'Devam'),
    );
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (step is LessonMoveStep && !c.solved)
          OutlinedButton.icon(
            key: const Key('lessonHint'),
            onPressed: c.showHint,
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('İpucu'),
          ),
        if (step is LessonMarkStep && !c.solved)
          FilledButton.tonal(
            key: const Key('lessonCheck'),
            onPressed: c.checkMarks,
            child: const Text('Kontrol et'),
          ),
        continueButton,
      ],
    );
  }
}
