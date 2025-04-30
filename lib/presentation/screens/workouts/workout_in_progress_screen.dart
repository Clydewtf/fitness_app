import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/locator.dart';
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
              // TODO: потом сделать чтобы при листании на последнем, кидало с анимкой на первый (фейк страницы добавить)
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
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(session: session),
                      const SizedBox(height: 20),
                      _ProgressIndicator(
                        exercises: exercises,
                        currentIndex: state.currentExerciseIndex,
                      ),
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
                              isResting: state.isResting,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SafeArea(child: _ActionButtons()), // Кнопки всегда снизу, с отступом
                    ],
                  ),

                  // Если отдых, покажем таймер по центру
                  // AnimatedSwitcher(
                  //   duration: const Duration(milliseconds: 400),
                  //   switchInCurve: Curves.easeOut,
                  //   switchOutCurve: Curves.easeIn,
                  //   transitionBuilder: (child, animation) {
                  //     return FadeTransition(
                  //       opacity: animation,
                  //       child: ScaleTransition(
                  //         scale: animation,
                  //         child: child,
                  //       ),
                  //     );
                  //   },
                  //   child: state.isResting
                  //       ? const Align(
                  //           key: ValueKey('resting_timer'), // обязательный ключ для AnimatedSwitcher
                  //           alignment: Alignment.center,
                  //           child: _RestingTimer(),
                  //         )
                  //       : const SizedBox.shrink(key: ValueKey('empty')), // обязательный ключ
                  // ),
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
        _WorkoutTimer(startTime: session.startTime),
      ],
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final String exerciseId;
  final WorkoutMode workoutMode;
  final bool isResting;

  const _ExerciseCard({
    required this.exerciseId,
    required this.workoutMode,
    required this.isResting,
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

  void _showInstructions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final instructions = _exercise!.instructions;
        final images = _exercise!.imageUrls ?? [];

        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Инструкция', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (images.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                          ),
                        );
                      },
                    ),
                  ),
                if (images.isNotEmpty) const SizedBox(height: 16),
                if (instructions.isNotEmpty)
                  ...instructions.map(
                    (step) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• $step', style: Theme.of(context).textTheme.bodyLarge),
                    ),
                  )
                else
                  const Text('Инструкция недоступна'),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: SizedBox.shrink()),
      );
    }

    if (_exercise == null) {
      return const Center(child: Text('Упражнение не найдено'));
    }

    final sets = widget.workoutMode.sets;
    final reps = widget.workoutMode.reps;
    final rest = widget.workoutMode.restSeconds;
    // final image = _exercise!.imageUrls?.isNotEmpty == true ? _exercise!.imageUrls!.first : null;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (image != null)
          //   SizedBox(
          //     width: double.infinity,
          //     height: 180,
          //     child: Image.network(image, fit: BoxFit.cover),
          //   ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _exercise!.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      tooltip: 'Инструкция',
                      onPressed: _showInstructions,
                    ),
                  ],
                ),
                if (_exercise!.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 12),
                    child: Text(
                      _exercise!.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                    ),
                  ),
                if (_exercise!.primaryMuscles.isNotEmpty == true || _exercise!.secondaryMuscles?.isNotEmpty == true)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_exercise!.primaryMuscles.isNotEmpty == true) ...[
                        Row(
                          children: [
                            const Icon(Icons.star, size: 18, color: Colors.deepOrange),
                            const SizedBox(width: 6),
                            Text('Основные мышцы', style: Theme.of(context).textTheme.labelLarge),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _exercise!.primaryMuscles.map(
                            (muscle) => Chip(
                              label: Text(
                                muscle,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.transparent,
                              shape: const StadiumBorder(
                                side: BorderSide(
                                  color: Colors.deepOrange,
                                  width: 1,
                                ),
                              ),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 0,
                              clipBehavior: Clip.antiAlias,
                            )
                          ).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_exercise!.secondaryMuscles?.isNotEmpty == true) ...[
                        Row(
                          children: [
                            const Icon(Icons.fitness_center, size: 18, color: Colors.blueGrey),
                            const SizedBox(width: 6),
                            Text('Второстепенные мышцы', style: Theme.of(context).textTheme.labelLarge),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _exercise!.secondaryMuscles!.map(
                            (muscle) => Chip(
                              label: Text(muscle),
                              backgroundColor: Colors.transparent,
                              shape: const StadiumBorder(
                                side: BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 0,
                              clipBehavior: Clip.antiAlias,
                            )
                          ).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoItem(icon: Icons.fitness_center, label: '$sets подходов'),
                    _InfoItem(icon: Icons.repeat, label: '$reps повторов'),
                    _InfoItem(icon: Icons.timer, label: '$rest сек отдыха'),
                  ],
                ),
              ],
            ),
          ),

          // Нижняя часть с таймером (заполняет всё оставшееся место)
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: widget.isResting
                    ? Align(
                        key: ValueKey('resting_timer'), // обязательный ключ для AnimatedSwitcher
                        alignment: Alignment.center,
                        child: _RestingTimer(totalSets: sets),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')), // обязательный ключ
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutSessionBloc, WorkoutSessionState>(
      buildWhen: (previous, current) {
        return previous.currentExerciseIndex != current.currentExerciseIndex ||
               previous.isResting != current.isResting ||
               previous.restSecondsLeft != current.restSecondsLeft ||
               previous.currentExercise?.status != current.currentExercise?.status;
      },
      builder: (context, state) {
        final currentIndex = state.currentExerciseIndex;
        final exercise = state.currentExercise;

        if (exercise == null) return const SizedBox.shrink();

        if (state.isResting) return const SizedBox.shrink();

        Widget buildButtonGroup({required List<Widget> buttons}) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...buttons.map((btn) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: btn,
              )),
            ],
          );
        }

        switch (exercise.status) {
          case ExerciseStatus.pending:
            return buildButtonGroup(
              buttons: [
                ElevatedButton(
                  onPressed: () {
                    context.read<WorkoutSessionBloc>().add(StartExercise(currentIndex));
                  },
                  child: const Text('Начать упражнение'),
                ),
                OutlinedButton(
                  onPressed: () {
                    context.read<WorkoutSessionBloc>().add(SkipExercise(currentIndex));
                  },
                  child: const Text('Пропустить'),
                ),
              ],
            );
          case ExerciseStatus.inProgress:
            return buildButtonGroup(
              buttons: [
                ElevatedButton(
                  onPressed: () {
                    context.read<WorkoutSessionBloc>().add(CompleteSet());
                  },
                  child: const Text('Завершить подход'),
                ),
                OutlinedButton(
                  onPressed: () {
                    context.read<WorkoutSessionBloc>().add(SkipExercise(currentIndex));
                  },
                  child: const Text('Пропустить'),
                ),
              ],
            );
          case ExerciseStatus.done:
          case ExerciseStatus.skipped:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

class _RestingTimer extends StatefulWidget {
  final int totalSets;

  const _RestingTimer({required this.totalSets});

  @override
  State<_RestingTimer> createState() => _RestingTimerState();
}

class _RestingTimerState extends State<_RestingTimer> {
  int _lastSecondsLeft = -1;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WorkoutSessionBloc>().state;
    final totalSeconds = state.restDurationSeconds ?? 30;
    final secondsLeft = state.restSecondsLeft ?? 0;

    final currentSet = state.currentSetIndex;
    final totalSets = widget.totalSets;

    // Вибрация при 3 секундах и меньше, только один раз
    if (secondsLeft <= 3 && secondsLeft != _lastSecondsLeft) {
      _lastSecondsLeft = secondsLeft;
      HapticFeedback.mediumImpact(); // можно заменить на `lightImpact()` или `vibrate()`
    }

    final progress = secondsLeft / totalSeconds;

    final color = _getColor(secondsLeft, totalSeconds, context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(
                  '$secondsLeft',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Отдых между подходами',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          'Подготовься к следующему упражнению',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Прогресс по подходам
        Text(
          'Подход $currentSet из $totalSets',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: LinearProgressIndicator(
            value: totalSets > 0 ? currentSet / totalSets : 0,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrange),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }

  Color _getColor(int secondsLeft, int total, BuildContext context) {
    final percent = secondsLeft / total;

    if (percent > 0.6) return Colors.green;
    if (percent > 0.3) return Colors.orange;
    return Colors.red;
  }
}

class _ProgressIndicator extends StatelessWidget {
  final List<WorkoutExerciseProgress> exercises;
  final int currentIndex;

  const _ProgressIndicator({required this.exercises, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: exercises.asMap().entries.map((entry) {
        final index = entry.key;
        final progress = entry.value;
        final isCurrent = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isCurrent ? 32 : 24,
          height: isCurrent ? 32 : 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isCurrent)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              Container(
                width: isCurrent ? 24 : 20,
                height: isCurrent ? 24 : 20,
                decoration: BoxDecoration(
                  color: _getBackgroundColor(progress, theme),
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: _getIcon(progress),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getBackgroundColor(WorkoutExerciseProgress progress, ThemeData theme) {
    switch (progress.status) {
      case ExerciseStatus.done:
        return Colors.green;
      case ExerciseStatus.skipped:
        return Colors.red;
      default:
        return theme.colorScheme.onSurface.withValues(alpha: 0.2);
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
  final DateTime startTime;
  const _WorkoutTimer({required this.startTime});

  @override
  State<_WorkoutTimer> createState() => _WorkoutTimerState();
}

class _WorkoutTimerState extends State<_WorkoutTimer> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Таймер только для обновления UI каждую секунду
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Duration get _duration => DateTime.now().difference(widget.startTime);

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