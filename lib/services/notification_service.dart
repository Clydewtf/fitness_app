import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _notificationKey = 'training_notifications';
  static const String _notificationTimeKey = 'training_notification_time';

  // Сохранение состояния уведомлений (включены/выключены)
  Future<void> setNotificationsEnabled(bool isEnabled) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationKey, isEnabled);
  }

  // Получение состояния уведомлений
  Future<bool> getNotificationsEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationKey) ?? false;
  }

  // Сохранение времени напоминания
  Future<void> setNotificationTime(String time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationTimeKey, time);
  }

  // Получение времени напоминания
  Future<String?> getNotificationTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_notificationTimeKey);
  }
}