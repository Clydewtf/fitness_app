import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/locator.dart';
import 'logic/auth_bloc/auth_bloc.dart';
import 'logic/workout_bloc/workout_bloc.dart';
import 'logic/nutrition_bloc/nutrition_bloc.dart';
import 'logic/notification_bloc/notification_bloc.dart';

void main() {
  setupLocator(); // Инициализируем DI перед запуском приложения
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => locator<AuthBloc>()),
        BlocProvider(create: (context) => locator<WorkoutBloc>()),
        BlocProvider(create: (context) => locator<NutritionBloc>()),
        BlocProvider(create: (context) => locator<NotificationBloc>()),
      ],
      child: MaterialApp(
        title: 'Фитнес-приложение',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const Placeholder(), // TODO: заменить на реальный главный экран
      ),
    );
  }
}
