import 'package:flutter/material.dart';
import '../../../data/models/exercise_model.dart';
import '../../screens/workouts/exercise_detail_screen.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final primary = exercise.primaryMuscles.join(', ');
    final secondary = exercise.secondaryMuscles?.join(', ');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExerciseDetailScreen(exercise: exercise),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.fitness_center, size: 32, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        children: [
                          TextSpan(
                            text: primary,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (secondary != null && secondary.isNotEmpty) ...[
                            const TextSpan(text: ' • '),
                            TextSpan(text: secondary),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.type} • ${exercise.level}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    if (exercise.equipment.isNotEmpty)
                      Text(
                        'Оборудование: ${exercise.equipment}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    if (exercise.description != null && exercise.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          exercise.description!,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}