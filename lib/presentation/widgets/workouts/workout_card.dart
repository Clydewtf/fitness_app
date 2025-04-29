import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/locator.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../logic/auth_bloc/auth_state.dart';
import '../../../logic/workout_bloc/exercise_bloc.dart';
import '../../../logic/workout_bloc/my_workout_event.dart';
import '../../../logic/workout_bloc/my_workout_state.dart';
import '../../../logic/workout_bloc/workout_bloc.dart';
import '../../../logic/workout_bloc/my_workout_bloc.dart';
import '../../../logic/workout_bloc/workout_session_bloc.dart';
import '../../../data/models/workout_model.dart';
import '../../../logic/workout_bloc/workout_event.dart';
import '../../../logic/workout_bloc/workout_session_event.dart';
import '../../../logic/workout_bloc/workout_state.dart';
import '../../screens/workouts/workout_detail_screen.dart';
import '../../screens/workouts/workout_in_progress_screen.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final bool isMyWorkout;

  const WorkoutCard({
    super.key,
    required this.workout,
    this.isMyWorkout = false,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<WorkoutBloc>()),
                    BlocProvider.value(value: context.read<MyWorkoutBloc>()),
                    BlocProvider.value(value: context.read<ExerciseBloc>()),
                  ],
                  child: WorkoutDetailScreen(
                    workout: workout,
                    isMyWorkout: isMyWorkout,
                  ),
                ),
              ),
            );
          },
          child: Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Название + избранное
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          workout.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),                  
                      isMyWorkout
                        ? BlocBuilder<MyWorkoutBloc, MyWorkoutState>(
                            builder: (context, state) {
                              final isFavorite = workout.isFavorite;
                              return IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: Colors.amber,
                                ),
                                onPressed: () {
                                  context.read<MyWorkoutBloc>().add(
                                    ToggleFavoriteMyWorkout(
                                      uid: authState.user.uid,
                                      workoutId: workout.id,
                                      isFavorite: !isFavorite,
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        : BlocBuilder<WorkoutBloc, WorkoutState>(
                            builder: (context, state) {
                              final isFavorite = state is WorkoutLoaded &&
                                  state.favoriteWorkoutIds
                                      .contains(workout.id);
                              return IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: Colors.amber,
                                ),
                                onPressed: () {
                                  context.read<WorkoutBloc>().add(
                                    ToggleFavoriteWorkout(
                                      workoutId: workout.id,
                                      isFavorite: !isFavorite,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 🔸 Время • Уровень • Кол-во упражнений
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${workout.duration} мин', style: _infoStyle(context)),

                      const SizedBox(width: 12),
                      _buildLevelIndicator(workout.level, context),

                      const SizedBox(width: 12),
                      Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${workout.exercises.length} упр.', style: _infoStyle(context)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 🔸 Тип • Цели • Мышцы
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _chip(workout.type, Colors.blue[50], Colors.blue),
                      ...workout.targetGoals.map((goal) => _chip(goal, Colors.green[50], Colors.green)),
                      ...workout.muscleGroups.take(2).map((m) => _chip(m, Colors.orange[50], Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 🔹 Мини-описание (tagline)
                  if (workout.tagline != null && workout.tagline!.isNotEmpty)
                    Text(
                      workout.tagline!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                    ),
                ],
              ),
            ),
          ),
        ),

        // 🟢 Кнопка "Play"
        Positioned(
          bottom: 16,
          right: 24,
          child: FloatingActionButton(
            backgroundColor: Colors.green,
            mini: true,
            elevation: 4,
            onPressed: () => _handleStartPressed(context),
            child: const Icon(Icons.play_arrow_rounded, size: 28),
          ),
        ),
      ]
    );
  }

  Widget _chip(String text, Color? bg, Color? fg) {
    return Chip(
      label: Text(text),
      backgroundColor: bg,
      labelStyle: TextStyle(color: fg),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildLevelIndicator(String level, BuildContext context) {
    final levelColor = switch (level.toLowerCase()) {
      'новичок' => Colors.green,
      'средний' => Colors.orange,
      'продвинутый' => Colors.red,
      _ => Colors.grey,
    };

    return Row(
      children: [
        Icon(Icons.bar_chart, size: 16, color: levelColor),
        const SizedBox(width: 4),
        Text(level, style: _infoStyle(context)?.copyWith(color: levelColor)),
      ],
    );
  }

  TextStyle? _infoStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700],);
  }

  void _handleStartPressed(BuildContext context) {
    if (workout.targetGoals.length <= 1) {
      final goal = workout.targetGoals.first;
      _navigateToSessionScreen(context, goal);
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => ListView(
          shrinkWrap: true,
          children: workout.targetGoals.map((goal) {
            return ListTile(
              title: Text(goal),
              onTap: () {
                Navigator.pop(context);
                _navigateToSessionScreen(context, goal);
              },
            );
          }).toList(),
        ),
      );
    }
  }

  void _navigateToSessionScreen(BuildContext context, String goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => WorkoutSessionBloc()..add(StartWorkoutSession(workout, goal)),
          child: const WorkoutInProgressScreen(),
        ),
      ),
    );
  }
}