import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Запрос разрешения на отправку уведомлений
class RequestNotificationPermission extends NotificationEvent {}

// Запланировать напоминание о тренировке
class ScheduleWorkoutNotification extends NotificationEvent {
  final DateTime dateTime;

  ScheduleWorkoutNotification(this.dateTime);

  @override
  List<Object?> get props => [dateTime];
}

// Запланировать напоминание о приеме пищи
class ScheduleMealNotification extends NotificationEvent {
  final DateTime dateTime;

  ScheduleMealNotification(this.dateTime);

  @override
  List<Object?> get props => [dateTime];
}

// Удалить все запланированные уведомления
class CancelAllNotifications extends NotificationEvent {}