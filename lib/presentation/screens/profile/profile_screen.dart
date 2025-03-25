import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../logic/auth_bloc/auth_event.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final UserService _userService = UserService();
  String _selectedGoal = 'Поддержание формы';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = AuthService().getCurrentUser();
    if (user == null) return;

    Map<String, dynamic>? userData = await _userService.getUserData(user.uid);
    if (userData != null) {
      setState(() {
        _ageController.text = (userData['age'] ?? '').toString();
        _weightController.text = (userData['weight'] ?? '').toString();
        _heightController.text = (userData['height'] ?? '').toString();
        _selectedGoal = userData['goal'] ?? 'Поддержание формы';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().getCurrentUser();

    return Scaffold(
      appBar: AppBar(title: const Text("Профиль")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Фото профиля
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 10),

            // Email (не редактируемый)
            Text(
              user?.email ?? "Неизвестный пользователь",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Поля для возраста, веса, роста
            _buildTextField("Возраст", _ageController),
            _buildTextField("Вес (кг)", _weightController),
            _buildTextField("Рост (см)", _heightController),

            // Выбор цели
            DropdownButtonFormField<String>(
              value: _selectedGoal,
              decoration: const InputDecoration(labelText: "Цель"),
              items: ["Набор массы", "Сушка", "Поддержание формы"]
                  .map((goal) => DropdownMenuItem(value: goal, child: Text(goal)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGoal = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Кнопка сохранения
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text("Сохранить изменения"),
            ),

            const SizedBox(height: 20),

            // Выход из аккаунта
            TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(LogoutUser());
                // Navigator.pop(context);
                Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
              },
              child: const Text("Выйти", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
  final user = AuthService().getCurrentUser();
  if (user == null) return;

  Map<String, dynamic> updatedData = {
    'age': int.tryParse(_ageController.text) ?? 0,
    'weight': double.tryParse(_weightController.text) ?? 0.0,
    'height': double.tryParse(_heightController.text) ?? 0.0,
    'goal': _selectedGoal,
  };

  await _userService.updateUserData(user.uid, updatedData);

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Данные профиля обновлены!')),
  );
}

  // Виджет для текстовых полей
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}