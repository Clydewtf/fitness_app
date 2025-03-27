import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../../logic/auth_bloc/auth_event.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../services/notification_service.dart';
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
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = false;
  String _notificationTime = "12:00";
  String _selectedGoal = 'Поддержание формы';
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().getCurrentUser();

    return Scaffold(
      appBar: AppBar(title: const Text("Профиль")),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
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
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                      child: _profileImagePath == null
                          ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const Center(child: Text("Нажмите, чтобы изменить фото")),

                const SizedBox(height: 20),

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

                // Настройки уведомлений
                const Text("Настройки уведомлений", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Включение/выключение уведомлений
                SwitchListTile(
                  title: const Text("Напоминания о тренировках"),
                  value: _notificationsEnabled,
                  onChanged: _updateNotifications,
                ),

                // Выбор времени уведомления
                ListTile(
                  title: const Text("Время напоминания"),
                  subtitle: Text(_notificationTime),
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectNotificationTime,
                ),

                const SizedBox(height: 20),

                // TODO: Убрать это, тестовое уведомление
                ElevatedButton(
                  onPressed: () async {
                    print("Отправка уведомления...");
                    await NotificationService().showInstantNotification("Тест", "Это тестовое уведомление!");
                    print("Уведомление отправлено!");
                  },
                  child: const Text("Тест уведомления"),
                ),

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

                const SizedBox(height: 20),
              ],
            )
          )
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

  Future<void> _loadNotificationSettings() async {
    bool isEnabled = await _notificationService.getNotificationsEnabled();
    String? savedTime = await _notificationService.getNotificationTime();
    setState(() {
      _notificationsEnabled = isEnabled;
      _notificationTime = savedTime ?? "12:00";
    });
  }

  Future<void> _updateNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _notificationService.setNotificationsEnabled(value);
  }

  Future<void> _selectNotificationTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_notificationTime.split(":")[0]),
        minute: int.parse(_notificationTime.split(":")[1]),
      ),
    );

    if (pickedTime != null) {
      String formattedTime = "${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')}";
      setState(() {
        _notificationTime = formattedTime;
      });
      await _notificationService.setNotificationTime(formattedTime);
    }
  }
}