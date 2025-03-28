import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_event.dart';
import 'notification_state.dart';
import 'package:fitness_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService notificationService;

  NotificationBloc({required this.notificationService}) : super(NotificationInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<AddNotificationBlockEvent>(_onAddNotificationBlock);
    on<RemoveNotificationBlockEvent>(_onRemoveNotificationBlock);
    on<EditNotificationBlockEvent>(_onEditNotificationBlock);
    on<ScheduleNotification>(_onScheduleNotification);
    on<CancelNotification>(_onCancelNotification);
  }

  void _onLoadNotifications(LoadNotificationsEvent event, Emitter<NotificationState> emit) async {
    List<NotificationBlock> notifications = await notificationService.loadNotifications();
    emit(NotificationsLoaded(notifications));
  }

  void _onAddNotificationBlock(AddNotificationBlockEvent event, Emitter<NotificationState> emit) async {
    if (state is NotificationsLoaded) {
      final updatedBlocks = List<NotificationBlock>.from((state as NotificationsLoaded).blocks)
        ..add(event.block);
      emit(NotificationsLoaded(updatedBlocks));
      await notificationService.saveNotifications(updatedBlocks);
    }
  }

  void _onRemoveNotificationBlock(RemoveNotificationBlockEvent event, Emitter<NotificationState> emit) async {
    if (state is NotificationsLoaded) {
      final updatedBlocks = (state as NotificationsLoaded).blocks.where((b) => b.id != event.id).toList();
      emit(NotificationsLoaded(updatedBlocks));
      await notificationService.saveNotifications(updatedBlocks);
    }
  }

  void _onEditNotificationBlock(EditNotificationBlockEvent event, Emitter<NotificationState> emit) async {
    if (state is NotificationsLoaded) {
      final updatedBlocks = (state as NotificationsLoaded).blocks.map((b) {
        return b.id == event.block.id ? event.block : b;
      }).toList();
      emit(NotificationsLoaded(updatedBlocks));
      await notificationService.saveNotifications(updatedBlocks);
    }
  }

  Future<void> _onScheduleNotification(ScheduleNotification event, Emitter<NotificationState> emit) async {
    await notificationService.scheduleNotification(
      id: event.id,
      title: event.title,
      body: event.body,
      scheduledTime: event.scheduledDate,
    );
  }

  Future<void> _onCancelNotification(CancelNotification event, Emitter<NotificationState> emit) async {
    await notificationService.cancelNotification(event.id);
  }
}

class NotificationBlock {
  final String id;
  final List<String> days;
  final List<String> times;
  final String goal;

  NotificationBlock({required this.id, required this.days, required this.times, required this.goal});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'days': days,
      'times': times,
      'goal': goal,
    };
  }

  factory NotificationBlock.fromJson(Map<String, dynamic> json) {
    return NotificationBlock(
      id: json['id'],
      days: List<String>.from(json['days']),
      times: List<String>.from(json['times']),
      goal: json['goal'],
    );
  }
}