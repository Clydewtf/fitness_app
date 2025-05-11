import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../logic/auth_bloc/auth_event.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import 'subscriprion_screen.dart';
import '../auth/login_screen.dart';
import 'settings_screen.dart';
import '../notifications/notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final UserService _userService = UserService();
  String _selectedGoal = 'Поддержание формы';
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().getCurrentUser();
    final initials = user?.email != null
        ? user!.email![0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Профиль")),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Фото профиля
                          Center(
                            child: GestureDetector(
                              onTap: _pickAndSaveImage,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade400,
                                backgroundImage: _profileImagePath != null
                                    ? FileImage(File(_profileImagePath!))
                                    : null,
                                child: _profileImagePath == null
                                    ? Text(
                                        initials,
                                        style: const TextStyle(
                                          fontSize: 30,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Center(child: Text("Нажмите, чтобы изменить фото")),
                          const SizedBox(height: 20),

                          const Text("Личные данные",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(height: 20),

                          Text(
                            user?.email ?? "Неизвестный пользователь",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),

                          _buildTextField("Возраст", _ageController),
                          _buildTextField("Вес (кг)", _weightController),
                          _buildTextField("Рост (см)", _heightController),

                          const SizedBox(height: 20),
                          const Text("Цель",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(height: 20),

                          DropdownButtonFormField<String>(
                            value: _selectedGoal,
                            decoration: const InputDecoration(labelText: "Цель"),
                            items: [
                              "Набор массы",
                              "Сушка",
                              "Поддержание формы",
                              "Сила",
                              "Выносливость"
                            ].map((goal) => DropdownMenuItem(value: goal, child: Text(goal))).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGoal = value!;
                              });
                            },
                          ),

                          const SizedBox(height: 30),
                          const Text("Дополнительно",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(height: 20),

                          ListTile(
                            leading: const Icon(Icons.credit_card),
                            title: const Text("Абонемент"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SubscriptionScreen()),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.notifications),
                            title: const Text("Уведомления"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.settings),
                            title: const Text('Настройки'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SettingsScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          Center(
                            child: TextButton(
                              onPressed: () {
                                context.read<AuthBloc>().add(LogoutUser());
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                );
                              },
                              child: const Text("Выйти", style: TextStyle(color: Colors.red)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Добавляем безопасный отступ с учётом нижнего меню
                          SizedBox(height: MediaQuery.of(context).padding.bottom),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _saveProfile,
            child: const Text("Сохранить изменения"),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final user = AuthService().getCurrentUser();
    if (user == null) return;

    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    if (age == null || age <= 0) {
      _showError("Введите корректный возраст");
      return;
    }
    if (weight == null || weight <= 0) {
      _showError("Введите корректный вес");
      return;
    }
    if (height == null || height <= 0) {
      _showError("Введите корректный рост");
      return;
    }

    Map<String, dynamic> updatedData = {
      'age': age,
      'weight': weight,
      'height': height,
      'goal': _selectedGoal,
    };

    await _userService.updateUserData(user.uid, updatedData);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Данные профиля обновлены!')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _loadUserData() async {
    final user = AuthService().getCurrentUser();
    String? imagePath = await _userService.getProfileImage();
    if (user == null) return;

    Map<String, dynamic>? userData = await _userService.getUserData(user.uid);
    if (userData != null) {
      setState(() {
        _ageController.text = (userData['age'] ?? '').toString();
        _weightController.text = (userData['weight'] ?? '').toString();
        _heightController.text = (userData['height'] ?? '').toString();
        _selectedGoal = userData['goal'] ?? 'Поддержание формы';
        _profileImagePath = imagePath;
      });
    }
  }

  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    String? savedPath = await _userService.saveProfileImage(imageFile);
    if (savedPath != null) {
      setState(() {
        _profileImagePath = savedPath;
      });
    }
  }
}