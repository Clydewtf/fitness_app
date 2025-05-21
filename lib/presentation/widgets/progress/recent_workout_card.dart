import 'package:flutter/material.dart';

// --- Стат карточка (для количества тренировок, минут и т.д.)
class StatCard extends StatelessWidget {
  final String title;
  final String value;

  const StatCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

// --- Карточка недавней тренировки
class RecentWorkoutCard extends StatelessWidget {
  final String title;
  final String date;
  final String duration;
  final bool isIncomplete;
  final VoidCallback? onTap;

  const RecentWorkoutCard({super.key, 
    required this.title,
    required this.date,
    required this.duration,
    this.isIncomplete = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isIncomplete ? Colors.orange.shade50 : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: isIncomplete
            ? const Icon(Icons.warning_amber, color: Colors.orange)
            : const Icon(Icons.check_circle, color: Colors.green),
        title: Text(title),
        subtitle: Text(date),
        trailing: Text(duration),
      ),
    );
  }
}