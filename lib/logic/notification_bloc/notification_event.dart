import 'package:equatable/equatable.dart';
import 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadNotificationsEvent extends NotificationEvent {}

class AddNotificationBlockEvent extends NotificationEvent {
  final NotificationBlock block;
  AddNotificationBlockEvent(this.block);

  @override
  List<Object> get props => [block];
}

class RemoveNotificationBlockEvent extends NotificationEvent {
  final String id;
  RemoveNotificationBlockEvent(this.id);

  @override
  List<Object> get props => [id];
}

class EditNotificationBlockEvent extends NotificationEvent {
  final NotificationBlock block;
  EditNotificationBlockEvent(this.block);

  @override
  List<Object> get props => [block];
}

class ScheduleNotification extends NotificationEvent {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;

  ScheduleNotification({required this.id, required this.title, required this.body, required this.scheduledDate});

  @override
  List<Object> get props => [id, title, body, scheduledDate];
}

class CancelNotification extends NotificationEvent {
  final int id;
  CancelNotification(this.id);

  @override
  List<Object> get props => [id];
}