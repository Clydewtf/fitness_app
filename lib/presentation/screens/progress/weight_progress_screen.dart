import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/body_log.dart';
import '../../../data/repositories/body_log_repository.dart';
import '../../../data/repositories/photo_progress_repository.dart';
import '../../../data/repositories/workout_log_repository.dart';
import '../../../services/achievement_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  late BodyLogRepository bodyLogRepository;
  List<BodyLog> logs = [];
  bool isLoading = true;
  FlSpot? selectedSpot;
  Offset? touchPosition;

  @override
  void initState() {
    super.initState();
    final uid = AuthService().getCurrentUser()?.uid;

    bodyLogRepository = BodyLogRepository(
      firestore: FirebaseFirestore.instance,
      userId: uid!,
    );
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final fetchedLogs = await bodyLogRepository.loadLogs();
    setState(() {
      logs = fetchedLogs;
      isLoading = false;
    });
  }

  Future<void> _addWeightLog() async {
    final result = await showDialog<BodyLog>(
      context: context,
      builder: (context) => WeightAddDialog(),
    );

    if (result != null) {
      await bodyLogRepository.addLog(result);

      final autoUpdate = await UserSettingsStorage().getAutoUpdateWeight();
      if (autoUpdate) {
        await UserService().updateUserData(
          bodyLogRepository.userId,
          {'weight': result.weight},
        );
      }

      _loadLogs();

      // ⬇️ Обновляем ачивки
      final uid = AuthService().getCurrentUser()?.uid;
      if (uid == null) return;

      final workoutLogs = await WorkoutLogRepository().getWorkoutLogs(uid);
      final photoLogs = await PhotoProgressRepository().loadEntries();
      final bodyLogs = await BodyLogRepository(
        firestore: FirebaseFirestore.instance,
        userId: uid,
      ).loadLogs();

      await AchievementService().checkAndUpdateAchievements(
        workoutLogs: workoutLogs,
        photoEntries: photoLogs,
        bodyLogs: bodyLogs,
      );
    }
  }

  final chartKey = ValueKey('weight_chart');

  Widget _buildChart() {
    if (logs.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    logs.sort((a, b) => a.date.compareTo(b.date));

    final spots = logs.map((log) {
      return FlSpot(log.date.millisecondsSinceEpoch.toDouble(), log.weight);
    }).toList();

    final minX = spots.map((e) => e.x).reduce((a, b) => a < b ? a : b);
    final maxX = spots.map((e) => e.x).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 1;
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1;

    const oneDayMs = 24 * 60 * 60 * 1000;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              lineTouchData: LineTouchData(
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent && response?.lineBarSpots?.isNotEmpty == true) {
                    final spot = response!.lineBarSpots!.first;
                    setState(() {
                      selectedSpot = spot;
                      touchPosition = event.localPosition;
                    });
                  } else if (event is FlTapUpEvent) {
                    setState(() {
                      selectedSpot = null;
                    });
                  }
                },
                handleBuiltInTouches: false,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(show: true),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: ((maxX - minX) / 4).clamp(oneDayMs, oneDayMs * 10).toDouble(),
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      final label = DateFormat.Md().format(date);
                      return SideTitleWidget(
                        space: 6,
                        meta: meta,
                        child: Transform.rotate(
                          angle: -0.5,
                          child: Text(label, style: const TextStyle(fontSize: 10)),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 2,
                    getTitlesWidget: (value, _) {
                      return Text('${value.toStringAsFixed(0)} кг', style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
          if (selectedSpot != null && touchPosition != null)
            Positioned(
              left: (touchPosition!.dx + 8).clamp(0, MediaQuery.of(context).size.width - 150),
              top: (touchPosition!.dy - 60).clamp(0, MediaQuery.of(context).size.height - 60),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.blueAccent,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${selectedSpot!.y.toStringAsFixed(1)} кг', style: const TextStyle(color: Colors.white)),
                      Text(
                        DateFormat.yMMMd().format(
                          DateTime.fromMillisecondsSinceEpoch(selectedSpot!.x.toInt()),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    final latestLogs = logs.reversed.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('История измерений', style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _AllLogsModal(
                    logs: logs.reversed.toList(),
                    onDelete: (log) async {
                      await bodyLogRepository.deleteLog(log);
                      _loadLogs();
                    },
                  ),
                );
              },
              child: const Text('Все'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: latestLogs.length,
          itemBuilder: (context, index) {
            final log = latestLogs[index];
            return ListTile(
              title: Text('${log.weight.toStringAsFixed(1)} кг'),
              subtitle: Text(DateFormat.yMMMd().format(log.date)),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await bodyLogRepository.deleteLog(log);
                  _loadLogs();
                },
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вес и тело')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 250, child: _buildChart()),
                  const SizedBox(height: 16),
                  //const Text('История измерений', style: TextStyle(fontWeight: FontWeight.bold)),
                  //const SizedBox(height: 8),
                  _buildLogList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWeightLog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class WeightAddDialog extends StatefulWidget {
  const WeightAddDialog({super.key});

  @override
  State<WeightAddDialog> createState() => _WeightAddDialogState();
}

class _WeightAddDialogState extends State<WeightAddDialog> {
  final TextEditingController _weightController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  double _currentWeight = 70.0;

  @override
  void initState() {
    super.initState();
    _loadLastWeight();
  }

  Future<void> _loadLastWeight() async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid != null) {
      final weight = await UserService().getUserWeight(uid);
      if (weight != null) {
        _currentWeight = weight;
        _weightController.text = weight.toStringAsFixed(1);
      } else {
        _weightController.text = _currentWeight.toStringAsFixed(1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новое измерение'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    _currentWeight = (_currentWeight - 0.1).clamp(0.0, 999.9);
                    _weightController.text = _currentWeight.toStringAsFixed(1);
                  });
                },
              ),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    final val = double.tryParse(value);
                    if (val != null) {
                      _currentWeight = val;
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Вес (кг)'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _currentWeight = (_currentWeight + 0.1).clamp(0.0, 999.9);
                    _weightController.text = _currentWeight.toStringAsFixed(1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Дата:'),
              const SizedBox(width: 8),
              Text(DateFormat.yMMMd().format(selectedDate)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final weight = double.tryParse(_weightController.text);
            if (weight != null) {
              Navigator.pop(
                context,
                BodyLog(
                  weight: weight,
                  date: DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    TimeOfDay.now().hour,
                    TimeOfDay.now().minute,
                  ),
                ),
              );
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _AllLogsModal extends StatefulWidget {
  final List<BodyLog> logs;
  final Future<void> Function(BodyLog) onDelete;

  const _AllLogsModal({required this.logs, required this.onDelete});

  @override
  State<_AllLogsModal> createState() => _AllLogsModalState();
}

class _AllLogsModalState extends State<_AllLogsModal> {
  late List<BodyLog> currentLogs;

  @override
  void initState() {
    super.initState();
    currentLogs = widget.logs;
  }

  Future<void> _handleDelete(BodyLog log) async {
    await widget.onDelete(log);
    setState(() {
      currentLogs.removeWhere((l) =>
          l.date == log.date && l.weight == log.weight);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          controller: controller,
          itemCount: currentLogs.length,
          itemBuilder: (context, index) {
            final log = currentLogs[index];
            return ListTile(
              title: Text('${log.weight.toStringAsFixed(1)} кг'),
              subtitle: Text(DateFormat.yMMMd().format(log.date)),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _handleDelete(log),
              ),
            );
          },
        ),
      ),
    );
  }
}