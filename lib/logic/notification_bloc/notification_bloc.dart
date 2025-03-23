import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationBloc() : super(NotificationInitial()) {
    tz.initializeTimeZones();
    on<RequestNotificationPermission>(_onRequestPermission);
    on<ScheduleWorkoutNotification>(_onScheduleWorkoutNotification);
    on<ScheduleMealNotification>(_onScheduleMealNotification);
    on<CancelAllNotifications>(_onCancelAllNotifications);
  }

  // Запрос разрешения на отправку уведомлений
  Future<void> _onRequestPermission(
      RequestNotificationPermission event, Emitter<NotificationState> emit) async {
    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings();

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await notificationsPlugin.initialize(settings);
  }

  // Запланировать уведомление о тренировке
  Future<void> _onScheduleWorkoutNotification(
      ScheduleWorkoutNotification event, Emitter<NotificationState> emit) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'workout_channel', 'Тренировки',
        importance: Importance.high, priority: Priority.high,
      );

      final iosDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(event.dateTime, tz.local);

      await notificationsPlugin.zonedSchedule(
        1,
        'Тренировка',
        'Не забудь выполнить свою тренировку!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      emit(NotificationScheduled("Уведомление о тренировке запланировано"));
    } catch (e) {
      emit(NotificationError("Ошибка при создании уведомления"));
    }
  }

  // Запланировать уведомление о приеме пищи
  Future<void> _onScheduleMealNotification(
      ScheduleMealNotification event, Emitter<NotificationState> emit) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'meal_channel', 'Прием пищи',
        importance: Importance.high, priority: Priority.high,
      );

      final iosDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(event.dateTime, tz.local);

      await notificationsPlugin.zonedSchedule(
        2,
        'Прием пищи',
        'Время покушать!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      emit(NotificationScheduled("Уведомление о приеме пищи запланировано"));
    } catch (e) {
      emit(NotificationError("Ошибка при создании уведомления"));
    }
  }

  // Отмена всех уведомлений
  Future<void> _onCancelAllNotifications(
      CancelAllNotifications event, Emitter<NotificationState> emit) async {
    await notificationsPlugin.cancelAll();
    emit(NotificationInitial());
  }
}