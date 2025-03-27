import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/notification_bloc/notification_bloc.dart';
import '../../../logic/notification_bloc/notification_event.dart';
import '../../widgets/notifications/multi_select_days_dialog.dart';

class CreateNotificationBlockDialog extends StatefulWidget {
  const CreateNotificationBlockDialog({super.key});

  @override
  _CreateNotificationBlockDialogState createState() => _CreateNotificationBlockDialogState();
}

class _CreateNotificationBlockDialogState extends State<CreateNotificationBlockDialog> {
  final TextEditingController _goalController = TextEditingController();
  List<String> _selectedDays = [];
  List<String> _selectedTimes = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Добавить уведомление"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _goalController,
            decoration: const InputDecoration(labelText: "Цель"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _selectDays,
            child: const Text("Выбрать дни"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _selectTime,
            child: const Text("Выбрать время"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        TextButton(
          onPressed: () {
            final newBlock = NotificationBlock(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              goal: _goalController.text,
              days: _selectedDays,
              times: _selectedTimes,
            );
            context.read<NotificationBloc>().add(AddNotificationBlockEvent(newBlock));
            Navigator.pop(context);
          },
          child: const Text("Создать"),
        ),
      ],
    );
  }

  void _selectDays() async {
    List<String> allDays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"];
    List<String> selectedDays = await showDialog(
      context: context,
      builder: (context) => MultiSelectDialog(allDays),
    );

    if (selectedDays.isNotEmpty) {
      setState(() {
        _selectedDays = selectedDays;
      });
    }
  }

  void _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (pickedTime != null) {
      setState(() {
        _selectedTimes.add("${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')}");
      });
    }
  }
}