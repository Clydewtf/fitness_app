import 'package:flutter/material.dart';
import '../workouts/workout_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/login_screen.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../logic/auth_bloc/auth_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Список экранов
  final List<Widget> _screens = [
    WorkoutScreen(),
    NutritionScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutUser());
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: _screens[_selectedIndex], // Отображаем активный экран
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Реализовать экран быстрого добавления данных
        },
        shape: const CircleBorder(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Центрируем кнопку
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Форма для FAB
        notchMargin: 6.0, // Отступ между FAB и баром
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // Чтобы текст не исчезал
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: "Тренировки",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fastfood),
              label: "Питание",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: "Прогресс",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Профиль",
            ),
          ],
        ),
      ),
    );
  }
}