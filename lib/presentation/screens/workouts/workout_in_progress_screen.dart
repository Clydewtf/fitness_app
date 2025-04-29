import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/locator.dart';
import '../../../core/utils.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../logic/workout_bloc/workout_session_bloc.dart';
import '../../../data/models/workout_session_model.dart';
import '../../../logic/workout_bloc/workout_session_event.dart';
import '../../../logic/workout_bloc/workout_session_state.dart';

class WorkoutInProgressScreen extends StatefulWidget {
  const WorkoutInProgressScreen({super.key});

  @override
  State<WorkoutInProgressScreen> createState() => _WorkoutInProgressScreenState();
}

class _WorkoutInProgressScreenState extends State<WorkoutInProgressScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _canSwipe(WorkoutSessionState state) {
    final current = state.currentExercise;
    if (current == null) return true; // если нет текущего - можно

    return current.status != ExerciseStatus.inProgress;
  }

  bool _isPageAnimating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: BlocConsumer<WorkoutSessionBloc, WorkoutSessionState>(
          listenWhen: (previous, current) =>
              previous.shouldAutoAdvance != current.shouldAutoAdvance &&
              current.shouldAutoAdvance,
          listener: (context, state) {
            if (state.shouldAutoAdvance && !_isPageAnimating && state.nextIndex != null) {
              final targetIndex = state.nextIndex!;
              final currentIndex = state.currentExerciseIndex;

              if (_pageController.hasClients) {
                final isCycleJump = (currentIndex == state.session!.exercises.length - 1 && targetIndex == 0);

                _isPageAnimating = true;

                if (isCycleJump) {
                  // Переход без анимации
                  _pageController.jumpToPage(targetIndex);
                  _isPageAnimating = false;
                  context.read<WorkoutSessionBloc>().add(AdvanceToIndex(targetIndex));
                  context.read<WorkoutSessionBloc>().add(ResetAutoAdvance());
                } else {
                  // Плавная анимация
                  _pageController.animateToPage(
                    targetIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ).then((_) {
                    _isPageAnimating = false;
                    context.read<WorkoutSessionBloc>().add(AdvanceToIndex(targetIndex));
                    context.read<WorkoutSessionBloc>().add(ResetAutoAdvance());
                  });
                }
              } else {
                // fallback — если не анимируется
                context.read<WorkoutSessionBloc>().add(AdvanceToIndex(targetIndex));
                context.read<WorkoutSessionBloc>().add(ResetAutoAdvance());
              }
            }
          },
          builder: (context, state) {
            final canSwipe = _canSwipe(state);
            final session = state.session;
            if (session == null) {
              return const Center(child: Text('Нет активной тренировки'));
            }

            final exercises = session.exercises;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(session: session),
                  const SizedBox(height: 20),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: canSwipe
                          ? const PageScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        context.read<WorkoutSessionBloc>().add(UpdateCurrentExerciseIndex(index));
                      },
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        return _ExerciseCard(
                          exerciseId: exercises[index].exerciseId,
                          workoutMode: exercises[index].workoutMode,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ProgressIndicator(
                    exercises: exercises,
                    currentIndex: state.currentExerciseIndex,
                  ),
                  const SizedBox(height: 20),
                  _ActionButtons(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final WorkoutSession session;
  const _Header({required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Текущая цель: ${session.goal}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _WorkoutTimer(initialDuration: session.duration),
      ],
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final String exerciseId;
  final WorkoutMode workoutMode;

  const _ExerciseCard({
    required this.exerciseId,
    required this.workoutMode,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  Exercise? _exercise;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    final exercise = await locator<ExerciseRepository>().getExerciseById(widget.exerciseId);
    if (mounted) {
      setState(() {
        _exercise = exercise;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 200, height: 24, color: Colors.white),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 16, color: Colors.white),
              const SizedBox(height: 8),
              Container(width: double.infinity, height: 16, color: Colors.white),
              const SizedBox(height: 24),
              Container(width: 150, height: 20, color: Colors.white),
            ],
          ),
        ),
      );
    }

    if (_exercise == null) {
      return const Center(child: Text('Упражнение не найдено'));
    }

    final sets = widget.workoutMode.sets;
    final reps = widget.workoutMode.reps;
    final rest = widget.workoutMode.restSeconds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _exercise!.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (_exercise!.description != null)
            Text(
              _exercise!.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 12),
          Text(
            'Подходы: $sets\nПовторы: $reps\nОтдых: $rest сек',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutSessionBloc, WorkoutSessionState>(
      buildWhen: (previous, current) {
        // перестраивать только если поменялся текущий индекс или режим отдыха
        return previous.currentExerciseIndex != current.currentExerciseIndex ||
               previous.isResting != current.isResting ||
               previous.restSecondsLeft != current.restSecondsLeft ||
               previous.currentExercise?.status != current.currentExercise?.status;
      },
      builder: (context, state) {
        final currentIndex = state.currentExerciseIndex;
        final exercise = state.currentExercise;

        if (exercise == null) return const SizedBox.shrink();

        if (state.isResting) {
          // Отдых между подходами
          final secondsLeft = state.restSecondsLeft ?? 0;
          return Column(
            children: [
              Text('Отдых: ${secondsLeft}s', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Подготовься к следующему подходу', style: Theme.of(context).textTheme.bodyMedium),
            ],
          );
        }

        switch (exercise.status) {
          case ExerciseStatus.pending:
            return Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<WorkoutSessionBloc>().add(StartExercise(currentIndex));
                    },
                    child: const Text('Начать упражнение'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<WorkoutSessionBloc>().add(SkipExercise(currentIndex));
                    },
                    child: const Text('Пропустить упражнение'),
                  ),
                ),
              ],
            );
          case ExerciseStatus.inProgress:
            return Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<WorkoutSessionBloc>().add(CompleteSet());
                    },
                    child: const Text('Завершить подход'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<WorkoutSessionBloc>().add(SkipExercise(currentIndex));
                    },
                    child: const Text('Пропустить упражнение'),
                  ),
                ),
              ],
            );
          case ExerciseStatus.done:
            return SizedBox.shrink();
          case ExerciseStatus.skipped:
            return SizedBox.shrink();
        }
      }
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final List<WorkoutExerciseProgress> exercises;
  final int currentIndex;

  const _ProgressIndicator({required this.exercises, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: exercises.asMap().entries.map((entry) {
        final index = entry.key;
        final progress = entry.value;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 32, // больше ширины для эффекта "кольца"
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Внешний кружок только если выбранный
              if (index == currentIndex)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              // Внутренний кружок
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getBackgroundColor(progress, index == currentIndex, context),
                  shape: BoxShape.circle,
                ),
                child: _getIcon(progress),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getBackgroundColor(WorkoutExerciseProgress progress, bool isCurrent, BuildContext context) {
    if (progress.status == ExerciseStatus.done) {
      return Colors.green;
    } else if (progress.status == ExerciseStatus.skipped) {
      return Colors.red;
    } else {
      return Colors.grey.shade400; // все неактивные серые
    }
  }

  Widget _getIcon(WorkoutExerciseProgress progress) {
    if (progress.status == ExerciseStatus.done) {
      return const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (progress.status == ExerciseStatus.skipped) {
      return const Icon(Icons.close, color: Colors.white, size: 16);
    } else {
      return const SizedBox.shrink();
    }
  }
}

class _WorkoutTimer extends StatefulWidget {
  final Duration initialDuration;
  const _WorkoutTimer({required this.initialDuration});

  @override
  State<_WorkoutTimer> createState() => _WorkoutTimerState();
}

class _WorkoutTimerState extends State<_WorkoutTimer> {
  late Timer _timer;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _duration += const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = _duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = _duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Text(
      'Время: $mins:$secs',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
    );
  }
}