import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/achievement_model.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.status == AchievementStatus.unlocked;
    final progressColor = isUnlocked ? Colors.green : Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка-достижения (эмодзи)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.green.withAlpha(30) : Colors.blue.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                achievement.icon,
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 16),

            // Основной контент
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Icon(
                        isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                        color: isUnlocked ? Colors.amber[700] : Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: achievement.progress,
                      minHeight: 8,
                      color: progressColor,
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${achievement.current}/${achievement.goal}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (isUnlocked && achievement.unlockedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Разблокировано: ${DateFormat('dd MMMM yyyy', 'ru_RU').format(achievement.unlockedAt!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}