import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/data/repositories/workout_repository.dart';
import 'package:fitness_app/services/daily_workout_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/locator.dart';
import '../../../core/utils.dart';
import '../../../data/models/exercise_model.dart';
import '../../../data/models/workout_log_model.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/repositories/body_log_repository.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/repositories/photo_progress_repository.dart';
import '../../../data/repositories/workout_log_repository.dart';
import '../../../logic/workout_bloc/my_workout_bloc.dart';
import '../../../logic/workout_bloc/my_workout_state.dart';
import '../../../logic/workout_bloc/workout_bloc.dart';
import '../../../logic/workout_bloc/workout_session_bloc.dart';
import '../../../data/models/workout_session_model.dart';
import '../../../logic/workout_bloc/workout_session_event.dart';
import '../../../logic/workout_bloc/workout_session_state.dart';
import '../../../logic/workout_bloc/workout_state.dart';
import '../../../services/achievement_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../widgets/workouts/workout_summary_bottom_sheet.dart';
import '../home/home_screen.dart';

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

    final currentIndex = context.read<WorkoutSessionBloc>().state.currentExerciseIndex;
    _pageController = PageController(initialPage: currentIndex);
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult:(didPop, result) {},
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: BlocConsumer<WorkoutSessionBloc, WorkoutSessionState>(
            listenWhen: (previous, current) =>
                previous.shouldAutoAdvance != current.shouldAutoAdvance ||
                (!previous.isWorkoutFinished && current.isWorkoutFinished) ||
                (!previous.isWorkoutAborted && current.isWorkoutAborted),
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

                      if (context.mounted) {
                        context.read<WorkoutSessionBloc>().add(AdvanceToIndex(targetIndex));
                        context.read<WorkoutSessionBloc>().add(ResetAutoAdvance());
                      }
                    });
                  }
                } else {
                  // fallback — если не анимируется
                  context.read<WorkoutSessionBloc>().add(AdvanceToIndex(targetIndex));
                  context.read<WorkoutSessionBloc>().add(ResetAutoAdvance());
                }
              }

              // <-- Показываем BottomSheet при завершении
              if (state.isWorkoutFinished) {
                final completed = state.session!.exercises.where((e) => e.status == ExerciseStatus.done).length;
                final total = state.session!.exercises.length;
                final duration = state.session!.endTime!.difference(state.session!.startTime);
                final workoutLogRepository = locator<WorkoutLogRepository>();
                final authService = locator<AuthService>();
                final dailyWorkoutService = locator<DailyWorkoutService>();
                final myWorkoutState = context.read<MyWorkoutBloc>().state;
                final workoutState = context.read<WorkoutBloc>().state;
                final cubit = locator<DailyWorkoutRefreshCubit>();

                Future.delayed(const Duration(milliseconds: 500), () {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return WorkoutSummaryBottomSheet(
                          session: state.session!,
                          completed: completed,
                          total: total,
                          duration: duration,
                          exercisesById: state.exercisesById,
                          onFinished: ({
                            int? difficulty,
                            String? mood,
                            String? comment,
                            File? photo,
                            double? weight,
                          }) async {
                            final uid = authService.getCurrentUser()?.uid;
                            if (uid == null) return;

                            final now = DateTime.now();
                            final logId = '${state.session!.workoutId}_${now.toIso8601String()}';

                            final log = WorkoutLog(
                              id: logId,
                              userId: uid,
                              workoutId: state.session!.workoutId,
                              workoutName: state.session!.workoutName,
                              goal: state.session!.goal,
                              date: now,
                              durationMinutes: duration.inMinutes,
                              difficulty: difficulty,
                              mood: mood,
                              comment: comment,
                              photoPath: photo?.path,
                              weight: weight,
                              exercises: state.session!.exercises.map((e) {
                                return ExerciseLog(
                                  id: e.exerciseId,
                                  sets: e.sets ?? List.generate(
                                    e.workoutMode.sets,
                                    (_) => ExerciseSetLog(reps: e.workoutMode.reps),
                                  ),
                                  restSeconds: e.workoutMode.restSeconds,
                                  status: e.status,
                                );
                              }).toList(),
                            );

                            await workoutLogRepository.saveWorkoutLog(log);

                            if (myWorkoutState is MyWorkoutLoaded && workoutState is WorkoutLoaded) {
                              final myFavorites = myWorkoutState.workouts.where((w) => w.isFavorite).toList();
                              final globalFavorites = workoutState.workouts.where((w) => w.isFavorite).toList();

                              final favorites = [
                                ...globalFavorites.map((w) => (w, false)),
                                ...myFavorites.map((w) => (w, true)),
                              ];

                              if (favorites.isEmpty) return;

                              await dailyWorkoutService.goToNextWorkout(favorites);
                              cubit.refresh();
                            }

                            // ⬇️ Добавим вес в BodyLog, если он указан
                            if (weight != null) {
                              final bodyLogRepo = BodyLogRepository(
                                firestore: FirebaseFirestore.instance,
                                userId: uid,
                              );

                              final autoUpdate = await UserSettingsStorage().getAutoUpdateWeight();

                              await bodyLogRepo.addOrUpdateWeightFromExternalSource(
                                weight,
                                now,
                                shouldUpdateProfile: autoUpdate,
                              );
                            }

                            // ⬇️ Обновляем ачивки
                            final workoutLogs = await WorkoutLogRepository().getWorkoutLogs(uid);
                            final photoLogs = await PhotoProgressRepository().loadEntries();
                            final bodyLogs = await BodyLogRepository(
                              firestore: FirebaseFirestore.instance,
                              userId: uid,
                            ).loadLogs();

                            await AchievementService().checkAndUpdateAchievements(
                              workoutLogs: workoutLogs,
                              photoEntries: photoLogs,
                              bodyLogs: bodyLogs,
                            );
                          },
                        );
                      },
                    );

                    await Future.delayed(const Duration(milliseconds: 150));

                    if (context.mounted) {
                      final shouldShowReminderBanner = result != true;

                      Navigator.of(context).pushAndRemoveUntil(
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 700),
                          pageBuilder: (_, __, ___) => HomeScreen(
                            showReminderBanner: shouldShowReminderBanner,
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
                            const end = Offset.zero;
                            const curve = Curves.easeOutCubic;

                            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            return SlideTransition(position: animation.drive(tween), child: child);
                          },
                        ),
                        (route) => false,
                      );
                    }
                  });
                });
              }
              
              // Если сессия обнулилась (все скипнули) → просто выходим
              if (state.isWorkoutAborted) {
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 700),
                      pageBuilder: (_, __, ___) => const HomeScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeOutCubic;
                        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        return SlideTransition(position: animation.drive(tween), child: child);
                      },
                    ),
                    (route) => false,
                  );
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
                        const SizedBox(height: 8),
                        _ProgressIndicator(
                          exercises: exercises,
                          currentIndex: state.currentExerciseIndex,
                        ),
                        // TODO: нажимаем на кружок - кидает на эту страницу
                        const SizedBox(height: 12),
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
                                isActive: exercises[index].status == ExerciseStatus.inProgress,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SafeArea(child: _ActionButtons()),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
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
        //const SizedBox(height: 8),
        WorkoutTimer(startTime: session.startTime, endTime: session.endTime),
      ],
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final String exerciseId;
  final WorkoutMode workoutMode;
  final bool isResting;
  final bool isActive;

  const _ExerciseCard({
    required this.exerciseId,
    required this.workoutMode,
    required this.isResting,
    required this.isActive,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> with TickerProviderStateMixin {
  Exercise? _exercise;
  bool _isLoading = true;

  late AnimationController _dotsController;
  late AnimationController _impulseController;

  @override
  void initState() {
    super.initState();
    _loadExercise();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _impulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _impulseController.dispose();
    super.dispose();
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

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (_, __) {
        final progress = _dotsController.value;
        final count = (progress * 3).floor() + 1;
        return Text('⏱ Выполняется${'.' * count}', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 200);
    }

    if (_exercise == null) {
      return const Center(child: Text('Упражнение не найдено'));
    }

    final sets = widget.workoutMode.sets;
    final reps = widget.workoutMode.reps;
    final rest = widget.workoutMode.restSeconds;

    return Stack(
      children: [
        // Постоянно анимированная рамка импульсов, если активно
        if (widget.isActive)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _impulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ImpulseBorderPainter(animationValue: _impulseController.value),
                );
              },
            ),
          ),
        
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 20, right: 20),
                  child: _buildDots(),
                ),
              Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 8,
                  top: widget.isActive ? 2 : 8,
                ),
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
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _exercise!.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                        ),
                      ),
                    if (_exercise!.primaryMuscles.isNotEmpty || _exercise!.secondaryMuscles?.isNotEmpty == true)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_exercise!.primaryMuscles.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.star, size: 18, color: Colors.deepOrange),
                                const SizedBox(width: 4),
                                Text('Основные мышцы', style: Theme.of(context).textTheme.labelLarge),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 3,
                              runSpacing: 2,
                              children: _exercise!.primaryMuscles
                                  .map((muscle) => Chip(
                                        label: Text(
                                          muscle,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: Colors.transparent,
                                        shape: const StadiumBorder(
                                          side: BorderSide(color: Colors.deepOrange, width: 1.2),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 6),
                          ],
                          if (_exercise!.secondaryMuscles?.isNotEmpty == true) ...[
                            Row(
                              children: [
                                const Icon(Icons.fitness_center, size: 18, color: Colors.blueGrey),
                                const SizedBox(width: 4),
                                Text('Второстепенные мышцы', style: Theme.of(context).textTheme.labelLarge),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 2,
                              runSpacing: 0,
                              children: _exercise!.secondaryMuscles!
                                  .map((muscle) => Chip(
                                        label: Text(muscle, style: const TextStyle(fontSize: 12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: Colors.transparent,
                                        shape: const StadiumBorder(
                                          side: BorderSide(color: Colors.grey, width: 1.2),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = (constraints.maxWidth - 3 * 8 - 2 * 20) / 2;

                        return Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final item in [
                              _InfoItem(icon: Icons.fitness_center, label: '$sets подходов'),
                              _InfoItem(icon: Icons.repeat, label: '$reps повторов'),
                              _InfoItem(icon: Icons.timer, label: '$rest сек отдыха'),
                            ])
                              SizedBox(
                                width: itemWidth,
                                child: item,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: widget.isResting
                        ? Align(
                            key: const ValueKey('resting_timer'),
                            alignment: Alignment.center,
                            child: _RestingTimer(totalSets: sets),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ActionButtons extends StatefulWidget {
  const _ActionButtons();

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  final ShakeController _shakeController = ShakeController();
  ExerciseStatus? _previousStatus;
  bool _isWaitingAfterRest = false;

  @override
  void dispose() {
    _shakeController.notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkoutSessionBloc, WorkoutSessionState>(
      listenWhen: (previous, current) =>
          previous.isResting == true && current.isResting == false,
      listener: (context, state) {
        setState(() {
          _isWaitingAfterRest = true;
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _isWaitingAfterRest = false;
            });
          }
        });
      },
      child: BlocBuilder<WorkoutSessionBloc, WorkoutSessionState>(
        buildWhen: (previous, current) =>
            previous.currentExerciseIndex != current.currentExerciseIndex ||
            previous.isResting != current.isResting ||
            previous.restSecondsLeft != current.restSecondsLeft ||
            previous.currentExercise?.status != current.currentExercise?.status,
        builder: (context, state) {
          final currentIndex = state.currentExerciseIndex;
          final exercise = state.currentExercise;

          if (exercise == null || state.isResting || _isWaitingAfterRest) {
            return const SizedBox.shrink();
          }

          final status = exercise.status;

          if (_previousStatus != ExerciseStatus.inProgress &&
              status == ExerciseStatus.inProgress) {
            Future.microtask(() {
              _shakeController.shake();
            });
          }

          _previousStatus = status;

          Widget buildButtonGroup({required List<Widget> buttons}) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: buttons
                  .map((btn) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: btn,
                      ))
                  .toList(),
            );
          }

          switch (status) {
            case ExerciseStatus.pending:
              return buildButtonGroup(
                buttons: [
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<WorkoutSessionBloc>()
                          .add(StartExercise(currentIndex));
                    },
                    child: const Text('Начать упражнение'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      context
                          .read<WorkoutSessionBloc>()
                          .add(SkipExercise(currentIndex));
                    },
                    child: const Text('Пропустить'),
                  ),
                ],
              );

            case ExerciseStatus.inProgress:
              return buildButtonGroup(
                buttons: [
                  ShakeWidget(
                    controller: _shakeController,
                    child: ElevatedButton(
                      onPressed: () {
                        context
                            .read<WorkoutSessionBloc>()
                            .add(CompleteSet());
                      },
                      child: const Text('Завершить подход'),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      context
                          .read<WorkoutSessionBloc>()
                          .add(SkipExercise(currentIndex));
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
      ),
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
                  width: 100,
                  height: 100,
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
        const SizedBox(height: 12),
        Text(
          'Отдых между подходами',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          'Подготовься к следующему упражнению',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),

        // Прогресс по подходам
        Text(
          'Подход $currentSet из $totalSets',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),

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

class WorkoutTimer extends StatefulWidget {
  final DateTime startTime;
  final DateTime? endTime;
  final TextStyle? textStyle;
  const WorkoutTimer({
    required this.startTime,
    required this.endTime,
    this.textStyle,
    super.key,
  });

  @override
  State<WorkoutTimer> createState() => _WorkoutTimerState();
}

class _WorkoutTimerState extends State<WorkoutTimer> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Таймер только для обновления UI каждую секунду
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.endTime == null && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Duration get _duration {
    final now = widget.endTime ?? DateTime.now();
    return now.difference(widget.startTime);
  }

  @override
  Widget build(BuildContext context) {
    final mins = _duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = _duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Text(
      'Время: $mins:$secs',
      style: widget.textStyle ??
          Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
    );
  }
}