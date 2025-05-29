import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:fitness_app/core/locator.dart';
import 'package:fitness_app/data/repositories/workout_log_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils.dart';
import '../../../data/models/achievement_model.dart';
import '../../../data/models/body_log.dart';
import '../../../data/models/workout_log_model.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/repositories/body_log_repository.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../logic/auth_bloc/auth_state.dart';
import '../../../logic/workout_bloc/my_workout_bloc.dart';
import '../../../logic/workout_bloc/my_workout_state.dart';
import '../../../logic/workout_bloc/workout_bloc.dart';
import '../../../logic/workout_bloc/workout_state.dart';
import '../../../services/achievement_service.dart';
import '../../../services/daily_workout_service.dart';
import '../../../services/user_service.dart';
import '../../widgets/progress/achievement_card.dart';
import '../../widgets/workouts/workout_card.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image');
    if (mounted) {
      setState(() {
        _profileImagePath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyWorkoutRefreshCubit, int>(
      builder: (context, state) {
        final authState = context.watch<AuthBloc>().state;
        if (authState is! Authenticated) {
          return const Center(child: CircularProgressIndicator());
        }
        final uid = authState.user.uid;
        final workoutLogs = locator<WorkoutLogRepository>().getWorkoutLogs(uid);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // 🔝 Верхний блок с профилем
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: _GreetingBlock(),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _profileImagePath != null
                              ? FileImage(File(_profileImagePath!))
                              : null,
                          child: _profileImagePath == null
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // 📦 Остальное содержимое
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _WorkoutCardBlock(),
                      FutureBuilder<List<WorkoutLog>>(
                        future: workoutLogs,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return const Text('Ошибка загрузки логов');
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const _ReminderBlock(workoutLogs: []);
                          } else {
                            return _ReminderBlock(workoutLogs: snapshot.data!);
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      _ProgressBlock(
                        bodyLogRepository: BodyLogRepository(
                          firestore: FirebaseFirestore.instance,
                          userId: uid,
                        ),
                        userId: uid,
                        userService: locator<UserService>(),
                      ),
                      SizedBox(height: 16),
                      _GoalProgressBlock(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Приветствие
class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock();

  @override
  Widget build(BuildContext context) {
    // TODO: Получать имя пользователя
    return Text(
      'Привет, спортсмен! 👋',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// Блок тренировок
class _WorkoutCardBlock extends StatefulWidget {
  const _WorkoutCardBlock();

  @override
  State<_WorkoutCardBlock> createState() => _WorkoutCardBlockState();
}

class _WorkoutCardBlockState extends State<_WorkoutCardBlock> {
  final DailyWorkoutService _dailyWorkoutService = DailyWorkoutService();

  (Workout, bool)? _currentWorkout;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutIfReady();
  }

  void _loadWorkoutIfReady() {
    final myState = context.read<MyWorkoutBloc>().state;
    final globalState = context.read<WorkoutBloc>().state;

    if (myState is MyWorkoutLoaded && globalState is WorkoutLoaded) {
      _loadWorkout(myState, globalState);
    }
  }

  Future<void> _loadWorkout(MyWorkoutLoaded myState, WorkoutLoaded globalState) async {
    setState(() => _isLoading = true);

    final myFavorites = myState.workouts.where((w) => w.isFavorite).toList();
    final globalFavorites = globalState.workouts.where((w) => w.isFavorite).toList();

    final allFavorites = [
      ...globalFavorites.map((w) => (w, false)),
      ...myFavorites.map((w) => (w, true)),
    ];

    final todayWorkout = await _dailyWorkoutService.getCurrentWorkout(allFavorites);

    if (mounted) {
      setState(() {
        _currentWorkout = todayWorkout;
        _isLoading = false;
      });
    }
  }

  Future<void> _switchWorkout() async {
    final myState = context.read<MyWorkoutBloc>().state;
    final globalState = context.read<WorkoutBloc>().state;

    if (myState is MyWorkoutLoaded && globalState is WorkoutLoaded) {
      final myFavorites = myState.workouts.where((w) => w.isFavorite).toList();
      final globalFavorites = globalState.workouts.where((w) => w.isFavorite).toList();

      final allFavorites = [
        ...globalFavorites.map((w) => (w, false)),
        ...myFavorites.map((w) => (w, true)),
      ];

      await _dailyWorkoutService.goToNextWorkout(allFavorites);

      final nextWorkout = await _dailyWorkoutService.getCurrentWorkout(allFavorites);

      if (mounted) {
        setState(() {
          _currentWorkout = nextWorkout;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MyWorkoutBloc, MyWorkoutState>(
          listener: (_, __) => _loadWorkoutIfReady(),
        ),
        BlocListener<WorkoutBloc, WorkoutState>(
          listener: (_, __) => _loadWorkoutIfReady(),
        ),
        BlocListener<DailyWorkoutRefreshCubit, int>(
          listener: (_, __) => _loadWorkoutIfReady(),
        ),
      ],
      child: Builder(
        builder: (context) {
          if (_isLoading || _currentWorkout == null) {
            return const SizedBox.shrink();
          }

          final (workout, isMyWorkout) = _currentWorkout!;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Тренировка дня", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                WorkoutCard(
                  workout: workout,
                  isMyWorkout: isMyWorkout,
                  canToggleFavorite: false,
                ),
                Center(
                  child: TextButton.icon(
                    onPressed: _switchWorkout,
                    icon: const Icon(Icons.autorenew),
                    label: const Text("Сменить"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Ближайшая цель
class _GoalProgressBlock extends StatelessWidget {
  const _GoalProgressBlock();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AchievementCubit, List<Achievement>>(
      builder: (context, achievements) {
        final inProgress = achievements
            .where((a) => a.status != AchievementStatus.unlocked)
            .toList();

        if (inProgress.isEmpty) {
          return const _PlaceholderCard(
            icon: Icons.emoji_events,
            title: 'Все достижения выполнены',
            subtitle: 'Ты выполнил все цели!',
          );
        }

        // Найти самое близкое
        inProgress.sort((a, b) {
          final aProgress = a.current / a.goal;
          final bProgress = b.current / b.goal;
          return bProgress.compareTo(aProgress); // от большего к меньшему
        });

        final closest = inProgress.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ближайшее достижение", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            AchievementCard(achievement: closest),
          ],
        );
      },
    );
  }
}

// Советы или напоминания
class _ReminderBlock extends StatelessWidget {
  final List<WorkoutLog> workoutLogs;

  const _ReminderBlock({required this.workoutLogs});

  static const List<String> _dailyTips = [
    'Ставьте достижимые цели и отслеживайте прогресс 📈',
    'Не забывайте про разминку и заминку — это важно! 🔥',
    'Фиксация веса помогает видеть свой прогресс ⚖️',
    'Фото-прогресс мотивирует лучше, чем цифры 📸',
    'Сон и восстановление важны не меньше тренировок 🛌',
    'Лучше 3 тренировки в неделю стабильно, чем 7 раз в один день 🗓️',
    'Записывайте свои ощущения после тренировок — это помогает 📝',
    'Не перегружайтесь — регулярность важнее интенсивности 💡',
    'Добавьте любимую музыку в тренировку — это повышает мотивацию 🎧',
    'Вода — ваш лучший друг во время занятий спортом 💧',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);

    return FutureBuilder<bool>(
      future: UserSettingsStorage().getRequireWeightsInSets(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final requireWeightsInSets = snapshot.data!;
        final incompleteLog = workoutLogs.firstWhereOrNull(
          (log) => !isLogComplete(log, requireWeightsInSets: requireWeightsInSets),
        );

        final String tip = _dailyTips[now.day % _dailyTips.length];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100.withValues(alpha: 0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.16),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates, color: Colors.blueAccent, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Совет дня',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        children: [
                          if (incompleteLog != null) ...[
                            const TextSpan(
                              text: '🔔 Напоминание:\n',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              children: [
                                const TextSpan(text: 'У вас есть незаполненная тренировка от '),
                                TextSpan(
                                  text: DateFormat('dd.MM.yyyy').format(incompleteLog.date),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: '.\n\n'),
                              ],
                            ),
                          ],
                          const TextSpan(
                            text: '💡 Совет:\n',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: tip),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Прогресс
class _ProgressBlock extends StatelessWidget {
  final BodyLogRepository bodyLogRepository;
  final String userId;
  final UserService userService;

  const _ProgressBlock({
    required this.bodyLogRepository,
    required this.userId,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<bool>(
      future: UserSettingsStorage().getAutoUpdateWeight(),
      builder: (context, autoUpdateSnapshot) {
        if (!autoUpdateSnapshot.hasData) return const SizedBox.shrink();
        final autoUpdate = autoUpdateSnapshot.data!;

        return FutureBuilder<double?>(
          future: autoUpdate ? userService.getUserWeight(userId) : null,
          builder: (context, weightSnapshot) {
            final weightFromProfile = weightSnapshot.data;

            return FutureBuilder<List<BodyLog>>(
              future: bodyLogRepository.loadLogs(),
              builder: (context, logsSnapshot) {
                final logs = logsSnapshot.data ?? [];

                return FutureBuilder<String?>(
                  future: userService.getUserGoal(userId),
                  builder: (context, goalSnapshot) {
                    final goal = goalSnapshot.data;

                    // Заглушки отдельно
                    if (weightFromProfile == null && logs.isEmpty) {
                      return _buildCard(
                        theme,
                        'Прогресс веса',
                        'Укажите вес в профиле',
                        icon: Icons.info_outline,
                        trendColor: Colors.grey,
                      );
                    }

                    if (!autoUpdate && logs.isEmpty) {
                      return _buildCard(
                        theme,
                        'Прогресс веса',
                        'Нет записей веса. Завершите тренировку или добавьте вес вручную на экране прогресса',
                        icon: Icons.info_outline,
                        trendColor: Colors.grey,
                      );
                    }

                    final now = DateTime.now();
                    final targetDate = now.subtract(const Duration(days: 7));

                    // Найти ближайший лог к 7-дневной давности, начиная от нее к сегодняшнему дню
                    BodyLog? findClosestLogAfter(DateTime from, List<BodyLog> logs) {
                      return logs
                          .where((log) => log.date.isAfter(from) || log.date.isAtSameMomentAs(from))
                          .sorted((a, b) => a.date.compareTo(b.date))
                          .firstOrNull;
                    }

                    double? latestWeight;
                    BodyLog? comparisonLog;

                    if (autoUpdate) {
                      // autoUpdate включен → берем вес из профиля
                      latestWeight = weightFromProfile;
                      comparisonLog = findClosestLogAfter(targetDate, logs);
                    } else {
                      // autoUpdate выключен → вес берём из последнего лога
                      if (logs.isNotEmpty) {
                        latestWeight = logs.last.weight;
                        final logsForComparison = logs.sublist(0, logs.length - 1);
                        comparisonLog = findClosestLogAfter(targetDate, logsForComparison);
                      }
                    }

                    if (latestWeight == null) {
                      return _buildCard(
                        theme,
                        'Прогресс веса',
                        'Укажите вес в профиле',
                        icon: Icons.info_outline,
                        trendColor: Colors.grey,
                      );
                    }

                    final diff = comparisonLog != null
                        ? latestWeight - comparisonLog.weight
                        : 0.0;

                    final String diffText;
                    final IconData? trendIcon;

                    if (comparisonLog == null) {
                      diffText = '';
                      trendIcon = null;
                    } else if (diff == 0) {
                      diffText = 'без изменений';
                      trendIcon = Icons.trending_flat;
                    } else if (diff > 0) {
                      diffText = '+${diff.toStringAsFixed(1)} кг';
                      trendIcon = Icons.trending_up;
                    } else {
                      diffText = '${diff.toStringAsFixed(1)} кг';
                      trendIcon = Icons.trending_down;
                    }

                    final trendColor = getTrendColor(diff: diff, goal: goal);

                    final subtitle = comparisonLog == null
                        ? 'Последний вес: ${latestWeight.toStringAsFixed(1)} кг'
                        : 'Последний вес: ${latestWeight.toStringAsFixed(1)} кг • $diffText за 7 дней';

                    return _buildCard(
                      theme,
                      'Прогресс веса',
                      subtitle,
                      icon: trendIcon,
                      trendColor: trendColor,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCard(
    ThemeData theme,
    String title,
    String subtitle, {
    IconData? icon,
    required Color trendColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            trendColor.withValues(alpha: 0.1),
            trendColor.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: trendColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon ?? Icons.show_chart, color: trendColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color getTrendColor({
    required double diff,
    required String? goal, // цель из профиля
  }) {
    if (diff == 0 || goal == null) {
      return Colors.grey;
    }

    switch (goal.toLowerCase()) {
      case 'сушка':
        return diff < 0 ? Colors.green : Colors.red;
      case 'набор массы':
        return diff > 0 ? Colors.green : Colors.red;
      case 'поддержание формы':
      case 'сила':
      case 'выносливость':
      default:
        //return Colors.grey;
        return diff < 0 ? Colors.green : Colors.red;
    }
  }
}

// Общая карточка-заглушка
class _PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Colors.blueAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}