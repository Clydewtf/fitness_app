import 'package:flutter/material.dart';
import '../../../data/models/workout_session_model.dart';

class WorkoutSummaryBottomSheet extends StatelessWidget {
  final WorkoutSession session;
  final int completed;
  final int total;
  final Duration duration;
  final void Function(int difficulty)? onDifficultySelected;
  final void Function(String mood)? onMoodSelected;
  final void Function(String comment)? onCommentChanged;
  final VoidCallback onFinish;

  const WorkoutSummaryBottomSheet({
    super.key,
    required this.session,
    required this.completed,
    required this.total,
    required this.duration,
    this.onDifficultySelected,
    this.onMoodSelected,
    this.onCommentChanged,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final timeText = "${duration.inMinutes} мин ${duration.inSeconds % 60} сек";
    final moodOptions = ['😄', '🙂', '😐', '😩', '🤒'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Тренировка завершена',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Выполнено: $completed из $total',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '⏱ $timeText',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Divider(height: 32),

          Text('Как оценишь сложность?', style: Theme.of(context).textTheme.bodyMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => onDifficultySelected?.call(index + 1),
                icon: Icon(Icons.star,
                    color: Colors.amber.shade600),
              );
            }),
          ),

          const SizedBox(height: 12),
          Text('Как самочувствие?', style: Theme.of(context).textTheme.bodyMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: moodOptions.map((mood) {
              return GestureDetector(
                onTap: () => onMoodSelected?.call(mood),
                child: Text(mood, style: const TextStyle(fontSize: 28)),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),
          TextField(
            onChanged: onCommentChanged,
            decoration: const InputDecoration(
              labelText: 'Комментарий (необязательно)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFinish,
              child: const Text('Сохранить и завершить'),
            ),
          ),
        ],
      ),
    );
  }
}