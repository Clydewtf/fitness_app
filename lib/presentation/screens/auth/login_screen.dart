import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../home/home_screen.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../logic/auth_bloc/auth_event.dart';
import '../../../logic/auth_bloc/auth_state.dart';
import '../../../data/models/user_model.dart'; //TODO: Убрать это, пока тестовое создание юзера

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Вход")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Пароль"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthFailure) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(state.message)));
                } else if (state is Authenticated) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                }
              },
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: () {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();
                    context.read<AuthBloc>().add(LoginUser(email, password));
                  },
                  child: const Text("Войти"),
                );
              },
            ),
            TextButton(
              onPressed: () {
                // TODO: Реализовать переход на экран регистрации
              },
              child: const Text("Еще нет аккаунта? Зарегистрироваться"),
            ),
            //TODO: Убрать, тестовое создание юзера
            TextButton(
              onPressed: () {
                final testUser = UserModel(
                  id: "1",
                  name: "Test User",
                  email: "test@example.com",
                  password: "12345678",
                  age: 25,
                  weight: 70.0,
                  height: 175.0,
                  goal: "mass",
                );
                
                context.read<AuthBloc>().add(SaveUser(testUser));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Тестовый пользователь создан!")),
                );
              },
              child: const Text("Создать тестового пользователя"),
            ),
          ],
        ),
      ),
    );
  }
}