import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/subscription/add_subscription_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? subscriptionType; // Тип абонемента (месяц, год)
  DateTime? lastPaymentDate; // Дата последней оплаты
  int? daysUntilNextPayment; // Осталось дней до оплаты
  List<DateTime> paymentHistory = []; // История оплат

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? type = prefs.getString('subscription_type');
    final String? dateStr = prefs.getString('last_payment_date');
    final List<String>? history = prefs.getStringList('paymentHistory');

    if (type != null && dateStr != null) {
      DateTime lastPayment = DateTime.parse(dateStr);
      DateTime nextPayment = _calculateNextPaymentDate(lastPayment, type);
      int daysLeft = nextPayment.difference(DateTime.now()).inDays;

      setState(() {
        subscriptionType = type;
        lastPaymentDate = lastPayment;
        daysUntilNextPayment = daysLeft >= 0 ? daysLeft : 0; // Защита от отрицательных значений
        paymentHistory = history?.map((e) => DateTime.parse(e)).toList() ?? [];
      });
    }
  }

  // Функция для расчета даты следующей оплаты
  DateTime _calculateNextPaymentDate(DateTime lastPayment, String type) {
    if (type == "Месяц") {
      return DateTime(lastPayment.year, lastPayment.month + 1, lastPayment.day);
    } else if (type == "Год") {
      return DateTime(lastPayment.year + 1, lastPayment.month, lastPayment.day);
    }
    return lastPayment;
  }

  void _markAsPaid() async {
    DateTime now = DateTime.now();

    setState(() {
      lastPaymentDate = now;
      daysUntilNextPayment = _calculateDaysUntilNextPayment(now);
    });

    // Добавляем в историю оплат
    _addToPaymentHistory(now);

    // Сохраняем обновления в SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastPaymentDate', now.toIso8601String());
  }

  int _calculateDaysUntilNextPayment(DateTime lastPayment) {
    if (subscriptionType == "Месяц") {
      return lastPayment.add(Duration(days: 30)).difference(DateTime.now()).inDays;
    } else if (subscriptionType == "Год") {
      return lastPayment.add(Duration(days: 365)).difference(DateTime.now()).inDays;
    }
    return 0; // Если тип не определен
  }

  void _addToPaymentHistory(DateTime paymentDate) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('paymentHistory') ?? [];

    history.add(paymentDate.toIso8601String());

    await prefs.setStringList('paymentHistory', history);

    setState(() {
      paymentHistory.add(paymentDate);
    });
  }

  void _editSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSubscriptionScreen(
          initialType: subscriptionType!,
          initialDate: lastPaymentDate!,
          onSave: (newType, newDate) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('subscription_type', newType);
            await prefs.setString('last_payment_date', newDate.toIso8601String());

            setState(() {
              subscriptionType = newType;
              lastPaymentDate = newDate;
              daysUntilNextPayment = _calculateDaysUntilNextPayment(newDate);
            });
          },
        ),
      ),
    );
  }

  void _deleteSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('subscription_type');
    await prefs.remove('last_payment_date');
    await prefs.remove('paymentHistory');

    setState(() {
      subscriptionType = null;
      lastPaymentDate = null;
      daysUntilNextPayment = null;
    });
  }
  // TODO: Сделать так, чтобы если абонемент оплачен недавно, при нажатии на кнопку оплачено появлялсоь что-то типа
  // "ваш абонемент еще действует", и в историю не добавлялось (подумать над логикой)
  // ну и уведомления доделать на абонемент отдельно (тоже над логикой подумать)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Абонемент")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            subscriptionType == null
                ? _buildAddSubscriptionButton()
                : _buildSubscriptionBlock(),
            SizedBox(height: 20),
            _buildPaymentHistory(), // Вывод истории оплат
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistory() {
    if (paymentHistory.isEmpty) {
      return Text("История оплат пока пуста", style: TextStyle(fontSize: 16));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("История оплат:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          itemCount: paymentHistory.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(Icons.payment),
              title: Text(DateFormat('dd.MM.yyyy').format(paymentHistory[index])),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddSubscriptionButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // Открываем экран добавления абонемента
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddSubscriptionScreen()),
          ).then((_) => _loadSubscriptionData()); // Обновляем после возврата
        },
        child: Text("Добавить абонемент"),
      ),
    );
  }

  Widget _buildSubscriptionBlock() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Тип: $subscriptionType", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Дата последней оплаты: ${DateFormat('dd.MM.yyyy').format(lastPaymentDate!)}"),
            SizedBox(height: 8),
            Text("До следующей оплаты: $daysUntilNextPayment дней", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _markAsPaid();
              },
              child: Text("Оплачено"),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _editSubscription,
                  child: Text("Редактировать"),
                ),
                ElevatedButton(
                  onPressed: _deleteSubscription,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("Удалить"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}