import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/logic/notification_bloc/notification_event.dart';
import 'package:fitness_app/logic/workout_bloc/exercise_event.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/locator.dart';
import 'core/theme/theme_cubit.dart';
import 'data/repositories/workout_repository.dart';
import 'logic/auth_bloc/auth_bloc.dart';
import 'logic/auth_bloc/auth_event.dart';
import 'logic/auth_bloc/auth_state.dart';
import 'logic/workout_bloc/workout_bloc.dart';
import 'logic/workout_bloc/exercise_bloc.dart';
import 'logic/nutrition_bloc/nutrition_bloc.dart';
import 'logic/notification_bloc/notification_bloc.dart';
import 'logic/workout_bloc/workout_event.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'services/notification_service.dart';
import 'services/subscription_notification_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones();

  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.reloadScheduledNotifications();

  final subscriptionNotificationService = SubscriptionNotificationService();
  await subscriptionNotificationService.initialize();
  await subscriptionNotificationService.reloadScheduledSubscriptionNotifications();

  setupLocator(); // Инициализируем DI перед запуском приложения
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => locator<AuthBloc>()..add(CheckLoginStatus())),
        BlocProvider<NotificationBloc>(create: (context) => NotificationBloc(notificationService: locator<NotificationService>())..add(LoadNotificationsEvent()),),
        BlocProvider(create: (context) => ThemeCubit()..loadTheme()),
        BlocProvider(create: (context) => locator<ExerciseBloc>()..add(LoadExercises()),),
        // BlocProvider<WorkoutBloc>(create: (context) => WorkoutBloc(workoutRepository: locator.get())..add(LoadWorkouts()),),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          bool isDarkMode = state is ThemeUpdated && state.isDarkMode;
          return MaterialApp(
            title: 'Фитнес-приложение',
            theme: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

// Виджет-обертка, который проверяет статус входа
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}