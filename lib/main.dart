import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/locator.dart';
import 'logic/auth_bloc/auth_bloc.dart';
import 'logic/auth_bloc/auth_event.dart';
import 'logic/auth_bloc/auth_state.dart';
import 'logic/workout_bloc/workout_bloc.dart';
import 'logic/nutrition_bloc/nutrition_bloc.dart';
import 'logic/notification_bloc/notification_bloc.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
      ],
      child: MaterialApp(
        title: 'Фитнес-приложение',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthWrapper(), // Определяем, какой экран загрузить
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