import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:collection/collection.dart';
import '../../../core/locator.dart';
import '../../../core/utils.dart';
import '../../../data/repositories/workout_log_repository.dart';
import '../../../logic/progress_bloc/progress_cubit.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../widgets/progress/recent_workout_card.dart';
import '../../widgets/progress/workout_log_dialog.dart';
import 'achievements_screen.dart';
import 'all_workout_logs_screen.dart';
import 'exercise_progress_screen.dart';
import 'photo_progress_screen.dart';
import 'weight_progress_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = locator<AuthService>().getCurrentUser()?.uid;

    return BlocProvider(
      create: (_) => WorkoutLogCubit(
        repository: locator<WorkoutLogRepository>(),
        userId: userId!,
      )..loadLogs(),
      child: const _ProgressContent(),
    );
  }
}

class _ProgressContent extends StatefulWidget {
  const _ProgressContent();

  @override
  State<_ProgressContent> createState() => _ProgressContentState();
}

class _ProgressContentState extends State<_ProgressContent> {
  bool requireWeightsInSets = true;
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = UserSettingsStorage();
    final value = await settings.getRequireWeightsInSets();
    setState(() {
      requireWeightsInSets = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutLogCubit, WorkoutLogState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = state.logs;

        final totalWorkouts = logs.length;
        final avgDuration = logs.isEmpty
            ? 0
            : (logs.map((e) => e.durationMinutes).reduce((a, b) => a + b) /
                    logs.length)
                .round();
        final totalExercises = logs.fold<int>(
          0,
          (sum, log) => sum + log.exercises.length,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Твоя статистика',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatCard(title: 'Тренировок', value: '$totalWorkouts'),
                  StatCard(title: 'Минут в среднем', value: '$avgDuration'),
                  StatCard(title: 'Упражнений', value: '$totalExercises'),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Календарь активности',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, size: 20),
                    tooltip: 'Что значит иконки?',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Обозначения'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Row(
                                  children: [
                                    Icon(Icons.fitness_center, size: 18, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('– выполненная тренировка'),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.fitness_center, size: 18, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('– не заполнена полностью'),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Ок'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: DateTime.now(),
                //selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDay = selected;
                    focusedDay = focused;
                  });

                  final log = logs.firstWhereOrNull((log) =>
                      log.date.year == selected.year &&
                      log.date.month == selected.month &&
                      log.date.day == selected.day);

                  if (log != null) {
                    showWorkoutLogDialog(context, log);
                  }
                },
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                availableGestures: AvailableGestures.horizontalSwipe,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  // selectedDecoration: const BoxDecoration(
                  //   color: Colors.green,
                  //   shape: BoxShape.circle,
                  // ),
                  markerDecoration: const BoxDecoration(),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, date, _) {
                    final log = logs.firstWhereOrNull((log) =>
                        log.date.year == date.year &&
                        log.date.month == date.month &&
                        log.date.day == date.day);

                    return Stack(
                      children: [
                        Center(
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        if (log != null)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Icon(
                              Icons.fitness_center,
                              size: 14,
                              color: isLogComplete(log, requireWeightsInSets: requireWeightsInSets)
                                ? Colors.blue : Colors.orange,
                            ),
                          ),
                      ],
                    );
                  },
                  todayBuilder: (context, date, _) {
                    final log = logs.firstWhereOrNull((log) =>
                        log.date.year == date.year &&
                        log.date.month == date.month &&
                        log.date.day == date.day);

                    return Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${date.day}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        if (log != null)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Icon(
                              Icons.fitness_center,
                              size: 14,
                              color: isLogComplete(log, requireWeightsInSets: requireWeightsInSets)
                                ? Colors.blue : Colors.orange,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // const Text(
              //   'Недавние тренировки',
              //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Недавние тренировки',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AllWorkoutLogsScreen()),
                      );
                    },
                    child: const Text('Все'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ...logs.take(3).map((log) {
                final dateFormatted = DateFormat('d MMMM yyyy, HH:mm', 'ru').format(log.date);
                final isComplete = isLogComplete(log, requireWeightsInSets: requireWeightsInSets);

                return RecentWorkoutCard(
                  title: log.workoutName,
                  date: dateFormatted,
                  duration: '${log.durationMinutes} мин',
                  isIncomplete: !isComplete,
                  onTap: () => showWorkoutLogDialog(context, log),
                );
              }),
              const SizedBox(height: 24),

              const Text(
                'Другие разделы',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: () {
                  final userId = locator<AuthService>().getCurrentUser()?.uid;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => WorkoutLogCubit(
                          repository: locator<WorkoutLogRepository>(),
                          userId: userId!,
                        )..loadLogs(),
                        child: const ExerciseProgressScreen(),
                      ),
                    ),
                  );
                },
                child: const Text('📈 Прогресс упражнений'),
              ),
              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PhotoProgressWrapper()),
                  );
                },
                child: const Text('🖼️ Фото-прогресс'),
              ),
              const SizedBox(height: 8),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeightScreen()),
                  );
                },
                child: const Text('⚖️ Вес и тело'),
              ),
              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                  );
                },
                child: const Text('🏅 Достижения'),
              ),
            ],
          ),
        );
      },
    );
  }
}