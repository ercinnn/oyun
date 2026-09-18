import 'package:flutter/material.dart';

import '../controllers/chess_lesson_controller.dart';
import '../data/chess_lesson_catalog.dart';
import '../models/chess_lesson.dart';
import 'chess_lesson_screen.dart';

/// Seviyelere ayrılmış ders listesi. Tamamlanan dersler işaretlenir; sıra
/// zorunlu değil, her ders istenen zaman açılabilir.
class ChessLessonListScreen extends StatefulWidget {
  const ChessLessonListScreen({super.key});

  @override
  State<ChessLessonListScreen> createState() => _ChessLessonListScreenState();
}

class _ChessLessonListScreenState extends State<ChessLessonListScreen> {
  final _progress = ChessLessonProgress();

  @override
  void initState() {
    super.initState();
    _progress.load();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Satranç Dersleri')),
      body: ListenableBuilder(
        listenable: _progress,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final level in ChessLessonLevel.values) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    level.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                for (final lesson in chessLessons.where(
                  (l) => l.level == level,
                ))
                  Card(
                    child: ListTile(
                      key: ValueKey('lesson_${lesson.id}'),
                      title: Text(lesson.title),
                      subtitle: Text(lesson.summary),
                      trailing: _progress.completed.contains(lesson.id)
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChessLessonScreen(
                            lesson: lesson,
                            progress: _progress,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
