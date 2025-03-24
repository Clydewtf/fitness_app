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
      body: Stack(
        children: [
          _screens[_selectedIndex], // Показываем активный экран

          // Нижняя панель с навигацией
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
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
                  const SizedBox(width: 70), // Оставляем место под "плюс"
                  _buildNavItem(Icons.bar_chart, "Прогресс", 2),
                  _buildNavItem(Icons.person, "Профиль", 3),
                ],
              ),
            ),
          ),

          // Кнопка "Плюс" по центру
          Positioned(
            bottom: 10, // Чуть выше, чтобы не перекрывать навигацию
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: FloatingActionButton(
              onPressed: () {
                // TODO: Открыть экран быстрого добавления
              },
              shape: const CircleBorder(),
              backgroundColor: Colors.blue,
              elevation: 8,
              child: const Icon(Icons.add, size: 35, color: Colors.white),
            ),
          ),
        ],
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