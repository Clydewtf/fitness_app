import 'workout_log_model.dart';
import 'workout_model.dart';

enum WorkoutStatus { initial, inProgress, completed }

class WorkoutSession {
  final String workoutId;
  final String workoutName;
  final String goal;
  final List<WorkoutExerciseProgress> exercises;
  final DateTime startTime;
  DateTime? endTime;
  WorkoutStatus status;

  WorkoutSession({
    required this.workoutId,
    required this.workoutName,
    required this.goal,
    required this.exercises,
    required this.startTime,
    this.endTime,
    this.status = WorkoutStatus.inProgress,
  });

  bool get isCompleted => exercises.every((e) => e.status == ExerciseStatus.done);
}

enum ExerciseStatus { pending, inProgress, done, skipped }

class WorkoutExerciseProgress {
  final String exerciseId;
  final WorkoutMode workoutMode;
  ExerciseStatus status;
  Duration? timeSpent;

  /// Новое поле для ручного ввода данных по подходам
  List<ExerciseSetLog>? sets;

  WorkoutExerciseProgress({
    required this.exerciseId,
    required this.workoutMode,
    this.status = ExerciseStatus.pending,
    this.timeSpent,
    this.sets,
  });
}

extension WorkoutSessionCopyWith on WorkoutSession {
  WorkoutSession copyWith({
    String? workoutId,
    String? workoutName,
    String? goal,
    List<WorkoutExerciseProgress>? exercises,
    DateTime? startTime,
    DateTime? endTime,
    WorkoutStatus? status,
  }) {
    return WorkoutSession(
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
      goal: goal ?? this.goal,
      exercises: exercises ?? this.exercises,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }
}

extension WorkoutExerciseProgressCopyWith on WorkoutExerciseProgress {
  WorkoutExerciseProgress copyWith({
    String? exerciseId,
    WorkoutMode? workoutMode,
    ExerciseStatus? status,
    Duration? timeSpent,
    List<ExerciseSetLog>? sets,
  }) {
    return WorkoutExerciseProgress(
      exerciseId: exerciseId ?? this.exerciseId,
      workoutMode: workoutMode ?? this.workoutMode,
      status: status ?? this.status,
      timeSpent: timeSpent ?? this.timeSpent,
      sets: sets ?? this.sets,
    );
  }
}