import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/subscription_notification_service.dart';
import '../../widgets/subscription/add_subscription_screen.dart';
import '../../widgets/notifications/notifications_settings_dialog.dart';

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
  bool _notificationsEnabled = false; // Переключатель
  List<int> _notificationDays = []; // Список дней для уведомлений
  TimeOfDay _notificationTime = TimeOfDay(hour: 9, minute: 0); // Время по умолчанию

  final _subscriptionNotificationService = SubscriptionNotificationService();

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
    _loadNotificationPreferences();
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
    if (lastPaymentDate == null) return;

    int daysSinceLastPayment = DateTime.now().difference(lastPaymentDate!).inDays;

    // Если прошло меньше 25 дней, показать подтверждение
    if (daysSinceLastPayment < 25) {
      _showConfirmPaymentDialog(daysSinceLastPayment);
      return;
    }

    _processPayment();
    
  }

  void _showConfirmPaymentDialog(int daysSinceLastPayment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Абонемент еще действует"),
        content: Text("Прошло всего $daysSinceLastPayment дней с последней оплаты. Вы уверены, что хотите отметить оплату?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Отмена
            child: Text("Отмена"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Закрыть диалог
              _processPayment(); // Все равно оплатить
            },
            child: Text("Все равно отметить"),
          ),
        ],
      ),
    );
  }

  void _processPayment() async {
    DateTime now = DateTime.now();

    setState(() {
      lastPaymentDate = now;
      daysUntilNextPayment = _calculateDaysUntilNextPayment(now);
    });

    _addToPaymentHistory(now);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_payment_date', now.toIso8601String());

    await _rescheduleSubscriptionNotifications(now);
    // Сохраняем тип подписки (например, monthly или yearly)
    await prefs.setString('subscription_type', subscriptionType ?? 'Месяц');
  }

  int _calculateDaysUntilNextPayment(DateTime lastPayment) {
    int period = (subscriptionType == "Месяц") ? 30 : 365;
    DateTime nextPayment = lastPayment.add(Duration(days: period));

    // 🛠 Если подписка уже истекла, увеличиваем до будущей даты
    while (nextPayment.isBefore(DateTime.now())) {
      nextPayment = nextPayment.add(Duration(days: period));
    }

    int remainingDays = nextPayment.difference(DateTime.now()).inDays;

    // 🛠 Если получилось 0 дней — значит, оплата сегодня
    if (remainingDays == 0) {
      print('📆 Сегодня день оплаты, уведомления не нужны.');
      return 0; 
    }

    return remainingDays;
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
    await prefs.remove('notifications_enabled');

    setState(() {
      subscriptionType = null;
      lastPaymentDate = null;
      daysUntilNextPayment = null;
      paymentHistory = [];
      _notificationsEnabled = false;
    });

    print('⚠️ Подписка удалена, отключаем уведомления...');
    _disableNotifications();
  }

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
            SizedBox(height: 16),
            _buildNotificationBlock(), // Добавляем блок уведомлений
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBlock() {
    return GestureDetector(
      onTap: _showNotificationSettings, // Открываем окно настроек
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Уведомления о платеже", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Switch(
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
                if (value) {
                  _showNotificationSettings(); // Если включается — открываем окно
                } else {
                  _disableNotifications(); // Если выключается — удаляем уведомления
                }
              });
            },
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    List<int> savedDays = prefs.getStringList('notification_days')?.map(int.parse).toList() ?? [];
    String? savedTimeStr = prefs.getString('notification_time');
    TimeOfDay savedTime = savedTimeStr != null
        ? TimeOfDay(
            hour: int.parse(savedTimeStr.split(":")[0]),
            minute: int.parse(savedTimeStr.split(":")[1]),
          )
        : TimeOfDay(hour: 9, minute: 0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return NotificationSettingsDialog(
          selectedDays: savedDays,
          selectedTime: savedTime,
          onSave: (selectedDays, selectedTime) {
            _saveNotificationPreferences(true, selectedDays, selectedTime); // Включаем уведомления
            _scheduleNotifications(selectedDays, selectedTime); // Создаём уведомления
          },
        );
      },
    );
  }

  Future<void> _loadNotificationPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;

      List<String>? daysString = prefs.getStringList('notification_days');
      _notificationDays = daysString?.map((d) => int.parse(d)).toList() ?? [];

      String? timeString = prefs.getString('notification_time');
      if (timeString != null) {
        List<String> parts = timeString.split(':');
        _notificationTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } else {
        _notificationTime = TimeOfDay(hour: 9, minute: 0); // Значение по умолчанию
      }
    });

    print('Загружены настройки уведомлений:');
    print('  Включены: $_notificationsEnabled');
    print('  Дни: $_notificationDays');
    print('  Время: ${_notificationTime.format(context)}');
  }

  Future<void> _saveNotificationPreferences(bool isEnabled, List<int> days, TimeOfDay time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', isEnabled);
    await prefs.setStringList('notification_days', days.map((d) => d.toString()).toList());
    await prefs.setString('notification_time', '${time.hour}:${time.minute.toString().padLeft(2, '0')}');

    print('Сохранены настройки уведомлений:');
    print('  Включены: $isEnabled');
    print('  Дни: $days');
    print('  Время: ${time.hour}:${time.minute}');
  }
  
  Future<void> _disableNotifications() async {
    await _saveNotificationPreferences(false, [], const TimeOfDay(hour: 9, minute: 0));
    // Здесь можно добавить код для отмены уведомлений
    await _subscriptionNotificationService.cancelSubscriptionNotifications();
    print('❌ Уведомления отключены и удалены!');
  }

  // Future<void> _scheduleNotifications(List<int> daysBefore, TimeOfDay time) async {
  //   print('📅 Планирование уведомлений...');
  //   print('  Дни: $daysBefore');
  //   print('  Время: ${time.hour}:${time.minute}');
  //   // Тут логика планирования уведомлений через `flutter_local_notifications`
  //   if (lastPaymentDate != null && daysUntilNextPayment != null) {
  //     DateTime nextPaymentDate = lastPaymentDate!.add(Duration(days: daysUntilNextPayment!));

  //     // 🛠 Если дата уже прошла, добавляем нужный период (месяц или год)
  //     // while (nextPaymentDate.isBefore(DateTime.now())) {
  //     //   nextPaymentDate = nextPaymentDate.add(Duration(days: daysUntilNextPayment!));
  //     // }
  //     print('  📆 Следующая оплата: $nextPaymentDate');

  //     // Проверяем, есть ли даты в будущем
  //     List<int> validDaysBefore = daysBefore.where((days) {
  //       DateTime notificationDate = nextPaymentDate.subtract(Duration(days: days));
  //       bool isFutureDate = notificationDate.isAfter(DateTime.now());
  //       if (!isFutureDate) {
  //         print('⚠️ Пропущено уведомление, так как дата уже прошла: $notificationDate');
  //         _saveNotificationPreferences(false, [], const TimeOfDay(hour: 9, minute: 0));
  //       }
  //       return isFutureDate;
  //     }).toList();

  //     if (validDaysBefore.isEmpty) {
  //       print('❌ Нет уведомлений для планирования, все даты уже прошли.');
  //       return;
  //     }

  //     await _subscriptionNotificationService.scheduleSubscriptionNotifications(
  //       endDate: nextPaymentDate,
  //       daysBefore: daysBefore,
  //       time: time,
  //     );
  //     print('✅ Уведомления успешно запланированы!');
  //   } else {
  //     print('⚠️ Дата подписки не установлена, уведомления не запланированы.');
  //   }
  // }

  Future<void> _scheduleNotifications(List<int> daysBefore, TimeOfDay time) async {
    print('📅 Планирование уведомлений...');
    print('  Дни: $daysBefore');
    print('  Время: ${time.hour}:${time.minute}');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastPaymentString = prefs.getString('last_payment_date');
    String? subscriptionType = prefs.getString('subscription_type');

    if (lastPaymentString == null || subscriptionType == null) {
      print('⚠️ Ошибка: Дата подписки или тип подписки отсутствуют в SharedPreferences.');
      return;
    }

    DateTime lastPaymentDate = DateTime.parse(lastPaymentString);
    int subscriptionDuration = (subscriptionType == 'Год') ? 365 : 30;
    DateTime nextPaymentDate = lastPaymentDate.add(Duration(days: subscriptionDuration));

    // 🛠 Если дата подписки устарела, сдвигаем её на следующий период
    while (nextPaymentDate.isBefore(DateTime.now())) {
      nextPaymentDate = nextPaymentDate.add(Duration(days: subscriptionDuration));
    }

    print('  📆 Следующая оплата: $nextPaymentDate');

    DateTime now = DateTime.now(); // Текущее время

    // Проверяем, есть ли даты в будущем
    List<int> validDaysBefore = daysBefore.where((days) {
      DateTime notificationDate = nextPaymentDate.subtract(Duration(days: days));
      // Добавляем время уведомления
      notificationDate = DateTime(notificationDate.year, notificationDate.month,
        notificationDate.day, time.hour, time.minute);

      bool isFutureDate = notificationDate.isAfter(DateTime.now());
      if (!isFutureDate) {
        print('⚠️ Пропущено уведомление, так как дата уже прошла: $notificationDate');
      }
      return isFutureDate;
    }).toList();

    if (validDaysBefore.isEmpty) {
      print('❌ Нет уведомлений для планирования, все даты уже прошли.');
      return;
    }

    await _subscriptionNotificationService.scheduleSubscriptionNotifications(
      endDate: nextPaymentDate,
      daysBefore: validDaysBefore, // Передаём только даты в будущем
      time: time,
    );

    print('✅ Уведомления успешно запланированы!');
  }

  Future<void> _rescheduleSubscriptionNotifications(DateTime newPaymentDate) async {
    print('🔄 Перепланируем уведомления...');
    
    await SubscriptionNotificationService.instance.cancelSubscriptionNotifications(); // Удаляем старые уведомления

    if (_notificationsEnabled && daysUntilNextPayment != null) {
      DateTime nextPaymentDate = newPaymentDate.add(Duration(days: daysUntilNextPayment!));
      print('  📆 Новая дата окончания подписки: $nextPaymentDate');

      // ✅ Загружаем сохранённые настройки уведомлений
      final prefs = await SharedPreferences.getInstance();
      _notificationDays = prefs.getStringList('notification_days')?.map(int.parse).toList() ?? _notificationDays;
      int hour = prefs.getInt('notification_hour') ?? _notificationTime.hour;
      int minute = prefs.getInt('notification_minute') ?? _notificationTime.minute;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);

      if (_notificationDays.isNotEmpty) {
        await SubscriptionNotificationService.instance.scheduleSubscriptionNotifications(
          endDate: nextPaymentDate, // Новый конец подписки
          daysBefore: _notificationDays, 
          time: _notificationTime,
        );
        print('✅ Уведомления перепланированы.');
      } else {
        print('⚠️ Дни перед окончанием пустые, уведомления не запланированы.');
      }
    } else {
      print('⚠️ Уведомления отключены или нет данных о подписке, перепланирование невозможно.');
    }
  }
}