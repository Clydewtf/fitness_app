import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionNotificationService {
  static final SubscriptionNotificationService _instance = SubscriptionNotificationService._internal();

  factory SubscriptionNotificationService() {
    return _instance;
  }

  SubscriptionNotificationService._internal();
  static SubscriptionNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Запрашиваем разрешение на точные уведомления
    await requestExactAlarmPermission();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);
  }

  Future<void> requestExactAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.request().isGranted) {
      print("Разрешение на точные уведомления получено.");
    } else {
      print("Разрешение на точные уведомления НЕ получено!");
    }
  }

  Future<void> scheduleSubscriptionNotifications({
    required DateTime endDate,
    required List<int> daysBefore,
    required TimeOfDay time,
  }) async {
    print('📅 Начинаем планирование уведомлений...');
    print('  Дата окончания подписки: $endDate');
    print('  Дни перед окончанием: $daysBefore');
    print('  Время уведомления: ${time.hour}:${time.minute}');

    DateTime now = DateTime.now();

    for (int days in daysBefore) {
      DateTime notificationDate = endDate.subtract(Duration(days: days));
      DateTime finalDateTime = DateTime(
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
        time.hour,
        time.minute,
      );

      if (finalDateTime.isBefore(now)) {
        print('⚠️ Пропускаем прошедшую дату: $finalDateTime');
        continue; // Пропускаем уведомления, которые попали в прошлое
      }

      print('⏳ Запланированное уведомление: $finalDateTime');

      final tz.TZDateTime tzFinalDateTime =
          tz.TZDateTime.from(finalDateTime, tz.local);

      await _notificationsPlugin.zonedSchedule(
        finalDateTime.millisecondsSinceEpoch ~/ 1000,
        'Оплата подписки',
        'Не забудьте оплатить подписку!',
        tzFinalDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'subscription_reminder',
            'Напоминание о подписке',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        //matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Уведомление успешно запланировано на $tzFinalDateTime');
    }
  }

  Future<void> reloadScheduledSubscriptionNotifications() async {
    await cancelSubscriptionNotifications();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;

    if (!notificationsEnabled) {
      print("🔕 Уведомления отключены, пропускаем перепланирование.");
      return;
    }

    print("🔄 Перезагрузка уведомлений...");

    String? lastPaymentString = prefs.getString('last_payment_date');
    String? subscriptionType = prefs.getString('subscription_type');
    List<String>? daysString = prefs.getStringList('notification_days');
    String? timeString = prefs.getString('notification_time');

    if (lastPaymentString == null || daysString == null || timeString == null || subscriptionType == null) {
      print("⚠️ Данные о подписке не найдены, уведомления не будут запланированы.");
      return;
    }

    DateTime lastPaymentDate = DateTime.parse(lastPaymentString);
    List<int> daysBefore = daysString.map(int.parse).toList();
    List<String> timeParts = timeString.split(':');
    TimeOfDay notificationTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    // Определяем длительность подписки
    int subscriptionDuration = (subscriptionType == 'Год') ? 365 : 30;

    // Дата окончания подписки
    DateTime endDate = lastPaymentDate.add(Duration(days: subscriptionDuration));

    DateTime now = DateTime.now();
    while (endDate.isBefore(now)) {
      // Если подписка истекла, двигаем её на следующий период
      endDate = endDate.add(Duration(days: subscriptionDuration));
    }

    print("⏳ Проверяем корректность даты окончания подписки...");
    print("   📆 Исходная дата: ${lastPaymentDate.add(Duration(days: subscriptionDuration))}");
    print("   📆 Пересчитанная дата окончания: $endDate");
    print("   🕒 Текущее время: $now");

    print("📅 Перепланирование уведомлений...");
    print("   📌 Дата окончания подписки: $endDate");
    print("   ⏳ Дни до окончания: $daysBefore");
    print("   ⏰ Время уведомления: ${notificationTime.hour}:${notificationTime.minute}");

    await scheduleSubscriptionNotifications(
      endDate: endDate,
      daysBefore: daysBefore,
      time: notificationTime,
    );

    print("✅ Уведомления успешно перепланированы!");
  }

  Future<void> cancelSubscriptionNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}