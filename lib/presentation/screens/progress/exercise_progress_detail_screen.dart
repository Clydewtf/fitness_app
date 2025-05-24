import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/workout_session_model.dart';
import '../../../logic/progress_bloc/progress_cubit.dart';
import '../../../data/models/workout_log_model.dart';

class ExerciseProgressDetailScreen extends StatefulWidget {
  final String exerciseId;

  const ExerciseProgressDetailScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseProgressDetailScreen> createState() => _ExerciseProgressDetailScreenState();
}

class _ExerciseProgressDetailScreenState extends State<ExerciseProgressDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedRange = '30д';

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  DateTime? _getFromDate() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case '7д':
        return now.subtract(const Duration(days: 7));
      case '30д':
        return now.subtract(const Duration(days: 30));
      case 'всё':
      default:
        return null;
    }
  }

  List<FlSpot> _generateSpots(List<WorkoutLog> logs, String type) {
    final fromDate = _getFromDate();
    final List<FlSpot> spots = [];

    final filteredLogs = logs
        .where((log) =>
            (fromDate == null || log.date.isAfter(fromDate)) &&
            log.exercises.any((e) => e.id == widget.exerciseId && e.status == ExerciseStatus.done))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final log in filteredLogs) {
      final date = log.date.millisecondsSinceEpoch.toDouble();
      final exercises = log.exercises.where((e) => e.id == widget.exerciseId);

      double value = 0;
      int count = 0;

      for (final e in exercises) {
        for (final set in e.sets) {
          final reps = set.reps;
          final weight = set.weight ?? 0;

          switch (type) {
            case 'weight':
              value += weight;
              count++;
              break;
            case 'reps':
              value += reps;
              count++;
              break;
            case 'volume':
              value += weight * reps;
              break;
          }
        }
      }

      if ((type == 'weight' || type == 'reps') && count > 0) {
        value = value / count;
      }

      spots.add(FlSpot(date, value));
    }

    return spots;
  }

  Widget _buildChart(List<WorkoutLog> logs, String type) {
    final spots = _generateSpots(logs, type);

    if (spots.isEmpty) {
      return const Center(child: Text('Недостаточно данных для графика.'));
    }

    final minX = spots.first.x;
    final maxX = spots.last.x;
    final values = spots.map((e) => e.y).toList();
    final minY = values.reduce(min);
    final maxY = values.reduce(max);
    final interval = (maxX - minX) / 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY * 0.9,
          maxY: maxY * 1.1,
          lineTouchData: LineTouchData(enabled: false),
          clipData: FlClipData.all(), // обрезает по краям
          gridData: FlGridData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withValues(alpha: 0.2),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval > 0 ? interval : 1,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${date.day}.${date.month}', style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40, // добавим отступ, чтобы не налезали
                interval: ((maxY - minY) / 4).clamp(1, 100),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Прогресс упражнения')),
        body: BlocBuilder<WorkoutLogCubit, WorkoutLogState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final logs = state.logs
                .where((log) => log.exercises.any((e) =>
                    e.id == widget.exerciseId && e.status == ExerciseStatus.done))
                .toList();

            if (logs.isEmpty) {
              return const Center(child: Text('Нет данных по этому упражнению.'));
            }

            return Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.hintColor,
                        indicatorColor: theme.colorScheme.primary,
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: const [
                          Tab(text: '📉 Вес'),
                          Tab(text: '🔁 Повторы'),
                          Tab(text: '🧮 Объём'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          DropdownButton<String>(
                            value: _selectedRange,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedRange = value;
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: '7д', child: Text('7д')),
                              DropdownMenuItem(value: '30д', child: Text('30д')),
                              DropdownMenuItem(value: 'всё', child: Text('всё')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildChart(logs, 'weight'),
                      _buildChart(logs, 'reps'),
                      _buildChart(logs, 'volume'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}