import '../data/models/workout_session_model.dart';

int? findNextIncompleteExercise(List<WorkoutExerciseProgress> exercises, int justCompletedIndex) {
  final total = exercises.length;

  // Шагаем вперёд от только что выполненного
  for (int i = justCompletedIndex + 1; i < total; i++) {
    if (!_isDoneOrSkipped(exercises[i])) return i;
  }

  // Если не нашли — ищем сначала
  for (int i = 0; i < justCompletedIndex; i++) {
    if (!_isDoneOrSkipped(exercises[i])) return i;
  }

  // Всё завершено или скипнуто
  return null;
}

bool _isDoneOrSkipped(WorkoutExerciseProgress e) {
  return e.status == ExerciseStatus.done || e.status == ExerciseStatus.skipped;
}