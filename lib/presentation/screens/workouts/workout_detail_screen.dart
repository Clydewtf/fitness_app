import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/locator.dart';
import '../../../data/models/workout_model.dart';
import '../../../logic/workout_bloc/workout_bloc.dart';
import '../../../logic/workout_bloc/workout_event.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/models/exercise_model.dart';
import '../../../logic/workout_bloc/workout_state.dart';
import '../../widgets/workouts/exercise_card.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late String selectedGoal;
  Map<String, Exercise> loadedExercises = {};
  bool isLoadingExercises = true;

  @override
  void initState() {
    super.initState();
    selectedGoal = widget.workout.targetGoals.first;
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final repo = locator<ExerciseRepository>();
      final futures = widget.workout.exercises.map((we) => repo.getExerciseById(we.exerciseId));
      final results = await Future.wait(futures);

      final map = <String, Exercise>{};
      for (int i = 0; i < results.length; i++) {
        final ex = results[i];
        if (ex != null) {
          map[widget.workout.exercises[i].exerciseId] = ex;
        }
      }

      setState(() {
        loadedExercises = map;
        isLoadingExercises = false;
      });
    } catch (e) {
      print("Ошибка загрузки упражнений: $e");
      setState(() => isLoadingExercises = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutBloc, WorkoutState>(
      builder: (context, state) {
        if (state is WorkoutLoaded) {
          // Находим актуальную тренировку по ID
          final workout = state.workouts.firstWhere(
            (w) => w.id == widget.workout.id,
            orElse: () => widget.workout,
          );

          return Scaffold(
            appBar: AppBar(
              title: Text(workout.name),
              actions: [
                BlocBuilder<WorkoutBloc, WorkoutState>(
                  builder: (context, state) {
                    final isFavorite = state is WorkoutLoaded &&
                            state.favoriteWorkoutIds.contains(workout.id);

                    return IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        context.read<WorkoutBloc>().add(
                          ToggleFavoriteWorkout(workoutId: workout.id, isFavorite: !isFavorite),
                        );
                      },
                     );
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (workout.tagline != null && workout.tagline!.isNotEmpty)
                    Text(
                      workout.tagline!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                    ),
                  const SizedBox(height: 12),

                  // 🔹 Основная информация
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(workout.level, Colors.blue),
                      _chip(workout.type, Colors.deepPurple),
                      ...workout.targetGoals.map((goal) => _chip(goal, Colors.green)),
                      ...workout.muscleGroups.map((m) => _chip(m, Colors.orange)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 🔸 Описание
                  if (workout.description != null && workout.description!.isNotEmpty)
                    Text(
                      workout.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                  const SizedBox(height: 24),

                  // 🎯 Выбор цели
                  if (workout.targetGoals.length > 1) ...[
                    const Text("Выберите цель:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: workout.targetGoals.map((goal) {
                        final isSelected = goal == selectedGoal;
                        return ChoiceChip(
                          label: Text(goal),
                          selected: isSelected,
                          onSelected: (_) => setState(() => selectedGoal = goal),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (isLoadingExercises)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Упражнения", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        ...workout.exercises.map((we) {
                          final exercise = loadedExercises[we.exerciseId];
                          final mode = we.modes[selectedGoal];

                          if (exercise == null) return const Text("Упражнение не найдено");

                          return Column(
                            children: [
                              ExerciseCard(exercise: exercise),
                              if (mode != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      _infoIcon(Icons.replay, '${mode.sets} подходов'),
                                      _infoIcon(Icons.repeat, '${mode.reps} повторений'),
                                      _infoIcon(Icons.timer, '${mode.restSeconds} сек. отдыха'),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        })
                      ],
                    ),
                ],
              ),
            ),
          );
        } else if (state is WorkoutLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is WorkoutError) {
          return Center(child: Text("Ошибка: ${state.message}"));
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _chip(String text, Color color) {
    return Chip(
      label: Text(text),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _infoIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }
}