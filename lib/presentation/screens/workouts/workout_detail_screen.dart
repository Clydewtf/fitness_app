import 'package:fitness_app/presentation/screens/workouts/workout_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/locator.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/repositories/my_workout_repository.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../logic/auth_bloc/auth_state.dart';
import '../../../logic/workout_bloc/my_workout_bloc.dart';
import '../../../logic/workout_bloc/my_workout_event.dart';
import '../../../logic/workout_bloc/my_workout_state.dart';
import '../../../logic/workout_bloc/workout_bloc.dart';
import '../../../logic/workout_bloc/workout_event.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/models/exercise_model.dart';
import '../../../logic/workout_bloc/workout_state.dart';
import '../../../services/auth_service.dart';
import '../../widgets/workouts/exercise_card.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;
  final bool isMyWorkout;

  const WorkoutDetailScreen({
    super.key,
    required this.workout,
    this.isMyWorkout = false,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late Workout workoutA;
  late String selectedGoal;
  Map<String, Exercise> loadedExercises = {};
  bool isLoadingExercises = true;

  @override
  void initState() {
    super.initState();
    workoutA = widget.workout;
    selectedGoal = workoutA.targetGoals.first;
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final repo = locator<ExerciseRepository>();
      final futures = workoutA.exercises.map((we) => repo.getExerciseById(we.exerciseId));
      final results = await Future.wait(futures);

      final map = <String, Exercise>{};
      for (int i = 0; i < results.length; i++) {
        final ex = results[i];
        if (ex != null) {
          map[workoutA.exercises[i].exerciseId] = ex;
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
      builder: (context, workoutState) {
        return BlocBuilder<MyWorkoutBloc, MyWorkoutState>(
          builder: (context, myWorkoutState) {
            if (workoutState is WorkoutLoaded) {
              // Находим актуальную тренировку по ID
              final workout = workoutState.workouts.firstWhere(
                (w) => w.id == workoutA.id,
                orElse: () => workoutA,
              );

              final isFavorite = widget.isMyWorkout
                  ? (myWorkoutState is MyWorkoutLoaded &&
                      myWorkoutState.favoriteWorkoutIds.contains(workout.id))
                  : workoutState.favoriteWorkoutIds.contains(workout.id);

              return Scaffold(
                appBar: AppBar(
                  title: Text(workoutA.name),
                  actions: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        final authState = context.read<AuthBloc>().state;

                        if (widget.isMyWorkout) {
                          if (authState is Authenticated) {
                            context.read<MyWorkoutBloc>().add(
                              ToggleFavoriteMyWorkout(
                                uid: authState.user.uid,
                                workoutId: workout.id,
                                isFavorite: !isFavorite,
                              ),
                            );
                          }
                        } else {
                          context.read<WorkoutBloc>().add(
                            ToggleFavoriteWorkout(
                              workoutId: workout.id,
                              isFavorite: !isFavorite,
                            ),
                          );
                        }
                      },
                    )
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
                            }),
                            if (widget.isMyWorkout) ...[
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final uid = AuthService().getCurrentUser()?.uid;
                                      if (uid == null) return;

                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateWorkoutScreen(existingWorkout: workout),
                                        ),
                                      );

                                      if (result != null && context.mounted) {
                                        final updatedWorkout = await locator<MyWorkoutRepository>().fetchMyWorkouts(uid).then(
                                          (workouts) => workouts.firstWhere(
                                            (w) => w.id == workout.id,
                                          ),
                                        );

                                        setState(() {
                                          workoutA = updatedWorkout;
                                          selectedGoal = updatedWorkout.targetGoals.first;
                                        });
                                        _loadExercises(); // перезагрузка упражнений, если что-то поменялось
                                      
                                        context.read<MyWorkoutBloc>().add(LoadMyWorkouts(uid));
                                      }
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text("Редактировать"),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Удалить тренировку?"),
                                          content: const Text("Это действие нельзя отменить."),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text("Отмена"),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text("Удалить", style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (!mounted) return;

                                      if (confirmed == true) {
                                        final authState = context.read<AuthBloc>().state;

                                        if (authState is Authenticated) {
                                          final uid = authState.user.uid;
                                          context.read<MyWorkoutBloc>().add(DeleteMyWorkout(uid, workout.id));
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.delete),
                                    label: const Text("Удалить"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              );
            } else if (workoutState is WorkoutLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (workoutState is WorkoutError) {
              return Center(child: Text("Ошибка: ${workoutState.message}"));
            } else {
              return const SizedBox.shrink();
            }
          },
        );
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