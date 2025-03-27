import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const String _notificationKey = 'training_notifications';
  static const String _notificationTimeKey = 'training_notification_time';
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

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

  Future<void> init() async {
    // Инициализация плагина
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings);

    // Инициализация timezones
    tz.initializeTimeZones();
  }

  // Показать мгновенное уведомление
  Future<void> showInstantNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'training_channel',
      'Напоминания о тренировках',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(0, title, body, details);
  }

  // Запланировать уведомление
  Future<void> scheduleNotification(String title, String body, DateTime scheduledTime) async {
    await _notificationsPlugin.zonedSchedule(
      1,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('training_channel', 'Напоминания о тренировках'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}