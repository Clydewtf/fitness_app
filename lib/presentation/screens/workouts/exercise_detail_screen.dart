import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/exercise_model.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final hasMedia = exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Если есть media — показываем, иначе заглушка
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasMedia
                  ? CachedNetworkImage(
                      imageUrl: exercise.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(height: 24),

            // 🔸 Информация об упражнении
            Text(
              exercise.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '${exercise.muscleGroup} • ${exercise.type}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            if (exercise.equipment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Оборудование: ${exercise.equipment}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 24),

            // 🔹 Заглушка под будущее описание (если планируешь)
            if (exercise.description != null && exercise.description!.isNotEmpty) ...[
              Text(
                'Описание',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.play_circle_fill, color: Colors.grey, size: 64),
      ),
    );
  }
}