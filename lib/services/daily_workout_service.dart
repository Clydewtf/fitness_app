import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/workout_model.dart';

class DailyWorkoutService {
  static const _key = 'dailyWorkoutIndex';

  Future<int?> _loadIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key);
  }

  Future<void> _saveIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, index);
  }

  /// Возвращает текущую тренировку. Если не выбрана — выбирает первую.
  Future<(Workout, bool)?> getCurrentWorkout(List<(Workout, bool)> allFavorites) async {
    if (allFavorites.isEmpty) return null;

    final index = await _loadIndex() ?? 0;
    final safeIndex = index % allFavorites.length;
    final selected = allFavorites[safeIndex];

    return selected;
  }

  /// Переходит к следующей тренировке по кругу.
  Future<void> goToNextWorkout(List<(Workout, bool)> allFavorites) async {
    if (allFavorites.isEmpty) return;

    final currentIndex = await _loadIndex() ?? 0;
    final nextIndex = (currentIndex + 1) % allFavorites.length;
    await _saveIndex(nextIndex);
  }

  /// Сбрасывает индекс до нуля (если понадобится).
  Future<void> reset() async {
    await _saveIndex(0);
  }
}

class DailyWorkoutRefreshCubit extends Cubit<int> {
  DailyWorkoutRefreshCubit() : super(0);

  void refresh() => emit(state + 1);
}