import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/data/repositories/body_log_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/achievement_model.dart';
import '../data/models/body_log.dart';
import '../data/models/photo_progress_entry.dart';
import '../data/models/workout_log_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/photo_progress_repository.dart';
import '../data/repositories/workout_log_repository.dart';

class AchievementService {
  static const _prefsKey = 'user_achievements';

  Future<List<Achievement>> checkAndUpdateAchievements({
    required List<WorkoutLog> workoutLogs,
    required List<PhotoProgressEntry> photoEntries,
    required List<BodyLog> bodyLogs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedAchievements = await _loadSavedAchievements(prefs);

    final Map<String, Achievement> savedMap = {
      for (final a in savedAchievements) a.id: a
    };

    final List<Achievement> achievements = [];

    Achievement buildAchievement({
      required String id,
      required String title,
      required String description,
      required String icon,
      required int current,
      required int goal,
      required bool isUnlocked,
    }) {
      final status = isUnlocked
          ? AchievementStatus.unlocked
          : current > 0
              ? AchievementStatus.inProgress
              : AchievementStatus.locked;

      final saved = savedMap[id];
      final wasUnlocked = saved?.status == AchievementStatus.unlocked;

      final unlockedAt = isUnlocked
          ? (wasUnlocked ? saved?.unlockedAt : DateTime.now())
          : null;

      return Achievement(
        id: id,
        title: title,
        description: description,
        icon: icon,
        current: current,
        goal: goal,
        status: status,
        unlockedAt: unlockedAt,
      );
    }

    // 1. 10 тренировок
    final totalWorkouts = workoutLogs.length;
    achievements.add(buildAchievement(
      id: 'workout_10',
      title: '10 тренировок',
      description: 'Пройди 10 тренировок',
      icon: '🏋️',
      current: totalWorkouts,
      goal: 10,
      isUnlocked: totalWorkouts >= 10,
    ));

    // 2. Первое фото
    final hasPhoto = photoEntries.isNotEmpty;
    achievements.add(buildAchievement(
      id: 'photo_1',
      title: 'Первый фото-прогресс',
      description: 'Добавь первое фото',
      icon: '📸',
      current: hasPhoto ? 1 : 0,
      goal: 1,
      isUnlocked: hasPhoto,
    ));

    // 3. Вес в подходе 100+ кг
    final maxWeight = workoutLogs
        .expand((log) => log.exercises)
        .expand((ex) => ex.sets)
        .map((set) => set.weight ?? 0)
        .fold<double>(0, (prev, curr) => curr > prev ? curr : prev);

    achievements.add(buildAchievement(
      id: 'weight_100kg',
      title: '100 кг в одном подходе',
      description: 'Подними 100 кг за подход',
      icon: '💪',
      current: maxWeight.clamp(0, 100).toInt(),
      goal: 100,
      isUnlocked: maxWeight >= 100,
    ));

    // 4. Изменение веса тела на 5 кг
    double weightChange = 0;
    if (bodyLogs.length >= 2) {
      final sorted = [...bodyLogs]..sort((a, b) => a.date.compareTo(b.date));
      weightChange = (sorted.last.weight - sorted.first.weight).abs();
    }

    achievements.add(buildAchievement(
      id: 'weight_change_5kg',
      title: 'Изменение веса на 5 кг',
      description: 'Измени вес тела на 5 кг',
      icon: '⚖️',
      current: weightChange.clamp(0, 5).toInt(),
      goal: 5,
      isUnlocked: weightChange >= 5,
    ));

    // 5. 7 тренировок подряд
    final uniqueDates = workoutLogs
        .map((log) => DateTime(log.date.year, log.date.month, log.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime? currentDay = DateTime.now();
    while (uniqueDates.contains(currentDay)) {
      streak++;
      currentDay = currentDay?.subtract(const Duration(days: 1));
    }

    achievements.add(buildAchievement(
      id: 'streak_7',
      title: '7 дней подряд',
      description: 'Заверши 7 тренировок подряд',
      icon: '🔥',
      current: streak,
      goal: 7,
      isUnlocked: streak >= 7,
    ));

    // Сохраняем достижения в SharedPreferences
    await _saveAchievements(prefs, achievements);

    return achievements;
  }

  Future<void> _saveAchievements(SharedPreferences prefs, List<Achievement> achievements) async {
    final List<String> encoded = achievements.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_prefsKey, encoded);
  }

  Future<List<Achievement>> _loadSavedAchievements(SharedPreferences prefs) async {
    final List<String>? saved = prefs.getStringList(_prefsKey);
    if (saved == null) return [];
    return saved.map((s) => Achievement.fromJson(jsonDecode(s))).toList();
  }
}

class AchievementCubit extends Cubit<List<Achievement>> {
  final AchievementService service;
  final WorkoutLogRepository workoutLogRepo;
  final PhotoProgressRepository photoRepo;
  final String userId;

  AchievementCubit({
    required this.service,
    required this.workoutLogRepo,
    required this.photoRepo,
    required this.userId,
  }) : super([]);

  Future<void> loadAchievements() async {
    final workoutLogs = await workoutLogRepo.getWorkoutLogs(userId);
    final photoLogs = await photoRepo.loadEntries();
    final bodyLogs = await BodyLogRepository(
      firestore: FirebaseFirestore.instance,
      userId: userId,
    ).loadLogs();

    final achievements = await service.checkAndUpdateAchievements(
      workoutLogs: workoutLogs,
      photoEntries: photoLogs,
      bodyLogs: bodyLogs,
    );

    emit(achievements);
  }
}