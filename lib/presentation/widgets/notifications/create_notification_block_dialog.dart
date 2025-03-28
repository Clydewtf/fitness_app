import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/notification_bloc/notification_bloc.dart';
import '../../../logic/notification_bloc/notification_event.dart';

class CreateNotificationBlockDialog extends StatefulWidget {
  const CreateNotificationBlockDialog({super.key});

  @override
  _CreateNotificationBlockDialogState createState() => _CreateNotificationBlockDialogState();
}

class _CreateNotificationBlockDialogState extends State<CreateNotificationBlockDialog> {
  String? _selectedGoal;
  List<String> _selectedDays = [];
  List<String> _selectedTimes = [];

  final List<String> _goals = ['Тренировка', 'Питание', 'Оплата'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Добавить уведомление"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Выбор цели (goal)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Цель"),
            value: _selectedGoal,
            items: _goals.map((goal) {
              return DropdownMenuItem(value: goal, child: Text(goal));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedGoal = value;
              });
            },
          ),
          const SizedBox(height: 10),

          // Выбор дней (ChoiceChip)
          Wrap(
            spacing: 5,
            children: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"].map((day) {
              return ChoiceChip(
                label: Text(day),
                selected: _selectedDays.contains(day),
                onSelected: (selected) {
                  setState(() {
                    selected ? _selectedDays.add(day) : _selectedDays.remove(day);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Выбор времени
          ElevatedButton(
            onPressed: _selectTime,
            child: const Text("Выбрать время"),
          ),
          const SizedBox(height: 10),

          // Отображение выбранного времени
          Wrap(
            spacing: 5,
            children: _selectedTimes.map((time) {
              return Chip(
                label: Text(time),
                onDeleted: () {
                  setState(() {
                    _selectedTimes.remove(time);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Отмена"),
        ),
        ElevatedButton(
          onPressed: _saveNotificationBlock,
          child: const Text("Создать"),
        ),
      ],
    );
  }

  void _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (pickedTime != null) {
      setState(() {
        _selectedTimes.add("${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')}");
      });
    }
  }

  void _saveNotificationBlock() {
    if (_selectedGoal == null || _selectedDays.isEmpty || _selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Заполните все поля!")));
      return;
    }

    final newBlock = NotificationBlock(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      goal: _selectedGoal!,
      days: _selectedDays,
      times: _selectedTimes,
    );

    context.read<NotificationBloc>().add(AddNotificationBlockEvent(newBlock));
    Navigator.pop(context);
  }
}