import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/notification_bloc/notification_bloc.dart';
import '../../../logic/notification_bloc/notification_state.dart';
import '../../../logic/notification_bloc/notification_event.dart';
import '../../widgets/notifications/create_notification_block_dialog.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});


  // TODO: ошибка, запустить приложение, там напишется
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Настройки уведомлений")),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationsLoaded) {
            return ListView(
              children: [
                ...state.blocks.map((block) => ListTile(
                      title: Text(block.goal),
                      subtitle: Text("${block.days.join(", ")} в ${block.times.join(", ")}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          context.read<NotificationBloc>().add(RemoveNotificationBlockEvent(block.id));
                        },
                      ),
                    )),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _showCreateBlockDialog(context);
                  },
                  child: const Text("Добавить уведомление"),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _showCreateBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateNotificationBlockDialog(),
    );
  }
}