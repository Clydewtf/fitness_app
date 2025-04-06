import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/exercise_model.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final hasImages = exercise.imageUrls != null && exercise.imageUrls!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Галерея изображений
            if (hasImages)
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: exercise.imageUrls!.length,
                  itemBuilder: (context, index) {
                    final url = exercise.imageUrls![index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, _) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, _, __) => _placeholder(),
                      ),
                    );
                  },
                ),
              )
            else
              _placeholder(),
            const SizedBox(height: 24),

            // 🔸 Название
            Text(
              exercise.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

             // 🔸 Мышцы
            Text(
              _formatMuscles(exercise),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),

            // 🔸 Тип, уровень
            const SizedBox(height: 8),
            Text(
              '${exercise.type} • ${exercise.level}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),

            // 🔸 Оборудование
            if (exercise.equipment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Оборудование: ${exercise.equipment}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],

            // 🔹 Краткое описание
            if (exercise.description != null && exercise.description!.isNotEmpty) ...[
              const SizedBox(height: 24),
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

            // 🔹 Подробные инструкции
            if (exercise.instructions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Инструкции',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...exercise.instructions.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(child: Text(step, style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ),
                  )),
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

  String _formatMuscles(Exercise e) {
    final primary = e.primaryMuscles.join(', ');
    final secondary = e.secondaryMuscles?.join(', ');
    if (secondary == null || secondary.isEmpty) return primary;
    return '$primary • $secondary';
  }
}