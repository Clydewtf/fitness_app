import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../data/models/achievement_model.dart';
import '../../../data/repositories/body_log_repository.dart';
import '../../../data/repositories/photo_progress_repository.dart';
import '../../../data/repositories/workout_log_repository.dart';
import '../../../services/achievement_service.dart';
import '../../../services/auth_service.dart';
import '../../widgets/progress/achievement_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late Future<List<Achievement>> _futureAchievements;

  @override
  void initState() {
    super.initState();
    _futureAchievements = _loadAchievements();
  }

  Future<List<Achievement>> _loadAchievements() async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) return [];

    final workoutLogs = await WorkoutLogRepository().getWorkoutLogs(uid);
    final photoLogs = await PhotoProgressRepository().loadEntries();
    final bodyLogs = await BodyLogRepository(
      firestore: FirebaseFirestore.instance,
      userId: uid,
    ).loadLogs();

    final achievements = await AchievementService().checkAndUpdateAchievements(
      workoutLogs: workoutLogs,
      photoEntries: photoLogs,
      bodyLogs: bodyLogs,
    );

    achievements.sort((a, b) {
      int statusOrder(AchievementStatus status) {
        switch (status) {
          case AchievementStatus.unlocked:
            return 0;
          case AchievementStatus.inProgress:
            return 1;
          case AchievementStatus.locked:
            return 2;
        }
      }

      return statusOrder(a.status).compareTo(statusOrder(b.status));
    });

    return achievements;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Достижения')),
      body: FutureBuilder<List<Achievement>>(
        future: _futureAchievements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final achievements = snapshot.data ?? [];

          if (achievements.isEmpty) {
            return const Center(child: Text('Достижений пока нет'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              return AchievementCard(achievement: a);
            },
          );
        },
      ),
    );
  }
}