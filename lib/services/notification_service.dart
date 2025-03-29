import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../logic/notification_bloc/notification_bloc.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String _notificationsKey = "notifications";
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Запрашиваем разрешение на точные уведомления
    await requestExactAlarmPermission(); 

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  Future<void> requestExactAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.request().isGranted) {
      print("Разрешение на точные уведомления получено.");
    } else {
      print("Разрешение на точные уведомления НЕ получено!");
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    int notificationId = id % 2147483647; // Уменьшаем id до 32-битного диапазона

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          channelDescription: 'Description',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> saveNotifications(List<NotificationBlock> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> jsonList = notifications.map((block) => jsonEncode(block.toJson())).toList();
    await prefs.setStringList(_notificationsKey, jsonList);
  }

  Future<List<NotificationBlock>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList(_notificationsKey);

    if (jsonList == null) return [];
    return jsonList.map((json) => NotificationBlock.fromJson(jsonDecode(json))).toList();
  }

  Future<void> reloadScheduledNotifications() async {
    await cancelAllNotifications(); // Очищаем перед загрузкой

    List<NotificationBlock> notifications = await loadNotifications();

    for (var block in notifications) {
      for (var day in block.days) {
        for (var time in block.times) {
          try {
            // Парсим часы и минуты из строки
            List<String> timeParts = time.split(":");
            int hour = int.parse(timeParts[0]);
            int minute = int.parse(timeParts[1]);

            // Определяем ближайшую дату для этого дня недели
            DateTime scheduledDate = getNextDateForDay(day, hour, minute);
            int notificationId = "${block.id}${hour}${minute}".hashCode;

            if (scheduledDate.isAfter(DateTime.now())) {
              await scheduleNotification(
                id: notificationId,
                title: "Напоминание",
                body: block.goal,
                scheduledTime: scheduledDate,
              );
              print("Запланировано: ${block.goal} на $scheduledDate (ID: $notificationId)");
            }
          } catch (e) {
            print("Ошибка при обработке уведомления: $e");
          }
        }
      }
    }
  }

  DateTime getNextDateForDay(String day, int hour, int minute) {
    final now = DateTime.now();
    int targetWeekday = _getWeekdayFromString(day);

    // Начнем с сегодняшней даты
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    print("Сегодня: $now (${now.weekday}), Ищем: $day ($targetWeekday)");

    // Если сегодня нужный день и время еще не прошло - оставляем на сегодня
    if (now.weekday == targetWeekday && scheduledDate.isAfter(now)) {
      print("Запланировано на СЕГОДНЯ: $scheduledDate");
      return scheduledDate;
    }

    // Иначе ищем ближайший день вперед
    do {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    } while (scheduledDate.weekday != targetWeekday);

    print("Запланировано на: $scheduledDate");
    return scheduledDate;
  }

  // Функция для конвертации строкового названия дня в int (понедельник - 1, воскресенье - 7)
  int _getWeekdayFromString(String day) {
    const Map<String, int> days = {
      "Пн": DateTime.monday,
      "Вт": DateTime.tuesday,
      "Ср": DateTime.wednesday,
      "Чт": DateTime.thursday,
      "Пт": DateTime.friday,
      "Сб": DateTime.saturday,
      "Вс": DateTime.sunday,
    };
    int result = days[day] ?? DateTime.monday; // Если ошибка, ставим понедельник
    print("Преобразование дня: $day -> $result");
    return result;
  }

  Future<void> cancelNotification(int id) async {
    int notificationId = id % 2147483647; // Приводим id к допустимому диапазону
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

// class NotificationService {
//   static const String _notificationKey = 'training_notifications';
//   static const String _notificationTimeKey = 'training_notification_time';
//   final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

//   // Сохранение состояния уведомлений (включены/выключены)
//   Future<void> setNotificationsEnabled(bool isEnabled) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_notificationKey, isEnabled);
//   }

//   // Получение состояния уведомлений
//   Future<bool> getNotificationsEnabled() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_notificationKey) ?? false;
//   }

//   // Сохранение времени напоминания
//   Future<void> setNotificationTime(String time) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_notificationTimeKey, time);
//   }

//   // Получение времени напоминания
//   Future<String?> getNotificationTime() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_notificationTimeKey);
//   }

//   Future<void> init() async {
//     // Инициализация плагина
//     const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const InitializationSettings settings = InitializationSettings(android: androidSettings);
//     await _notificationsPlugin.initialize(settings);

//     // Инициализация timezones
//     tz.initializeTimeZones();
//   }

//   // Показать мгновенное уведомление
//   Future<void> showInstantNotification(String title, String body) async {
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'training_channel',
//       'Напоминания о тренировках',
//       importance: Importance.high,
//       priority: Priority.high,
//     );

//     const NotificationDetails details = NotificationDetails(android: androidDetails);

//     await _notificationsPlugin.show(0, title, body, details);
//   }

//   // Запланировать уведомление
//   Future<void> scheduleNotification(String title, String body, DateTime scheduledTime) async {
//     await _notificationsPlugin.zonedSchedule(
//       1,
//       title,
//       body,
//       tz.TZDateTime.from(scheduledTime, tz.local),
//       const NotificationDetails(
//         android: AndroidNotificationDetails('training_channel', 'Напоминания о тренировках'),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );
//   }
// }