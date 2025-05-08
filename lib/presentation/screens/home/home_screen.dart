import 'package:flutter/material.dart';
import '../../../core/locator.dart';
import '../../../data/models/workout_session_model.dart';
import '../../../data/repositories/my_workout_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../logic/auth_bloc/auth_state.dart';
import '../../../logic/workout_bloc/my_workout_bloc.dart';
import '../../../logic/workout_bloc/my_workout_event.dart';
import '../../../logic/workout_bloc/workout_bloc.dart';
import '../../../logic/workout_bloc/workout_event.dart';
import '../../../logic/workout_bloc/workout_session_bloc.dart';
import '../../../logic/workout_bloc/workout_session_state.dart';
import '../../../services/user_service.dart';
import '../../widgets/workouts/workout_session_mini_player.dart';
import '../workouts/workout_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/login_screen.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../logic/auth_bloc/auth_event.dart';

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
  double _navBarHeight = 80;

  // Список экранов
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      WorkoutScreen(),
      NutritionScreen(),
      ProgressScreen(),
      ProfileScreen(),
    ];

    // 👇 Показываем SnackBar, если нужно напомнить
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showReminderBanner) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Вы не завершили тренировку до конца 🧐'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
    // TODO: доделать логику с дозаполнением настроения и прочего после тренировки для сохранения
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = _navBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        setState(() {
          _navBarHeight = renderBox.size.height;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => WorkoutBloc(
            workoutRepository: locator.get<WorkoutRepository>(),
            userService: locator.get<UserService>(),
            uid: authState.user.uid,
          )..add(LoadWorkouts()),
        ),
        BlocProvider(
          create: (_) => MyWorkoutBloc(
            locator.get<MyWorkoutRepository>(),
          )..add(LoadMyWorkouts(authState.user.uid)),
        ),
        BlocProvider(
          create: (_) => WorkoutSessionBloc(),
        ),
      ],
// TODO: сделать, чтобы мини-плеер сохранялся при закрытии приложения (или вообще сделать чтобы полностью всё состояние сохранялось)
      child: Scaffold(
        appBar: AppBar(),
        body: Stack(
          children: [
            _screens[_selectedIndex],

            // Нижняя панель
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                key: _navBarKey,
                decoration: BoxDecoration(
                  color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(38),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.fitness_center, "Тренировки", 0),
                    _buildNavItem(Icons.fastfood, "Питание", 1),
                    const SizedBox(width: 70),
                    _buildNavItem(Icons.bar_chart, "Прогресс", 2),
                    _buildNavItem(Icons.person, "Профиль", 3),
                  ],
                ),
              ),
            ),

            // Кнопка "плюс"
            Positioned(
              bottom: 15,
              left: MediaQuery.of(context).size.width / 2 - 30,
              child: FloatingActionButton(
                onPressed: () {
                  // TODO: открытие быстрого добавления
                },
                shape: const CircleBorder(),
                backgroundColor: Colors.blue,
                elevation: 8,
                child: const Icon(Icons.add, size: 35, color: Colors.white),
              ),
            ),

            // Плеер
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
                  bottom: _navBarHeight + 10,
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
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index), // Делаем кнопку кликабельной
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
                  blurStyle: BlurStyle.normal,
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