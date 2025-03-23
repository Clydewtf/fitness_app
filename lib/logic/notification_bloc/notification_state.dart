import 'package:equatable/equatable.dart';

abstract class NotificationState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Начальное состояние (уведомления не настроены)
class NotificationInitial extends NotificationState {}

// Уведомления успешно запланированы
class NotificationScheduled extends NotificationState {
  final String message;

  NotificationScheduled(this.message);

  @override
  List<Object?> get props => [message];
}

// Ошибка при настройке уведомлений
class NotificationError extends NotificationState {
  final String error;

  NotificationError(this.error);

  @override
  List<Object?> get props => [error];
}