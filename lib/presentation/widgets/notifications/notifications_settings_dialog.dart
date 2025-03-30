import 'package:flutter/material.dart';

class NotificationSettingsDialog extends StatefulWidget {
  final List<int> selectedDays;
  final TimeOfDay selectedTime;
  final Function(List<int>, TimeOfDay) onSave;

  const NotificationSettingsDialog({super.key, 
    required this.selectedDays,
    required this.selectedTime,
    required this.onSave,
  });

  @override
  _NotificationSettingsDialogState createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends State<NotificationSettingsDialog> {
  late List<int> selectedDays;
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    selectedDays = List.from(widget.selectedDays); // Загружаем сохраненные данные
    selectedTime = widget.selectedTime;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Настройки уведомлений"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("За сколько дней до оплаты напоминать?"),
          Wrap(
            spacing: 8,
            children: [1, 3, 5, 7].map((day) {
              return ChoiceChip(
                label: Text("$day дн."),
                selected: selectedDays.contains(day),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedDays.add(day);
                    } else {
                      selectedDays.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          Text("Выберите время"),
          TextButton(
            onPressed: () async {
              TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: selectedTime,
              );
              if (picked != null) {
                setState(() {
                  selectedTime = picked;
                });
              }
            },
            child: Text("Время: ${selectedTime.format(context)}"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Отмена"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(selectedDays, selectedTime);
            Navigator.pop(context);
          },
          child: Text("Сохранить"),
        ),
      ],
    );
  }
}