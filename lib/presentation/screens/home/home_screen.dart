import 'package:fitness_app/data/repositories/photo_progress_repository.dart';
import 'package:fitness_app/services/daily_workout_service.dart';
import 'package:flutter/material.dart';
import '../../../core/locator.dart';
import '../../../data/models/workout_session_model.dart';
import '../../../data/repositories/my_workout_repository.dart';
import '../../../data/repositories/workout_log_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../logic/auth_bloc/auth_state.dart';
import '../../../logic/workout_bloc/my_workout_bloc.dart';
import '../../../logic/workout_bloc/my_workout_event.dart';
import '../../../logic/workout_bloc/workout_bloc.dart';
import '../../../logic/workout_bloc/workout_event.dart';
import '../../../logic/workout_bloc/workout_session_bloc.dart';
import '../../../logic/workout_bloc/workout_session_state.dart';
import '../../../services/achievement_service.dart';
import '../../../services/user_service.dart';
import '../../widgets/workouts/workout_session_mini_player.dart';
import '../workouts/workout_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool showReminderBanner;

  const HomeScreen({
    super.key,
    this.showReminderBanner = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey _navBarKey = GlobalKey();
  double _navBarHeight = kBottomNavigationBarHeight;

  // ✅ Обновлённый список экранов
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      DashboardScreen(),      // 0
      WorkoutScreen(),        // 1
      NutritionScreen(),      // 2
      ProgressScreen(),       // 3
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showReminderBanner) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы не завершили тренировку до конца 🧐'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _navBarKey.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && mounted) {
          setState(() {
            _navBarHeight = box.size.height;
          });
        }
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => WorkoutBloc(
          workoutRepository: locator.get<WorkoutRepository>(),
          userService: locator.get<UserService>(),
          uid: authState.user.uid,
        )..add(LoadWorkouts())),
        BlocProvider(
          create: (_) => AchievementCubit(
            service: locator.get<AchievementService>(),
            workoutLogRepo: locator.get<WorkoutLogRepository>(),
            photoRepo: locator.get<PhotoProgressRepository>(),
            userId: authState.user.uid,
          )..loadAchievements(),
        ),
        BlocProvider(create: (_) => MyWorkoutBloc(locator.get<MyWorkoutRepository>())..add(LoadMyWorkouts(authState.user.uid))),
        BlocProvider(create: (_) => WorkoutSessionBloc()),
        BlocProvider(create: (_) => DailyWorkoutRefreshCubit()),
      ],

      child: Scaffold(
        resizeToAvoidBottomInset: true,

        body: Stack(
          children: [
            SafeArea(child: _screens[_selectedIndex]),

            BlocBuilder<WorkoutSessionBloc, WorkoutSessionState>(
              builder: (context, state) {
                final session = state.session;
                final index = state.currentExerciseIndex;

                if (session == null || session.status != WorkoutStatus.inProgress) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: _navBarHeight + MediaQuery.of(context).padding.bottom + 10,
                  child: WorkoutSessionMiniPlayer(
                    session: session,
                    currentExercise: index,
                    isResting: state.isResting,
                    restSecondsLeft: state.restSecondsLeft ?? 0,
                    navBarHeight: _navBarHeight,
                  ),
                );
              },
            ),
          ],
        ),

        bottomNavigationBar: SafeArea(
          child: Container(
            key: _navBarKey,
            decoration: BoxDecoration(
              color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 10, spreadRadius: 2)],
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, "Главная", 0),
                _buildNavItem(Icons.fitness_center, "Тренировки", 1),
                GestureDetector(
                  onTap: () {
                    // TODO: Открытие быстрого добавления
                  },
                  child: Container(
                    height: 50,
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
                _buildNavItem(Icons.fastfood, "Питание", 2),
                _buildNavItem(Icons.bar_chart, "Прогресс", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: _selectedIndex == index ? Colors.blueGrey.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              if (_selectedIndex == index)
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.05),
                  blurRadius: 6,
                  spreadRadius: -2,
                  offset: const Offset(0, 2),
                )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: _selectedIndex == index ? Colors.blue : Colors.grey,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: _selectedIndex == index ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}