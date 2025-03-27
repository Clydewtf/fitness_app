import 'package:equatable/equatable.dart';
import 'notification_bloc.dart';

abstract class NotificationState extends Equatable {
  final List<NotificationBlock> blocks;
  const NotificationState({required this.blocks});

  @override
  List<Object> get props => [blocks];
}

class NotificationInitial extends NotificationState {
  NotificationInitial() : super(blocks: []);
}

class NotificationsLoaded extends NotificationState {
  const NotificationsLoaded(List<NotificationBlock> blocks) : super(blocks: blocks);
}

class NotificationScheduled extends NotificationState {
  const NotificationScheduled(List<NotificationBlock> blocks) : super(blocks: blocks);
}

class NotificationCancelled extends NotificationState {
  const NotificationCancelled(List<NotificationBlock> blocks) : super(blocks: blocks);
}