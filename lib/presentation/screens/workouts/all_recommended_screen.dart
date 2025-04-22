import 'package:flutter/material.dart';
import '../../../data/models/workout_model.dart';
import '../../widgets/workouts/workout_card.dart';

class AllRecommendedScreen extends StatelessWidget {
  final List<Workout> workouts;

  const AllRecommendedScreen({super.key, required this.workouts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Все рекомендованные"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WorkoutCard(workout: workout),
          );
        },
      ),
    );
  }
}