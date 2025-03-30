import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final String? initialType;
  final DateTime? initialDate;
  final Function(String, DateTime)? onSave;

  const AddSubscriptionScreen({super.key, this.initialType, this.initialDate, this.onSave});

  @override
  _AddSubscriptionScreenState createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  late String _selectedType;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? "Месяц";
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  Future<void> saveSubscription() async {
    if (widget.onSave != null) {
      widget.onSave!(_selectedType, _selectedDate);
      Navigator.pop(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_type', _selectedType);
    await prefs.setString('last_payment_date', _selectedDate.toIso8601String());

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Добавить абонемент")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Тип абонемента:", style: TextStyle(fontSize: 16)),
            DropdownButton<String>(
              value: _selectedType,
              items: ["Месяц", "Год"].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            SizedBox(height: 16),
            Text("Дата оплаты:", style: TextStyle(fontSize: 16)),
            TextButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: saveSubscription,
              child: Text("Сохранить"),
            ),
          ],
        ),
      ),
    );
  }
}